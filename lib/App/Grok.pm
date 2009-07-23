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

our $VERSION = '0.14';
my %opt;

our $GOT_ANSI;
BEGIN {
    if ($^O ne 'Win32') {
        eval {
            require Win32::Console::ANSI;
            $GOT_ANSI = 1;
        }
    }
    else {
        $GOT_ANSI = 1;
    }
}

sub new {
    my ($package, %self) = @_;
    return bless \%self, $package;
}

sub run {
    my ($self) = @_;

    $self->_get_options();

    if ($opt{index}) {
        print join("\n", $self->target_index()) . "\n";
        return;
    }

    my $target = defined $opt{file} ? $opt{file} : $ARGV[0];

    if ($opt{only}) {
        my $file = $opt{file};
        $file = $self->find_target_file($target) if !defined $file;
        die "No matching file found for target '$target'\n" if !defined $file;
        print $file, "\n";
    }
    else {
        my $rendered;
        if ($opt{file}) {
            $rendered = $self->render_file($opt{file}, $opt{output});
        }
        else {
            $rendered = $self->render_target($target, $opt{output});
        }

        die "Target '$target' not recognized\n" if !defined $rendered;
        $self->_print($rendered, $opt{output});
    }

    return;
}

sub _get_options {
    my ($self) = @_;

    GetOptions(
        'F|file=s'      => \$opt{file},
        'h|help'        => sub { pod2usage(1) },
        'i|index'       => \$opt{index},
        'l|locate'      => \$opt{locate},
        'o|output=s'    => \($opt{output} = $GOT_ANSI ? 'ansi' : 'text'),
        'T|no-pager'    => \$opt{no_pager},
        'u|unformatted' => sub { $opt{output} = 'pod' },
        'V|version'  => sub { print "grok $VERSION\n"; exit },
    ) or pod2usage();

    if (!$opt{index} && !defined $opt{file} && !@ARGV) {
        warn "Too few arguments\n";
        pod2usage();
    }

    return;
}

# functions from synopsis 29
sub read_functions {
    my ($self) = @_;

    return $self->{functions} if defined $self->{functions};

    my %functions;
    my $S29_file = catfile(dist_dir('Perl6-Doc'), 'Synopsis', 'S29-functions.pod');

    ## no critic (InputOutput::RequireBriefOpen)
    open my $S29, '<', $S29_file or die "Can't open '$S29_file': $!";

    # read until you find 'Function Packages'
    until (<$S29> =~ /Function Packages/) {}

    # parse the rest of S29 looking for Perl6 function documentation
    my $function_name;
    while (my $line = <$S29>) {
        if (my ($directive, $title) = $line =~ /^=(\S+) +(.+)/) {
            if ($directive eq 'item') {
                # Found Perl6 function name
                if (my ($reference) = $title =~ /-- (see S\d+.*)/) {
                    # one-line entries
                    (my $func = $title) =~ s/^(\S+).*/$1/;
                    $functions{$func} = $reference;
                }
                else {
                    $function_name = $title;
                }
            }
            else {
                $function_name = undef;
            }
        }
        elsif ($function_name) {
            # Adding documentation to the function name
            $functions{$function_name} .= $line;
        }
    }

    my %sanitized;
    while (my ($func, $body) = each %functions) {
        $sanitized{$func} = [$func, $body] if $func !~ /\s/;

        if ($func =~ /,/) {
            my @funcs = split /,\s+/, $func;
            $sanitized{$_} = [$func, $body] for @funcs;
        }
    }

    $self->{functions} = \%sanitized;
    return $self->{functions};
}

sub read_table {
    my ($self) = @_;

    return $self->{table} if defined $self->{table};

    my %table;
    my $table_file = catfile(dist_dir('Perl6-Doc'), 'table_index.pod');

    ## no critic (InputOutput::RequireBriefOpen)
    open my $table_handle, '<', $table_file or die "Can't open '$table_file': $!";

    my $entry;
    while (my $line = <$table_handle>) {
        $entry = $1 if $line =~ /^=head2 C<<< (.+) >>>$/;
        $table{$entry} .= $line if defined $entry;
    }

    $self->{table} = \%table;
    return \%table;
}

sub target_index {
    my ($self) = @_;
    
    my @index;
    my %docs = map {
        substr($_, 0, 1) => catdir(dist_dir('Perl6-Doc'), $_)
    } qw<Apocalypse Exegesis Magazine Synopsis>;

    while (my ($type, $dir) = each %docs) {
        my @parts = map { (splitpath($_))[2] } glob "$dir/*.pod";
        s/\.pod$// for @parts;
        push @index, @parts;
    }

    # synopsis 32
    my $S32_dir = catdir($docs{S}, 'S32-setting-library');
    my @sections = map { (splitpath($_))[2] } glob "$S32_dir/*.pod";
    s/\.pod$// for @sections;
    push @index, map { "S32-$_" } @sections;

    # functions from synopsis 29
    push @index, sort keys %{ $self->read_functions() };

    # entries from the Perl 6 Table Index
    push @index, sort keys %{ $self->read_table() };
    
    return @index;
}

