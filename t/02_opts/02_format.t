use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 4;

my $script = catfile('script', 'grok');
my $pod = catfile('t_source', 'basic.pod');
my $result_text_short = qx/$script -F $pod -f text/;
my $result_text_long = qx/$script -F $pod --format text/;
my $result_ansi_short = qx/$script -F $pod -f ansi/;
my $result_ansi_long = qx/$script -F $pod --format ansi/;

isnt($result_text_short, $result_ansi_short, "Text and Ansi are different (short)");
like($result_ansi_short, qr/\e\[/, "Ansi has color codes (short)");
isnt($result_text_long, $result_ansi_long, "Text and Ansi are different (long)");
like($result_ansi_long, qr/\e\[/, "Ansi has color codes (long)");

