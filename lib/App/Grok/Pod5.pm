package App::Grok::Pod5;

use strict;
use warnings;

our $VERSION = '0.09';

my %formatter = (
    text  => 'Pod::Text',
    ansi  => 'Pod::Text::Color',
    xhtml => 'Pod::Xhtml',
    pod   => 'Pod::Perldoc::ToPod',
);

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub render_file {
    my ($self, $file, $format) = @_;

    my $form = $formatter{$format};
    die __PACKAGE__ . " doesn't support the '$format' format" if !defined $form;
    eval "require $form";
    die $@ if $@;

    my $pod = '';
    open my $out_fh, '>', \$pod or die "Can't open output filehandle: $!";
    binmode $out_fh, ':utf8' if $form ne 'Pod::Perldoc::ToPod';
    $form->new->parse_from_file($file, $out_fh);
    close $out_fh;
    return $pod;
}

sub render_string {
    my ($self, $string, $format) = @_;

    open my $handle, '<', \$string or die "Can't open input filehandle: $!";
    my $result = $self->render_file($handle, $format);
    close $handle;
    return $result;
}

1;

=encoding UTF-8

=head1 NAME

App::Grok::Pod5 - A Pod 5 backend for grok

=head1 METHODS

=head2 C<new>

This is the constructor. It currently takes no arguments.

=head2 C<render_file>

Takes two arguments, a filename and the name of an output format. Returns
a string containing the rendered document. It will C<die> if there is an
error.

=head2 C<render_string>

Takes two arguments, a string and the name of an output format. Returns
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
