use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 4;
use App::Grok::Pod5;

my $pod = catfile('t_source', 'basic5.pod');
ok(my $render = App::Grok::Pod5->new(), 'Constructed renderer object');

my ($text, $ansi);
open my $out_fh_text, '>', \$text or fail "Can't open output FH";
open my $out_fh_ansi, '>', \$ansi or fail "Can't open output FH";

$render->render($pod, $out_fh_text, 'text');
$render->render($pod, $out_fh_ansi, 'ansi');

ok(length $text, 'Got text output');
ok(length $ansi, 'Got colored text output');
ok(length($ansi) > length($text), 'Colored output is longer than uncolored');
