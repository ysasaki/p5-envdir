# NAME

EnvDir - Load environment values from directory

# SYNOPSIS

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

# DESCRIPTION

EnvDir is a module like envdir(8). But this module does not reset all
environments, updates only the value that file exists.

# COPYRIGHT AND LICENSE

Copyright (C) 2013 Yoshihiro Sasaki <ysasaki at cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yoshihiro Sasaki <ysasaki at cpan.org>
