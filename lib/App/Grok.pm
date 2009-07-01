package App::Grok;

use strict;
use warnings;
use Config qw<%Config>;
use File::ShareDir qw<dist_dir>;
use File::Spec::Functions qw<catdir catfile splitpath>;
use File::Temp qw<tempfile>;
use IO::Interactive qw<is_interactive>;
use Getopt::Long qw<:config bundling>;
use List::Util qw<first>;
use Pod::Usage;

our $VERSION = '0.08';
my %opt;

sub new {
    my ($package, %self) = @_;

    $self{share_dir} = defined $ENV{GROK_SHAREDIR}
        ? $ENV{GROK_SHAREDIR}
        : dist_dir('grok')
    ;

    return bless \%self, $package;
}

sub run {
    my ($self) = @_;

    $self->get_options();
    my ($target, $renderer);

    if ($opt{index}) {
        print $self->target_index();
        return;
    }

    if (defined $opt{file}) {
        ($target, $renderer) = ($opt{file}, 'App::Grok::Pod6');
    }
    else {
        ($target, $renderer) = $self->find_target($ARGV[0]);
    }

    die "No matching files found for target '$target'" if !-e $target;

    if ($opt{only}) {
        print "$target\n";
    }
    else {
        $self->render_file($target, $renderer);
    }
}

sub get_options {
    my ($self) = @_;

    GetOptions(
        'F|file=s'   => \$opt{file},
        'f|format=s' => \($opt{format} = 'ansi'),
        'h|help'     => sub { pod2usage(1) },
        'i|index'    => \$opt{index},
        'l|only'     => \$opt{only},
        'T|no-pager' => \$opt{no_pager},
        'V|version'  => sub { print "grok $VERSION\n"; exit },
    ) or pod2usage();

    die "Too few arguments\n" if !$opt{index} && !defined $opt{file} && !@ARGV;
}

sub target_index {
    my ($self) = @_;
    my $dir = catdir($self->{share_dir}, 'Spec');
    my @index;

    my @synopses = map { (splitpath($_))[2] } glob "$dir/*.pod";
    push @index, @synopses;

    my $S32_dir = catdir($dir, 'S32-setting-library');
    my @sections = map { (splitpath($_))[2] } glob "$S32_dir/*.pod";
    push @index, map { "S32-$_" } @sections;

    s/\.pod$// for @index;
    return join("\n", @index) . "\n";
}

sub find_target {
    my ($self, $arg) = @_;

    my ($target, $renderer);
    ($target, $renderer) = $self->find_synopsis($arg);
    ($target, $renderer) = $self->find_file($arg) if !defined $target;

    die "Target '$arg' not recognized\n" if !$target;
    return ($target, $renderer);
}

sub find_synopsis {
    my ($self, $syn) = @_;
    my $dir = catdir($self->{share_dir}, 'Spec');

    if ($syn =~ /^S\d+$/i) {
        my @synopses = map { (splitpath($_))[2] } glob "$dir/*.pod";
        my $found = first { /$syn/i } @synopses;
        
        return if !defined $found;

        if ($found =~ /^S26/) {
            return (catfile($dir, $found), 'App::Grok::Pod6');
        }
        else {
            return (catfile($dir, $found), 'App::Grok::Pod5');
        }
    }
    elsif (my ($section) = $syn =~ /^S32-(\S+)$/i) {
        my $S32_dir = catdir($dir, 'S32-setting-library');
        my @sections = map { (splitpath($_))[2] } glob "$S32_dir/*.pod";
        my $found = first { /$section/i } @sections;
        
        if (defined $found) {
            return (catfile($S32_dir, $found), 'App::Grok::Pod5');
        }
    }

    return;
}

sub find_file {
    my ($self, $file) = @_;

    # TODO: do a grand search
    return ($file, 'App::Grok::Pod6');
}

sub render_file {
    my ($self, $file, $renderer) = @_;
    
    eval "require $renderer";
    die $@ if $@;
    my $pod = $renderer->new->render($file, $opt{format});

    if ($opt{no_pager} || !is_interactive()) {
        print $pod;
    }
    else {
        my $pager = $Config{pager};
        my ($temp_fh, $temp) = tempfile(UNLINK => 1);
        print $temp_fh $pod;
        close $temp_fh;

        # $pager might contain options (e.g. "more /e") so we pass a string
        $^O eq 'MSWin32'
            ? system $pager . qq{ "$temp"}
            : system $pager . qq{ '$temp'}
        ;
    }
}

1;

=encoding UTF-8

=head1 NAME

App::Grok - Does most of grok's heavy lifting

=head1 AUTHOR

Hinrik Örn Sigurðsson, L<hinrik.sig@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Hinrik Örn Sigurðsson

C<grok> is distributed under the terms of the Artistic License 2.0.
For more details, see the full text of the license in the file F<LICENSE>
that came with this distribution.

=cut
