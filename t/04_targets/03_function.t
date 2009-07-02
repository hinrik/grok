use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

$ENV{GROK_SHAREDIR} = 'share';
my $grok = catfile('script', 'grok');

my $fork = qx/$^X $grok fork/;
my $kill = qx/$^X $grok kill/;

like($fork, qr/process/, "Got fork()");
like($kill, qr/TERM/, "Got kill()");
