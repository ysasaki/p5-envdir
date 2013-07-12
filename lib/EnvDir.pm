package EnvDir;
use 5.008005;
use strict;
use warnings;
use Carp ();
use File::Spec;

our $VERSION = "0.01";

our $DEFAULT_ENVDIR = File::Spec->catdir( File::Spec->curdir, 'env' );

use constant MARK_DELETE => '__MARK_DELETE__';

sub new {
    my $class = shift;
    bless { depth => 0, cache => [], stack => [] }, $class;
}

my @GLOBAL_GUARD;

sub import {
    my $class = shift;
    if ( scalar @_ > 0 and $_[0] eq '-autoload' ) {
        shift;
        my $self = $class->new;
        push @GLOBAL_GUARD, $self->envdir( shift || $DEFAULT_ENVDIR );
    }
    elsif ( $_[0] and $_[0] eq 'envdir' ) {
        my $package = (caller)[0];
        no strict 'refs';
        *{"$package\::envdir"} = \&envdir;
    }
}

sub envdir {
    my ( $self, $envdir ) = @_;

    unless ( ref $self and ref $self eq 'EnvDir' ) {
        $envdir = $self;
        $self   = EnvDir->new;
    }

    $self->{depth} = scalar @{ $self->{stack} };
    $envdir ||= $DEFAULT_ENVDIR;

    my $depth = $self->{depth};

    # from cache
    my @keys = keys %{ $self->{cache}->[$depth] };
    if ( scalar @keys ) {
        $self->_push_stack( $self->_copy_env(@keys) );
        $ENV{$_} = $self->{cache}->{$_} for @keys;

        return EnvDir::Guard->new( sub { $self->_revert if $self } );
    }

    # from dir
    opendir my $dh, $envdir or Carp::croak "Cannot open $envdir: $!";

    for my $key ( grep !/^\./, readdir($dh) ) {
        my $path = File::Spec->catfile( $envdir, $key );
        next if -d $path;
        my $value = $self->_slurp($path);
        $self->{cache}->[$depth]->{ uc $key } = $value;
    }

    @keys = keys %{ $self->{cache}->[$depth] };
    $self->_push_stack( $self->_copy_env(@keys) );
    $ENV{$_} = $self->{cache}->[$depth]->{$_} for @keys;

    closedir $dh or Carp::carp "Cannot close $envdir: $!";

    return EnvDir::Guard->new( sub { $self->_revert if $self } );
}

sub _push_stack {
    my $self         = shift;
    my %previous_ENV = @_;
    push @{ $self->{stack} }, \%previous_ENV;
}

sub _pop_stack {
    my $self = shift;
    pop @{ $self->{stack} };
}

sub _revert {
    my $self         = shift;
    my $previous_ENV = $self->_pop_stack;
    return unless $previous_ENV and scalar keys %$previous_ENV;

    for my $key (%$previous_ENV) {
        my $value = $previous_ENV->{$key};
        if ( $value and $value eq MARK_DELETE ) {
            delete $ENV{$key};
        }
        else {
            $ENV{$key} = $value;
        }
    }
}

sub _copy_env {
    my $self = shift;
    my @keys = @_;
    my %previous_ENV;

    for my $key (@keys) {
        if ( exists $ENV{$key} ) {
            $previous_ENV{$key} = delete $ENV{$key};
        }
        else {
            $previous_ENV{$key} = MARK_DELETE;
        }
    }
    return %previous_ENV;
}

sub _slurp {
    my $self = shift;
    my $path = shift;
    if ( open my $fh, '<', $path ) {
        my $value = <$fh>;    # read first line only.
        chomp $value if defined $value;
        close $fh or Carp::carp "Cannot close $path: $!";
        return $value;
    }
    else {
        Carp::carp "Cannot open $path: $!";
        return;
    }
}

package EnvDir::Guard;

sub new {
    my ( $class, $handler ) = @_;
    bless $handler, $class;
}

sub DESTROY {
    my $self = shift;
    $self->();
}

1;
__END__

=encoding utf-8

=head1 NAME

EnvDir - Load environment values from directory

=head1 SYNOPSIS

    # load from ./env
    use EnvDir -autoload;

    # specify a directory
    use EnvDir -autoload => '/path/to/dir';

    # lexical change when using a guard object.
    use EnvDir 'envdir';

    $ENV{PATH} = '/bin';
    {
        my $guard = envdir('/path/to/dir');
    }
    # PATH is /bin from here

    # you can nest envdir by OOP syntax.
    use EnvDir;

    my $envdir = EnvDir->new;
    {
        my $guard = $envdir->envdir('/env1');
        ...

        {
            my $guard = $envdir->envdir('/env2');
            ...
        }
    }

=head1 DESCRIPTION

EnvDir is a module like envdir(8). But this module does not reset all
environments, updates only the value that file exists.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Yoshihiro Sasaki E<lt>ysasaki at cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki at cpan.orgE<gt>

=cut

