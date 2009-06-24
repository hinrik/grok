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

our $VERSION = '0.03';
my %opt;

sub new {
    return bless { }, shift;
}

sub run {
    get_options();
    if (defined $opt{file}) {
        render_file($opt{file}, 'App::Grok::Pod6');
    }
    else {
        my $arg = shift @ARGV;
        find_target($arg);
    }
}

sub get_options {
    GetOptions(
        'F|file=s'   => \$opt{file},
        'f|format=s' => \($opt{format} = 'ansi'),
        'h|help'     => sub { pod2usage(1) },
        'T|no-pager' => \$opt{no_pager},
        'v|version'  => sub { print "grok $VERSION\n"; exit },
    ) or pod2usage();

    if ($opt{format} ne 'text' && $opt{format} ne 'ansi') {
        die "Format '$opt{format}' is unsupported\n";
    }

    die "Too few arguments\n" if !defined $opt{file} && !@ARGV;
}

sub find_target {
    my ($arg) = @_;

    my ($target, $renderer);
    ($target, $renderer) = find_synopsis($arg);
    ($target, $renderer) = find_file($arg) if !defined $target;

    die "Target '$arg' not recognized\n" if !$target;
    render_file($target, $renderer);
}

sub find_synopsis {
    my ($syn) = @_;

    # we override this during testing
    my $share = defined $ENV{GROK_SHAREDIR}
        ? $ENV{GROK_SHAREDIR}
        : dist_dir('App-Grok')
    ;
    my $dir = catdir($share, 'Spec');

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
    my ($file) = @_;

    # TODO: do a grand search and render the found file
    return ($file, 'App::Grok::Pod6');
}

sub render_file {
    my ($file, $renderer) = @_;
    
    eval "require $renderer";
    die $@ if $@;

    my $pod;
    open my $out_fh, '>', \$pod or die "Couldn't open output FH: $!";
    binmode $out_fh, ':utf8';
    $renderer->new->render($file, $out_fh, $opt{format});

    if ($opt{no_pager} || !is_interactive()) {
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
