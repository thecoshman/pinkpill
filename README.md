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

Status
======
Right now, this build system is in a very primitive shape. Technically it can be used to build your project, but it is not really in a position to be realistically considered. It is currently able to build your program, but in a very limited way, with a lot of features that you would expect lacking.

Version 1.0.0 - Saw pinkpill reach a 'it can build an executable' milestone, the point at which you could in a crude way say that it actually works.

Version 2.0.0 - Will hopefully see dependency management fully realised. Currently individual files are compiled with 'proper' dependency management, but not the link process. This release will probably mark the point at which I consider pinkpill viable, but by no means done. Hopefully incremental builds will be 'super fast' once this is done.

Version 3.0.0 - This will probably be the introduction of a threading system for compilation. I plan to split the compilation of files into many threads with the hopes of facilitating faster builds. 

Version 4.0.0 - I will probably look at a better way of linking different build steps together. I already have projects that use sub projects, so it would be nice to come up with a good way for this builds to interact with each other.

Version 5.0.0 - Hair brain ideas now! This might introduce distributed compilation, though I doubt there will be much benefit to this, but it is an idea at least. 

How to Help
===========
I am more then willing to except help, so please do feel free to fork and issue pull requests or use the issue tracker to offer suggestions for new features or improvements, or for reporting bugs. If you choose to start using this build system I would love to know about it!

A note on obfuscated Perl: Yes, we all know that Perl can be twisted into some very complex stuff, but for the most part I try avoid doing so. Perl is not my primary language, so I like to keep the code reasonably readable. And no, there are not hard and fast rules I am following for 'reasonably readable'; if I get on a bit of a binge, I might get more comfortable with more inverted forms, but I might later comeback to it and decide to make things a bit more explicate.

The Name
========
When I started this, I had just re-watched a rather famous film involving a blue pill and a red pill (can you guess what film it was) so I had this notion of this project being 'another choice'. Obliviously the pill had to have a colour, and some how tie to Perl, of the top of my head pink is the only colour that starts with the letter 'p'; oh, I also arduously admit an atrocious alliteration addiction amiably appeased about ... a ... project name that alliterates.   
