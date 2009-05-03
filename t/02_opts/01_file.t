use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 3;

my $script = catfile('script', 'grok');
my $pod = catfile('t_source', 'basic.pod');
my $result = qx/$script -F $pod/;

for my $para (qw(Foo Bar Baz)) {
    like($result, qr/$para/, "Paragraph $para");
}
