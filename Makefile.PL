use strict;
use warnings;
use inc::Module::Install;
use 5.006;

name           ('grok');
perl_version   ('5.006');
author         ('Hinrik Örn Sigurðsson <hinrik.sig@gmail.com>');
abstract       ('Perl 6 documentation reader');
version_from   ('script/grok');
install_script ('script/grok');
no_index       (directory => 't_source');
install_share  (install_share => 'share');
license        ('artistic_2');
requires       ('Getopt::Long'             => '2.33');
requires       ('Perl6::Perldoc'           => '0.0.5');
requires       ('Perl6::Perldoc::To::Ansi' => '0.01');
requires       ('Pod::Usage'               => '0');
test_requires  ('Test::More'               => '0');
test_requires  ('Test::Script'             => '0');
tests_recursive;
WriteAll();

