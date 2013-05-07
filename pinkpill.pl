#!/usr/bin/perl
use strict;
use warnings;
use PinkPill;

my $pp = new PinkPill;
$pp->set_options(
    src_folder => 'src',
    build_folder => 'bin',
    obj_folder => 'obj',
    compiler_flags => '-std=C++11 -Wall -Wextra',
);
$, = "\n";
#my @options = PinkPill->config_options();
#print @options;
#print "\n\n";
my @options = $pp->config_options();
print @options;
print "\n\n";
print "\nError logs...\n" and print $pp->error_logs unless $pp->build;

