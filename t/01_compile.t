use strict;
use warnings;
use Test::More tests => 2;
use Test::Script;
use_ok('App::Grok');
script_compiles_ok('script/grok', 'grok compiles');
