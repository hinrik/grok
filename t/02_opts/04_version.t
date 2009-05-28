use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('script', 'grok');
my $result_short = qx/$script -v/;
my $result_long = qx/$script --version/;

like($result_short, qr/^grok \d/, "Got version info (short)");
like($result_long, qr/^grok \d/, "Got version info (long)");

