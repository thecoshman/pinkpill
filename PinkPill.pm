#!/usr/bin/perl
package PinkPill;
use File::Path qw(make_path);

# these default values should be private to this class
my %default_config = (
    src_folders => '',
    inc_folders => '',
    program_name => 'pinkpill_program',
    config_file => 'pinkpill.config',
    build_folder => 'bin',
    obj_folder => 'bin/obj',
    compiler => 'gcc',
    verbose => 'on',
    compiler_flags => '',
);
my $pp_version = '0.0.1';

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
    # my %params = @_;
    # copy the default values into this object
    #@this->{keys %default_config} = values %default_config;
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

# allows user to pass in the config file to load, or just use the default one
sub loadConfigFile{
    my $this = shift;
    # Currently not using any paramaters
    # my %params = @_;
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
    $this->trace("Ensureing all expected folders exist...\n");
    push @{$this->{error_messages}}, "Failed to create folders" and return 0
        unless $this->ensure_folders_exist();

    $this->trace("Compiling all source files in source folders...\n");
    push @{$this->{error_messages}}, "Failed to compile files" and return 0
        unless $this->compile_files();

    $this->trace("Linking project...\n");
    push @{$this->{error_messages}}, "Failed to link program" and return 0
        unless $this->link_program();

    $this->trace("Success\n!");
    delete $this->{error_messages};
    return 1;
}

sub ensure_folders_exist{
    my $this = shift;
    push @{$this->{error_messages}}, "Build folder '" . $this->{build_folder} . "' could not be created" and return 0
        unless -d $this->{build_folder} or make_path($this->{build_folder});
    push @{$this->{error_messages}}, "Object folder '" . $this->{obj_folder} . "' could not be created" and return 0
        unless -d $this->{obj_folder} or make_path($this->{obj_folder});
    return 1;
}

# takes a list of files to compile
sub compile_files{
    my $this = shift;
    local $, = "\n";
    $this->trace("parsing src_folders string =>\n");
    $this->trace("    $this->{src_folders}\n");
    my $src_folders_to_search = parse_folder_matching_string($this->{src_folders});
    my @files;
    $this->trace("\nincluding: @{$src_folders_to_search->{include}}\n");
    $this->trace("excluding: @{$src_folders_to_search->{exclude}}\n\n");
    for (@{$src_folders_to_search->{include}}){
        push @files, files_in_folder($_, @{$src_folders_to_search->{exclude}});
    }    
#    print "parsing inc_folders string =>\n    $this->{inc_folders}\n" if $this->{verbose} eq 'on';
#    my $include_folders;
#    for (parse_folder_matching_string($this->{src_folders})->{include}){
#        $include_folders .= $_ . " ";
#    }
    $this->trace("List of all files:", @files);
    # get a list of all files that end in the '.cpp' extension
    my @cpp_files = grep { /\.c[p\+]{2}$/ } @files;
    $this->trace(@cpp_files);
    for (@cpp_files){
        my $external_command = $this->{compiler} . ' ' . $_ . '-I ' . $include_folders;
        $this->trace("Compiling - $_\n");
        $this->trace("    running the command > $external_command\n");
    }
    push @{$this->{error_messages}}, "Compilation process is still WIP";
    return 0;
}

sub link_program{
    my $this  = shift;
    print "link_program\nThis is a stub\nThis function still needs to be fleshed out\n";
    return 0;
}

sub parse_folder_matching_string{
    my $folder_match_string = $_[0];
    # use the fucnky AWK like feature of split
    my @folder_elements = split " ", $folder_match_string;
    $this->trace("folder elements: ", @folder_elements, "\n");
    my %results = (
        include => [],
        exclude => []
    );
    for (@folder_elements){
        $this->trace("parsing '$_'\n");
        unless($_ =~ /\^/){
            # this has no meta data, just add it the include list and move on
            $this->trace("    simple folder, including '$_'\n");
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
            $this->trace("    OS conditioal\n");
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
    my @exclude = @_;
    $this->trace("Generating list of files in '$folder'\n");
    opendir FOLDER, $folder;
    my @files;
    my $file;
    FILELOOP: while (readdir FOLDER){
        $this->trace("  $_ (meta folder) - skipping\n") and next if /^\.\.?$/;
        $this->trace("  $_\n");

        for $exclude_folder (@exclude){
            #$this->trace("Cheacking '$_' for exclusion against '$exclude_folder'\n");
            next FILELOOP if $_ eq $exclude_folder;
        }
        # if files, add 'folder/file' to the list of files 
        $file = $folder . '/' . $_;
        push @files, $file if -f $file;
        # if folder, get all fiels in that folder, and for each retruned file add 'folder/file' to the list of files
        map { 
            $file = $folder . '/' . $_;
            push @files, $file; 
        } files_in_folder($_, \@exclude) if -d;
    }
    #$this->trace("About to return file list: ", @files, "\n");
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