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

    if ($opt{index}) {
        print $self->target_index();
        return;
    }

    my $target = defined $opt{file}
        ? $opt{file}
        : $self->find_target($ARGV[0])
    ;

    die "No matching files found for target '$target'" if !-e $target;

    if ($opt{only}) {
        print "$target\n";
    }
    else {
        $self->render_file($target);
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

    if (!$opt{index} && !defined $opt{file} && !@ARGV) {
        warn "Too few arguments\n";
        pod2usage();
    }
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

sub detect_source {
    my ($self, $file) = @_;

    open my $handle, '<', $file or die "Can't open $file";
    my $contents = do { local $/; scalar <$handle> };
    close $handle;

    my ($first_pod) = $contents =~ /(^=(?!encoding)\S+)/m;
    return if !defined $first_pod; # no Pod found

    if ($first_pod =~ /^=(?:pod|head\d+|over)$/
            || $contents =~ /^=cut\b/m) {
        return 'App::Grok::Pod5';
    }
    else {
        return 'App::Grok::Pod6';
    }
}

sub find_target {
    my ($self, $arg) = @_;

    my $target = $self->find_synopsis($arg);
    $target = $self->find_file($arg) if !defined $target;

    die "Target '$arg' not recognized\n" if !$target;
    return $target;
}

sub find_synopsis {
    my ($self, $syn) = @_;
    my $dir = catdir($self->{share_dir}, 'Spec');

    if ($syn =~ /^S\d+$/i) {
        my @synopses = map { (splitpath($_))[2] } glob "$dir/*.pod";
        my $found = first { /$syn/i } @synopses;
        
        return if !defined $found;
        return catfile($dir, $found);
    }
    elsif (my ($section) = $syn =~ /^S32-(\S+)$/i) {
        my $S32_dir = catdir($dir, 'S32-setting-library');
        my @sections = map { (splitpath($_))[2] } glob "$S32_dir/*.pod";
        my $found = first { /$section/i } @sections;
        
        if (defined $found) {
            return catfile($S32_dir, $found);
        }
    }

    return;
}

sub find_file {
    my ($self, $file) = @_;

    # TODO: do a grand search
    return $file;
}

sub render_file {
    my ($self, $file) = @_;
    
    my $renderer = $self->detect_source($file);
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
