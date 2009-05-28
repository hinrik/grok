use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('script', 'grok');
my $result_short = qx/$script -h/;
my $result_long = qx/$script --help/;

like($result_short, qr/Options:/, "Got help message (short)");
like($result_long, qr/Options:/, "Got help message (long)");

