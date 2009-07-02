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

our $VERSION = '0.09';
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

    $self->_get_options();

    if ($opt{index}) {
        print join("\n", $self->target_index()) . "\n";
        return;
    }

    my $target = defined $opt{file}
        ? $opt{file}
        : $self->find_target($ARGV[0])
    ;

    die "No matching files found for target '$target'\n" if !-e $target;

    if ($opt{only}) {
        print "$target\n";
    }
    else {
        my $output = $self->render_file($target, $opt{output});
        $self->_print($output);
    }

    return;
}

sub _get_options {
    my ($self) = @_;

    GetOptions(
        'F|file=s'      => \$opt{file},
        'h|help'        => sub { pod2usage(1) },
        'i|index'       => \$opt{index},
        'l|only'        => \$opt{only},
        'o|output=s'    => \($opt{output} = 'ansi'),
        'T|no-pager'    => \$opt{no_pager},
        'u|unformatted' => \$opt{unformatted},
        'V|version'  => sub { print "grok $VERSION\n"; exit },
    ) or pod2usage();

    $opt{output} = 'pod' if $opt{unformatted};

    if (!$opt{index} && !defined $opt{file} && !@ARGV) {
        warn "Too few arguments\n";
        pod2usage();
    }

    return;
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
    return @index;
}

sub detect_source {
    my ($self, $file) = @_;

    open my $handle, '<', $file or die "Can't open $file";
    my $contents = do { local $/ = undef; scalar <$handle> };
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
    $target = $self->find_module_or_program($arg) if !defined $target;

    return if !defined $target;
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

sub find_module_or_program {
    my ($self, $file) = @_;

    # TODO: do a grand search
    return $file;
}

sub render_file {
    my ($self, $file, $output) = @_;
    
    my $renderer = $self->detect_source($file);
    eval "require $renderer";
    die $@ if $@;
    return $renderer->new->render($file, $output);
}

sub _print {
    my ($self, $output) = @_;

    if ($opt{no_pager} || !is_interactive()) {
        print $output;
    }
    else {
        my $pager = $Config{pager};
        my ($temp_fh, $temp) = tempfile(UNLINK => 1);
        print $temp_fh $output;
        close $temp_fh;

        # $pager might contain options (e.g. "more /e") so we pass a string
        $^O eq 'MSWin32'
            ? system $pager . qq{ "$temp"}
            : system $pager . qq{ '$temp'}
        ;
    }

    return;
}

1;

=encoding UTF-8

=head1 NAME

App::Grok - Does most of grok's heavy lifting

=head1 DESCRIPTION

This class provides the main functionality needed by grok. It has some
methods you can use if you need to hook into grok.

=head1 METHODS

=head2 C<new>

This is the constructor. It takes no arguments.

=head2 C<run>

If you call this method, it will look at the command line arguments in
C<@ARGV> and act accordingly. This is basically what the L<C<grok>|grok>
program does. Takes no arguments.

=head2 C<target_index>

Takes no arguments. Returns a list of all the targets known to C<grok>.

=head2 C<detect_source>

Takes a filename as an argument. Returns the name of the appropriate
C<App::Grok::*> class to parse it. Returns nothing if the file doesn't contain
any Pod.

=head2 C<find_target>

Takes a valid C<grok> target as an argument. If found, it will return a path
to a matching file, otherwise it returns nothing.

=head2 C<find_synopsis>

Takes the name (or a substring of a name) of a Synopsis as an argument.
Returns a path to a matching file if one is found, otherwise returns nothing.
B<Note:> this method is called by L<C<find_target>|/find_target>.

=head2 C<find_module_or_program>

Takes the name of a module or a program. Returns a path to a matching file
if one is found, otherwise returns nothing. B<Note:> this doesn't do anything
yet.

=head2 C<render_file>

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
