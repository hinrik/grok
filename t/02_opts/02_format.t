use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('script', 'grok');
my $pod = catfile('t_source', 'basic.pod');
my $result_text = qx/$script -F $pod -f text/;
my $result_ansi = qx/$script -F $pod -f ansi/;

isnt($result_text, $result_ansi, "Text and Ansi are differnet");
like($result_ansi, qr/\e\[/, "Ansi has color codes");

