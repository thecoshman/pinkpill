pinkpill
========

An excuse to play around with Perl wrapped up as a poor attempt at a build system for C++

Bare bones build script
=======================

As the code for pinkpill is all contained in a single perl module, all you need to be to use it to build your system is a very minimal perl script, which you can modify with next to no knowledge of perl itself. The repository comes with a basic script for you to use and modify to suit your needs, but for the sake of completeness, here is the very minimum sample of code required to get pinkpill to build your project, assuming your project is set up 'correctly'.

    #!/usr/bin/perl
    use PinkPill;
    $p = new PinkPill;
    $p->build;

