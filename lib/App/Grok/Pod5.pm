package App::Grok::Pod5;

use strict;
use warnings;

our $VERSION = '0.03';

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub render {
    my ($self, $file, $out_fh, $format) = @_;

    my $formatter = $format eq 'ansi'
        ? 'Pod::Text::Color'
        : 'Pod::Text'
    ;

    eval "require $formatter";
    $formatter->new->parse_from_file($file, $out_fh);
}

1;
