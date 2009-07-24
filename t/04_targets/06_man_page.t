use strict;
use warnings;
use File::Spec::Functions 'catfile';
use Test::More tests => 2;

my $grok = catfile('script', 'grok');

my $perlintro = qx/$^X $grok perlintro/;
my $perlsyn   = qx/$^X $grok perlsyn/;

like($perlintro, qr/A brief introduction and overview of Perl 6/, 'Got perlintro');
like($perlsyn, qr/Perl syntax/, 'Got perlsyn');
