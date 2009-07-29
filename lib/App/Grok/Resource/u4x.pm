package App::Grok::Resource::u4x;

use strict;
use warnings;

our $VERSION = '0.18_02';
use base qw(Exporter);
our @EXPORT_OK = qw(u4x_index u4x_fetch u4x_locate);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

my %index;

sub u4x_fetch {
    my ($topic) = @_;

    return $index{$topic} if defined $index{$topic};
    return;
}

sub u4x_index {
    return keys %index;
}

sub u4x_locate {
    my ($topic) = @_;
    return __FILE__ if $index{$topic};
    return;
}

1;
=head1 NAME

App::Grok::Resource::u4x - u4x resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::u4x qw<:ALL>;

 # a list of all terms
 my @index = u4x_index();

 # documentation for a single term 
 my $pod = u4x_fetch('infix:<+>');

=head1 DESCRIPTION

This resource looks maintains an index of syntax items that can be looked up.
See L<http://svn.pugscode.org/pugs/docs/u4x/README>.

=head1 METHODS

=head2 C<u4x_index>

Takes no arguments. Lists all syntax items.

=head2 C<u4x_fetch>

Takes an syntax item as an argument. Returns the documentation for it.

=head2 C<u4x_locate>

Takes a syntax item as an argument. Returns the file where it was found.

=cut
