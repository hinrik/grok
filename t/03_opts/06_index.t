use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('script', 'grok');
my $index_short = qx/$^X $script -i/;
my $index_long  = qx/$^X $script --index/;

like($index_short, qr/^S02/m, 'Got index (-i)');
like($index_long, qr/^S02/m, 'Got index (--index)');

