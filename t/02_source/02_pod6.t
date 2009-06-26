use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 4;
use App::Grok::Pod6;

my $pod = catfile('t_source', 'basic.pod');
ok(my $render = App::Grok::Pod6->new(), 'Constructed renderer object');

my $text = $render->render($pod, 'text');
my $ansi = $render->render($pod, 'ansi');

ok(length $text, 'Got text output');
ok(length $ansi, 'Got colored text output');
ok(length($ansi) > length($text), 'Colored output is longer than uncolored');
