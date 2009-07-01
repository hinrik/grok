use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('script', 'grok');
my $result_short = qx/$^X $script -V/;
my $result_long = qx/$^X $script --version/;

like($result_short, qr/^grok \d/, "Got version info (-V)");
like($result_long, qr/^grok \d/, "Got version info (--version)");

