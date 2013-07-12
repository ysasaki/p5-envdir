use utf8;
use strict;
use warnings;
use Test::More;
use EnvDir -autoload => 't/env';

is $ENV{FOO},  'foo',      'env/FOO ok';
is $ENV{PATH}, '/env/bin', 'evn/PATH ok';
ok exists $ENV{EMPTY}, 'EMPTY key exists';
ok( ( not exists $ENV{'.IGNORE'} ), 'dotfile is ignored' );

done_testing;
