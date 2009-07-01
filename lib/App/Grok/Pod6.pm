package App::Grok::Pod6;

# blows up if we use strict before this, damn source filter
use Perl6::Perldoc::Parser;

use strict;
use warnings;

our $VERSION = '0.08';

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub render {
    my ($self, $file, $format) = @_;

    die "Format $format unsupported" if $format !~ /^(?:ansi|text|xhtml)$/;
    eval "require Perl6::Perldoc::To::\u$format";
    die $@ if $@;

    my $method = "to_$format";
    return Perl6::Perldoc::Parser->parse($file, {all_pod=>'auto'})
                                 ->report_errors()
                                 ->$method();
}

1;

=encoding UTF-8

=head1 NAME

App::Grok::Pod6 - A Pod 6 backend for grok

=head1 METHODS

=head2 C<new>

This is the constructor. It currently takes no arguments.

=head2 C<render>

Takes two arguments, a filename and the name of an output format. Returns
a string containing the rendered document. It will C<die> if there is an
error.

=head1 AUTHOR

Hinrik Örn Sigurðsson, L<hinrik.sig@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Hinrik Örn Sigurðsson

C<grok> is distributed under the terms of the Artistic License 2.0.
For more details, see the full text of the license in the file F<LICENSE>
that came with this distribution.

=cut
