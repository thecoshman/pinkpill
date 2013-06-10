pinkpill
========

Pinkpill is a build system dedicated to C++. It started as an excuse for myself play around with Perl, and is now something a bit more usable.

Bare bones build script
=======================

As the code for pinkpill is all contained in a single Perl module, all you need to be to use it to build your project is a very minimal Perl script, which you can modify with next to no knowledge of Perl itself. The repository comes with a basic script for you to use and modify to suit your needs, but for the sake of completeness, here is the very minimum sample of code required to get pinkpill to build your project, assuming your project is set up 'correctly'.

    #!/usr/bin/perl
    use PinkPill;
    $p = new PinkPill;
    $p->build;

How to Help
===========

I am more then willing to except help, so please do feel free to fork and issue pull requests or use the issue tracker to offer suggestions for new features or improvements, or for reporting bugs. If you choose to start using this build system I would love to know about it!

A note on obfuscated Perl: Yes, we all know that Perl can be twisted into some very complex stuff, but for the most part I try avoid doing so. Perl is not my primary language, so I like to keep the code reasonably readable. And no, there are not hard and fast rules I am following for 'reasonably readable'; if I get on a bit of a binge, I might get more comfortable with more inverted forms, but I might later comeback to it and decide to make things a bit more explicate.

The Name
========

When I started this, I had just re-watched a rather famous film involving a blue pill and a red pill (can you guess what film it was) so I had this notion of this project being 'another choice'. Obliviously the pill had to have a colour, and some how tie to Perl, of the top of my head pink is the only colour that starts with the letter 'p'; oh, I also ardously admit an atrocious alliteration addiction amiably appeased about ... a ... project name that alliterates.   
