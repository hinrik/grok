use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $script = catfile('script', 'grok');
my $pod = catfile('t_source', 'basic.pod');
my $result_paged         = qx/$script -F $pod/; # TODO: test this
my $result_unpaged_short = qx/$script -F $pod -T/;
my $result_unpaged_long  = qx/$script -F $pod --no-pager/;

ok(length $result_unpaged_short, 'Got unpaged output (-T)');
ok(length $result_unpaged_long, 'Got unpaged output (--no-pager)');

