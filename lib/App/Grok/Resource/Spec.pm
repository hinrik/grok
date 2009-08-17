package App::Grok::Resource::Spec;

use strict;
use warnings;
use File::ShareDir qw<dist_dir>;
use File::Spec::Functions qw<catdir splitpath>;

our $VERSION = '0.19';
use base qw(Exporter);
our @EXPORT_OK = qw(spec_index spec_fetch spec_locate);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

my %index;
my $dist_dir = dist_dir('Perl6-Doc');
my %docs = map {
    substr($_, 0, 1) => catdir($dist_dir, $_) 
} qw<Apocalypse Exegesis Magazine Synopsis>;

sub spec_fetch {
    my ($topic) = @_;
    _build_index() if !%index;
    
    for my $doc (keys %index) {
        if ($doc =~ /^\Q$topic/i) {
            open my $handle, '<', $index{$doc} or die "Can't open $index{$doc}: $!";
            my $pod = do { local $/ = undef; scalar <$handle> };
            close $handle;
            return $pod;
        }
    }
    return;
}

sub spec_index {
    _build_index() if !%index;
    return keys %index;
}

sub spec_locate {
    my ($topic) = @_;
    _build_index() if !%index;
    
    for my $doc (keys %index) {
        return $index{$doc} if $doc =~ /^$topic/i;
    }

    return;
}

sub _build_index {
    while (my ($type, $dir) = each %docs) {
        for my $file (glob "$dir/*.pod") {
            my $name = (splitpath($file))[2];
            $name =~ s/\.pod$//;
            $index{$name} = $file;
        }
    }

    # man pages (perlintro, etc)
    my $pages_dir = catdir($dist_dir, 'man_pages');
    for my $file (glob "$pages_dir/*.pod") {
        my $name = (splitpath($file))[2];
        $name =~ s/\.pod$//;
        $index{$name} = $file;
    }

    # synopsis 32
    my $S32_dir = catdir($docs{S}, 'S32-setting-library');
    for my $file (glob "$S32_dir/*.pod") {
        my $name = (splitpath($file))[2];
        $name =~ s/\.pod$//;
        $name = "S32-$name";
        $index{$name} = $file;
    }

    return;
}

1;
=head1 NAME

App::Grok::Resource::Spec - Perl 6 specification resource for grok

=head1 SYNOPSIS

 use strict;
 use warnings;
 use App::Grok::Resource::Spec qw<:ALL>;

 # list of all Synopsis, Exegeses, etc
 my @index = spec_index();

 # get the contents of Synopsis 02
 my $pod = spec_fetch('s02');

 # filename containing S02
 my $file = spec_locate('s02');

=head1 DESCRIPTION

This module the locates Apocalypses, Exegeses, Synopsis and magazine articles
distributed with L<Perl6::Doc>.

It also includes user documentation like F<perlintro> and F<perlsyn>.

=head1 METHODS

=head2 C<spec_index>

Doesn't take any arguments. Returns a list of all documents known to this
resource.

=head2 C<spec_fetch>

Takes the name of a document as an argument. It is case-insensitive and you
only need to specify the first three characters (though more are allowed),
e.g. C<spec_fetch('s02')>. Returns the Pod text of the document.

=head2 C<spec_locate>

Takes the same argument as L<C<spec_fetch>|/spec_fetch>. Returns the filename
corresponding to the given document.

=cut
