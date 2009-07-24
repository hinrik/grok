use strict;
use warnings;
use Test::More tests => 4;
use Test::Script;
use_ok('App::Grok');
use_ok('App::Grok::Parser::Pod5');
use_ok('App::Grok::Parser::Pod6');
script_compiles_ok('script/grok', 'grok compiles');
