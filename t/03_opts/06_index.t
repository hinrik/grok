use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 4;

my $script = catfile('script', 'grok');
my $index_short = qx/$^X $script -i/;
my $index_long  = qx/$^X $script --index/;

like($index_short, qr/^S02/m, 'Found synopsis in index (-i)');
like($index_long, qr/^S02/m, 'Found synopsis in (--index)');
like($index_short, qr/^say\b/m, 'Found function in index (-i)');
like($index_long, qr/^sleep\b/m, 'Found function in (--index)');
