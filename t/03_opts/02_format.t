use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 14;

my $script = catfile('script', 'grok');

my $pod6 = catfile('t_source', 'basic.pod');
my $pod6_text_short = qx/$^X $script -F $pod6 -f text/;
my $pod6_text_long = qx/$^X $script -F $pod6 --format text/;
my $pod6_ansi_short = qx/$^X $script -F $pod6 -f ansi/;
my $pod6_ansi_long = qx/$^X $script -F $pod6 --format ansi/;
my $pod6_xhtml_short = qx/$^X $script -F $pod6 -f xhtml/;
my $pod6_xhtml_long  = qx/$^X $script -F $pod6 --format xhtml/;

isnt($pod6_text_short, $pod6_ansi_short, "Pod 6 text and ANSI are different (-f)");
like($pod6_ansi_short, qr/\e\[/, "Pod 6 ANSI has color codes (-f)");
isnt($pod6_text_long, $pod6_ansi_long, "Pod 6 text and ANSI are different (--format)");
like($pod6_ansi_long, qr/\e\[/, "Pod 6 ANSI has color codes (--format)");
isnt($pod6_text_long, $pod6_xhtml_long, "Pod 6 text and xhtml are different (--format)");
like($pod6_xhtml_long, qr/<p>/, "Pod 6 xhtml has <p> (--format)");

my $pod5 = catfile('t_source', 'basic5.pod');
my $pod5_text_short  = qx/$^X $script -F $pod5 -f text/;
my $pod5_text_long   = qx/$^X $script -F $pod5 --format text/;
my $pod5_ansi_short  = qx/$^X $script -F $pod5 -f ansi/;
my $pod5_ansi_long   = qx/$^X $script -F $pod5 --format ansi/;
my $pod5_xhtml_short = qx/$^X $script -F $pod5 -f xhtml/;
my $pod5_xhtml_long  = qx/$^X $script -F $pod5 --format xhtml/;
my $pod5_pod_short   = qx/$^X $script -F $pod5 -f pod/;
my $pod5_pod_long    = qx/$^X $script -F $pod5 --format pod/;

isnt($pod5_text_short, $pod5_ansi_short, "Pod 5 text and ANSI are different (-f)");
like($pod5_ansi_short, qr/\e\[/, "Pod 5 ANSI has color codes (-f)");
isnt($pod5_text_long, $pod5_ansi_long, "Pod 5 text and ANSI are different (--format)");
like($pod5_ansi_long, qr/\e\[/, "Pod 5 ANSI has color codes (--format)");
isnt($pod5_text_long, $pod5_xhtml_long, "Pod 5 text and xhtml are different (--format)");
like($pod5_xhtml_long, qr/<p>/, "Pod 5 xhtml has <p> (--format)");
isnt($pod5_text_long, $pod5_pod_long, "Pod 5 text and pod are different (--format)");
like($pod5_pod_long, qr/^=head1/m, "Pod 5 pod has =item (--format)");
