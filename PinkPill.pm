#!/usr/bin/perl
package PinkPill;
use File::Path qw(make_path);
use File::Find;
use File::Basename;
use File::Spec::Functions;

# these default values should be private to this class
my %default_config = (
    src_folders => 'code',
    inc_folders => 'code',
    program_name => 'pinkpill_program',
    config_file => 'pinkpill.config',
    build_folder => 'bin',
    obj_folder => 'bin/obj',
    compiler => 'g++',
    verbose => 'on',
    compiler_flags => '',
    stop_on_fail => 'on',
    linker_flags => '',
    link_libraries => '',
    mode => 'executable',
    dep_info => 'dep_info',
);
my $pp_version = '0.6.0';

sub new{
    my $class_name = shift;
    my $obj = {};
    bless $obj, $class_name;
    my %params = @_;
    $obj->Init(%params);
    # allow the name of the config file to be passed into the contructor. 
    $obj->{config_file} = $params{'config_file'} if exists $params{'config_file'};
    return $obj;
}

# In theory, this could be called at any time to reset the class back to default
sub Init {
    my $this = shift;
    for (keys %default_config){
        $this->{$_} = $default_config{$_};
    }
    return $this;
}

sub negotiate_platform{
    my $this = shift;
    my %OS_mappings = (
        dos => 'win',
        os2 => 'win',
        MSWin32 => 'win',
        cygwin => 'win',
        darwin => 'osx',
#        aix => 'Linux',
#        bsdos => 'Linux',
#        dgux => 'Linux',
#        dynixptx => 'Linux',
#        freebsd => 'Linux',
#        haiku => 'Linux',
        linux => 'nix',
#        hpux => 'Linux',
#        irix => 'Linux',
#        next => 'Linux',
#        openbsd => 'Linux',
#        dec_osf => 'Linux',
#        svr4 => 'Linux',
#        unicos => 'Linux',
#        unicosmk => 'Linux',
#        solaris => 'Linux',
#        sunos => 'Linux',
    );
    my %Arch_mappings = (
        'MSWin32-x86' => 'x86',
        'MSWin32-x64' => 'x64',
    );
    exists $OS_mappings{$^O} and $this->{current_OS} = $OS_mappings{$^O} or die
        "$^O is not currently a supported platform. If you think it should or is, please report this.";
    $this->trace("    platform determined to be '$this->{current_OS}'\n");
    return 1;
}

