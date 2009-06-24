use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 1;

$ENV{GROK_SHAREDIR} = 'share';

# grok should fall back to reading from a (Pod 6) file if it doesn't
# recognize the target
my $file = catfile('t_source', 'basic.pod');
my $grok = catfile('script', 'grok');

my $result = qx/$grok $file/;
like($result, qr/Baz/, "Got result");
