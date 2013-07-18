#!perl

use strict;
use warnings;
use EnvDir 'envdir', -clean;

my ($dir, @cmd) = @ARGV;

unless ( $dir and -d $dir ) {
    usage();
    exit 111;
}

shift @cmd if scalar @cmd and $cmd[0] eq '--';
if ( scalar @cmd == 0 ) {
    usage();
    exit 111;
}

my $guard = envdir($dir);
system @cmd;

# functions
sub usage {
    warn "envdir.pl: usage: envdir dir child\n";
}