sub load_config_file{
    my $this = shift;
    my $config_file = $this{'config_file'};
    #  If the file cannot be opened to read, we will not worry about, perhaps a config file is not being used
    push @{$this->{'error_messages'}}, "Config file could no be opened" and return $this unless open CONFIG, $config_file;
    while (<CONFIG>){
        next if /^\s*#/;
        my ($key, $value) = split(/\s*=\s*/,$_,2);
        ($value) = $value =~ /([^#]*)/;
        $config_options{$key} = $value;
    }
    return $this;
}

# take a hash of options, for each posible option, copy it's value if it has been set
sub set_options{
    my $this = shift;
    my %params = @_;
    for (keys %default_config){
        $this->{$_} = $params{$_} if exists $params{$_};
    }
    for (keys %params){
        push @{$this->{error_messages}}, "The setting '$_' is not supprted" unless exists $default_config{$_};
    }
    $this->{verbose} = '0' if $this->{verbose} eq 'off';
    return $this;
}

sub build{
    $this = shift;
    fancy_header();
    $this->trace("Determining platform details...\n");
    $this->negotiate_platform();
    $this->trace("\nEnsureing all expected folders exist...\n");
    push @{$this->{error_messages}}, "Failed to create folders" and return 0
        unless $this->ensure_folders_exist();

    $this->trace("\nCompiling all source files in source folders...\n");
    push @{$this->{error_messages}}, "Failed to compile files" and return 0
        unless $this->compile_files();

    if($this->{mode} eq 'executable'){
        $this->trace("\nLinking project...\n");
        push @{$this->{error_messages}}, "Failed to link program" and return 0
            unless $this->link_program();
    } elsif ($this->{mode} eq 'static'){
        $this->trace("\nCreating static library...\n");
        push @{$this->{error_messages}}, "Failed to build library" and return 0
            unless $this->build_static_library();
    } else {
        $this->trace("\nNo post compile process selected ('$this->{mode}')\n");
    }

    $this->trace("\nSuccess!\n\n");
    delete $this->{error_messages};
    return 1;
}

sub ensure_folders_exist{
    my $this = shift;
    push @{$this->{error_messages}}, "Build folder '" . $this->{build_folder} . "' could not be created" and return 0
        unless -d $this->{build_folder} or make_path($this->{build_folder});
    push @{$this->{error_messages}}, "Object folder '" . $this->{obj_folder} . "' could not be created" and return 0
        unless -d $this->{obj_folder} or make_path($this->{obj_folder});
    push @{$this->{error_messages}}, "Dependency information folder '" . $this->{dep_info} . "' could not be created" and return 0
        unless -d $this->{dep_info} or make_path($this->{dep_info});
    return 1;
}

sub compile_files{
    my $this = shift;
    local $, = "\n";
    $this->trace("parsing src_folders string => $this->{src_folders}\n");
    my $src_folders_to_search = parse_folder_matching_string($this->{src_folders});
    my @files;
    $this->trace("including folders: @{$src_folders_to_search->{include}}\n");
    $this->trace("excluding folders: @{$src_folders_to_search->{exclude}}\n\n");
    for (@{$src_folders_to_search->{include}}){
        push @files, files_in_folder($_, @{$src_folders_to_search->{exclude}});
    }    
    $this->trace("\nparsing inc_folders string => $this->{inc_folders}\n");
    my $include_folders = "";
    for (@{parse_folder_matching_string($this->{inc_folders})->{include}}){
        $include_folders .= ' -I ' . $_;
    }
    $this->trace("\nList of all files:", @files, "\n");
    my @cpp_files = grep { /\.c([p\+]{2})?$/ } @files;
    $this->trace("cpp files:", @cpp_files, "\n");
    for (@cpp_files){
        unless ($this->compile($_, $include_folders)){
            push @{$this->{error_messages}}, "Compilation of $_ failed";
            return 0 if $this->{stop_on_fail} eq 'on';
        }
    }
    return 1;
}

# compiles one file to it's .o form
sub compile{
    my $this = shift;
    my $input = shift;
    my $include_folders = shift;
    $this->trace("Skipping '$source', all ready up-to-date\n") and next unless $this->compilation_required($input);
    
    my ($input_file, $input_folder, $input_suffix) = fileparse($input);
    $input_file =~ s/\.c([p\+]{2})?$//;
    my $output_folder = catfile($this->{obj_folder}, $input_folder);
    push @{$this->{error_messages}}, "Object subfolder '$output_folder' could not be created" and return 0
        unless -d $output_folder or make_path($output_folder);
    my $output_file = catfile($output_folder, $input_file) . '.o';
    
    my $dep_info_folder = catfile($this->{dep_info}, $input_folder);
    push @{$this->{error_messages}}, "Dependency information subfolder '$dep_info_folder' could not be created" and return 0
        unless -d $dep_info_folder or make_path($dep_info_folder);
    my $dep_info_file = catfile($dep_info_folder, $input_file) . '.d';

    my $external_command = $this->{compiler} . ' -MMD -MF ' . $dep_info_file;
    $external_command .= ' -c ' . $this->{compiler_flags};
    $external_command .= ' ' . $input . ' -o ' . $output_file;
    $external_command .= $include_folders;
    $this->trace("> " . $external_command . "\n");
    system($external_command);
    my $result = $? >> 8;
    return 0 if $result != 0;
    return 1;
}

# checks if *.cpp needs to be recompiled to *.o
sub compilation_required{
    my $this = shift;
    my $mtime = 9; # It is field nine from 'stat' that contains the modified time for a file
    my $input = shift;
    my $output_file = catfile($this->{obj_folder}, $input);
    $output_file =~  s/\.c([p\+]{2})?$/\.o/;

    my $dep_info_file = catfile($this->{dep_info}, $input);
    $dep_info_file =~ s/\.c([p\+]{2})?$/\.d/;

    my $obj_last_modified = (stat($dep_info_file))[$mtime];
    my $dep_last_modified = (stat($input))[$mtime];
    $this->trace("found a newer file!\n") and return 1 if $obj_last_modified < $dep_last_modified;
    return 1 unless -f $dep_info_file and open DEP, $dep_info_file;
    my $dep = <DEP>; # This first line is output file and the input file, we just checked this
    while(<DEP>){
        $dep = $_;
        $dep =~ s/^\s*//;
        $dep =~ s/\s*\\?\s*$//;
        $dep_last_modified = (stat($dep))[$mtime];
        $this->trace("found a newer file!\n") and return 1 if $dep_last_modified and $obj_last_modified < $dep_last_modified;
        unless ($dep_last_modified) {
            $this->trace("  timestamp was not found, closer look at '$dep'\n");
            for(split " ", $dep){
                $dep_last_modified = (stat($_))[$mtime];
                $this->trace("found a newer file!\n") and return 1 if $dep_last_modified and $obj_last_modified < $dep_last_modified;
            }
        }
    }
    return 0;
}

sub link_program{
    my $this  = shift;
    my @object_files = $this->find_object_files();
    my $external_command = $this->{compiler} . ' ' . $this->{linker_flags};
    for(@object_files){
        $external_command .= ' ' . $_;
    }
    my @libraries = split " ", $this->{link_libraries};
    for(@libraries){
        $external_command .= " -l" . $_;
    }
    $external_command .= ' -o ' . $this->{program_name};
    $this->trace("> $external_command\n");
    system($external_command);
    my $result = $? >> 8;
    return 0 if $result != 0;
    return 1;
}

sub build_static_library{
    my $this = shift;
    my @object_files = $this->find_object_files();
    my $external_command = 'ar rcs ' . $this->{build_folder} . '/';
    $external_command .= 'lib' . $this->{program_name} . '.a';
    for(@object_files){
        $external_command .= ' ' . $_;
    }
    $this->trace("> $external_command\n");
    system($external_command);
    return 1;
}

sub find_object_files{
    my $this = shift;
    my @object_files = ();
    find(sub { push(@object_files, $File::Find::name) if $_ =~ /\.o$/; }, $this->{obj_folder});
    return @object_files;
}

sub parse_folder_matching_string{
    my $folder_match_string = $_[0];
    # use the fucnky AWK like feature of split
    my @folder_elements = split " ", $folder_match_string;
    my %results = (
        include => [],
        exclude => []
    );
    for (@folder_elements){
        $this->trace("  examing token '$_'\n");
        unless($_ =~ /\^/){
            # this has no meta data, just add it the include list and move on
            $this->trace("    basic token, including '$_'\n");
            push @{$results{include}}, $_;
            next;
        }
        my ($meta_data, $folder, $escape_string);
        # these two refex matches should up the last ^ or ~ character, but not capture them
        ($meta_data, $folder) = /(.*)\^(.*)/;
        $this->trace("    meta data is '$meta_data'\n");
        ($meta_data, $escape_string) = $meta_data =~ /(.*)~(.*)^/ and $folder = $escape_string . $folder if $meta_data =~ /~/;
        # These two take the last instance of the match, hence the '.*' at the start of the pattern
        if($meta_data =~ /(win|nix|osx)/){
            $this->trace("    OS conditional\n");
            my ($OS) = $meta_data =~ /.*((win|nix|osx))/;
            unless($OS eq $this->{current_OS}){
                $this->trace("    skipping, this OS is not '$OS'\n");
                next;
            }
        }
        # my ($arch) = $meta_data =~ /.*((x86|x64))/;
        $this->trace("    x86/x64 conditionals not yet supported\n");
        if($meta_data =~ /!/){
            $this->trace("    excluding '$folder'\n");
            push @results{exclude}, $folder;
        } else {
            $this->trace("    including '$folder'\n");
            push @results{include}, $folder;
        }
    }
    return \%results;
}

# Can be used to get the list of options that can be set
sub config_options{
    my $this = shift;
    # if called in static context, just return the options you can set
    return sort keys %default_config unless ref $this;
    my @options;
    # return the options that CAN be set, this avoids returning options that are not supposed to be set by the user
    for (sort keys %default_config){
        push @options, "$_=$this->{$_}";
    }
    return @options;
}

# This is not intended to be a class/instance function, it is to be used as just a free function
sub files_in_folder{
    my $folder = shift;
    my @excludes = @_;
    $this->trace("Generating list of files in '$folder'\n");
    if (-f $folder){
        $this->trace("  this is a file, I assume you want it compiled\n");
        return ($folder);
    }
    
    opendir FOLDER, $folder or $this->trace("  failed to open '$folder'\n");
    my @files;
    FILELOOP: while (readdir FOLDER){
        $this->trace("  $_ (meta folder) - skipping\n") and next if /^\.\.?$/;
        $this->trace("  $_\n");
        my $listing = $folder . '/' . $_;

        for $exclude (@excludes){
            #$this->trace("Cheacking '$_' for exclusion against '$exclude_folder'\n");
            next FILELOOP if $listing eq $exclude;
        }
        # if files, add 'folder/file' to the list of files 
        push @files, $listing if -f $listing;
        # if folder, get all fiels in that folder, and for each retruned file add 'folder/file' to the list of files
        push @files, files_in_folder($listing, \@excludes) if -d $listing;
    }
    #$this->trace("  About to return file list: ", @files, "\n");
    return @files;
}

sub fancy_header{
    $this->trace("# - - - - - - - - - - - - - - - -\n");
    $this->trace("# Welcome to the pinkpill build system\n");
    $this->trace("# Version $pp_version\n");
    $this->trace("# Written by thecoshman\n");
    $this->trace("# - - - - - - - - - - - - - - - -\n\n");
}

sub error_logs{
    my $this = shift;
    return @{$this->{error_messages}};
}

sub trace{
  my $this = shift;
  my @messages = @_;
  print @messages if $this->{verbose} eq 'on';
  # Could possibly add support for other forms logging, like to file...
}

1;
