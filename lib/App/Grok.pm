package App::Grok;

# blows up if we use strict before this, damn source filter
use Perl6::Perldoc::Parser;

use strict;
use warnings;
use Config qw<%Config>;
use File::Temp qw<tempfile>;
use IO::Interactive qw<is_interactive>;
use Getopt::Long qw<:config bundling>;
use Pod::Usage;

our $VERSION = '0.03';

sub run {
    GetOptions(
        'F|file=s'   => \my $from_file,
        'f|format=s' => \(my $format = 'ansi'),
        'h|help'     => sub { pod2usage(1) },
        'T|no-pager' => \my $no_pager,
        'v|version'  => sub { print "grok $VERSION\n"; exit },
    ) or pod2usage();

    if (!defined $from_file) {
        die "You must supply --file with an argument; see --help\n";
    }
    
    if ($format ne 'text' && $format ne 'ansi') {
        die "Format '$format' is unsupported\n";
    }
    
    $format eq 'text'
        ? require Perl6::Perldoc::To::Text
        : require Perl6::Perldoc::To::Ansi
    ;

    my $pod = Perl6::Perldoc::Parser->parse($from_file, {all_pod=>'auto'})
                                    ->report_errors()
                                    ->to_text();

    if ($no_pager || !is_interactive()) {
        print $pod;
    }
    else {
        my $pager = $Config{pager};
        my ($temp_fh, $temp) = tempfile(UNLINK => 1);
        print $temp_fh $pod;
        system $pager, $temp;
    }
}

1;
