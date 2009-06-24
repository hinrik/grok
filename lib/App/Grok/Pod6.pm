package App::Grok::Pod6;

# blows up if we use strict before this, damn source filter
use Perl6::Perldoc::Parser;

use strict;
use warnings;

our $VERSION = '0.03';

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub render {
    my ($self, $file, $out_fh, $format) = @_;

    $format eq 'ansi'
        ? require Perl6::Perldoc::To::Ansi
        : require Perl6::Perldoc::To::Text
    ;

    print $out_fh Perl6::Perldoc::Parser->parse($file, {all_pod=>'auto'})
                                        ->report_errors()
                                        ->to_text();
}

1;
