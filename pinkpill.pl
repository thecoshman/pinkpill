#!/usr/bin/perl
use strict;
use warnings;
use PinkPill;

my $pp = new PinkPill;
$pp->set_options(
    src_folder => '../thecoshman-kyrostat/src',
    compilers_flags => '-std=C++0x -Wall -Wextra',
);
$, = "\n";
#my @options = PinkPill->config_options();
#print @options;
#print "\n\n";
my @options = $pp->config_options();
print @options;
print "\n\n";
print "\nError logs...\n" and print $pp->error_logs unless $pp->build;

