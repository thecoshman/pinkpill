#!/usr/bin/perl
use strict;
use warnings;
use pinkpill;

my $pp = new pinkpill;

$, = "\n";
print $pp->config_options;
print "PinkPill";