sub detect_source {
    my ($self, $file) = @_;

    open my $handle, '<', $file or die "Can't open $file";
    my $contents = do { local $/ = undef; scalar <$handle> };
    close $handle;

    $contents =~ s/.*^=encoding\b.*$//m; # skip over =encoding
    my ($first_pod) = $contents =~ /^(=\S+)/m;
    return if !defined $first_pod; # no Pod found

    if ($first_pod =~ /^=(?:pod|head\d+|over)$/
            || $contents =~ /^=cut\b/m) {
        return 'App::Grok::Parser::Pod5';
    }
    else {
        return 'App::Grok::Parser::Pod6';
    }
}

sub find_target_file {
    my ($self, $arg) = @_;

    my $target = $self->find_perl6_doc($arg);
    $target = $self->find_module_or_program($arg) if !defined $target;

    return if !defined $target;
    return $target;
}

sub find_perl6_doc {
    my ($self, $doc) = @_;
    
    my $dist = dist_dir('Perl6-Doc');
    return catfile($dist, 'table_index.pod') if $doc eq 'table_index';

    my %docs = map {
        substr($_, 0, 1) => catdir($dist, $_)
    } qw<Apocalypse Exegesis Magazine Synopsis>;

    # S32 is split up, need to special-case it
    if (my ($section) = $doc =~ /^S32-(\S+)$/i) {
        my $S32_dir = catdir($docs{S}, 'S32-setting-library');
        my @sections = map { (splitpath($_))[2] } glob "$S32_dir/*.pod";
        my $found = first { /^$section/i } @sections;
        
        if (defined $found) {
            return catfile($S32_dir, $found);
        }
    }
    elsif (my ($type) = $doc =~ /^(\w)\d+/i) {
        my @parts = map { (splitpath($_))[2] } glob "$docs{uc $type}/*.pod";
        my $found = first { /\Q$doc/i } @parts;
        
        return if !defined $found;
        return catfile($docs{uc $type}, $found);
    }

    return;
}

sub find_module_or_program {
    my ($self, $file) = @_;

    # TODO: do a grand search
    return $file if -e $file;
    return;
}

sub render_target {
    my ($self, $target, $output) = @_;

    my $functions = $self->read_functions();
    if (defined $functions->{$target}) {
        my ($func, $body) = @{ $functions->{$target} };
        my $renderer = 'App::Grok::Parser::Pod5';
        eval "require $renderer";
        die $@ if $@;
        my $content = "=head1 $func\n\n$body";
        return $renderer->new->render_string($content, $output);
    }

    my $entries = $self->read_table();
    if (defined $entries->{$target}) {
        my $content = $entries->{$target};
        my $renderer = 'App::Grok::Parser::Pod5';
        eval "require $renderer";
        die $@ if $@;
        return $renderer->new->render_string($content, $output);
    }

    my $file = $self->find_target_file($target);
    if (defined $file) {
        return $self->render_file($file, $output);
    }

    return;
}

sub render_file {
    my ($self, $file, $output) = @_;
    
    my $renderer = $self->detect_source($file);
    eval "require $renderer";
    die $@ if $@;
    return $renderer->new->render_file($file, $output);
}

sub _print {
    my ($self, $rendered, $output) = @_;

    if ($opt{no_pager} || !is_interactive()) {
        print $rendered;
    }
    else {
        my $pager = defined $ENV{PAGER} ? $ENV{PAGER} : $Config{pager};

        my @args;
        # tell less(1) to display colors without a fuss
        push @args, '-f', '-R' if $pager =~ /less/ && $output eq 'ansi';

        my ($temp_fh, $temp) = tempfile(UNLINK => 1);
        print $temp_fh $rendered;
        close $temp_fh;

        # $pager might contain options (e.g. "more /e") so we pass a string
        $^O eq 'MSWin32'
            ? system $pager . qq{ @args "$temp"}
            : system $pager . qq{ @args '$temp'}
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

=head2 C<read_functions>

Takes no arguments. Returns a hash reference of all function documentation
from Synopsis 29. There will be a key for every function, with the value being
a Pod snippet from Synopsis 29.

=head2 C<read_table>

Takes no arguments. Returns a hash reference of all entries in the
I<Perl 6 Table Index>. Keys are the entry names, values are Pod snippets.

=head2 C<detect_source>

Takes a filename as an argument. Returns the name of the appropriate
C<App::Grok::*> class to parse it. Returns nothing if the file doesn't contain
any Pod.

=head2 C<find_target_file>

Takes a valid C<grok> target as an argument. If found, it will return a path
to a matching file, otherwise it returns nothing.

=head2 C<find_perl6_doc>

Takes the name (or a substring of a name) of a Synopsis as an argument.
Returns a path to a matching file if one is found, otherwise returns nothing.
B<Note:> this method is called by L<C<find_target>|/find_target>.

=head2 C<find_module_or_program>

Takes the name of a module or a program. Returns a path to a matching file
if one is found, otherwise returns nothing. B<Note:> this doesn't do anything
yet.

=head2 C<render_target>

Takes two arguments, a target and the name of an output format. Returns a
string containing the rendered documentation, or nothing if the target is
unrecognized.

=head2 C<render_file>

Takes two arguments, a filename and the name of an output format. Returns
a string containing the rendered document. B<Note:> this method is called
by L<C<render_target>|/render_target>.

=head1 AUTHOR

Hinrik Örn Sigurðsson, L<hinrik.sig@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Hinrik Örn Sigurðsson

C<grok> is distributed under the terms of the Artistic License 2.0.
For more details, see the full text of the license in the file F<LICENSE>
that came with this distribution.

=cut
