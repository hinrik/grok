package App::Grok::Resource::Table;

use strict;
use warnings;
use File::ShareDir qw<dist_dir>;
use File::Spec::Functions qw<catfile>;

our $VERSION = '0.18_02';
use base qw(Exporter);
our @EXPORT_OK = qw(table_index table_fetch table_locate);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

my %table;
my $table_file = catfile(dist_dir('Perl6-Doc'), 'table_index.pod');

sub table_fetch {
    my ($topic) = @_;
    _build_table() if !%table;

    return $table{$topic} if defined $table{$topic};
    return;
}

sub table_index {
    _build_table() if !%table;
    return keys %table;
}

sub table_locate {
    return $table_file;
}

sub _build_table {
    my ($self) = @_; 

    ## no critic (InputOutput::RequireBriefOpen)
    open my $table_handle, '<', $table_file or die "Can't open '$table_file': $!";

    my $entry;
    while (my $line = <$table_handle>) {
        $entry = $1 if $line =~ /^=head2 C<<< (.+) >>>$/;
        $table{$entry} .= $line if defined $entry;
    }
    while (my ($key, $value) = each %table) {
        $table{$key} = "=encoding UTF-8\n\n$value";
    }

    return;
}

1;
=head1 NAME

App::Grok::Resource::Table - Perl 6 Table Index resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::Table qw<:ALL>;

 # a list of all entries in the table
 my @index = table_index();

 # documentation for a table entry
 my $pod = table_fetch('+');

 # filename where the table entry was found
 my $file = table_locate('+');

=head1 DESCRIPTION

This resource looks up entries in the Perl 6 Table Index
(L<http://www.perlfoundation.org/perl6/index.cgi?perl_table_index>.

=head1 METHODS

=head2 C<table_index>

Takes no arguments. Lists all entry names in the table.

=head2 C<table_fetch>

Takes an entry name as an argument. Returns the documentation for it.

=head2 C<table_locate>

Takes an entry name as an argument. Returns the name of the file where it
was found.

=cut
