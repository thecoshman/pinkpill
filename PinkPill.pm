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
    $this->negotiate_platform;
    return $this;
}

sub negotiate_platform{
    my $this = shift;
    my %OS_mappings = (
        dos => 'Windows',
        os2 => 'Windows',
        MSWin32 => 'Windows',
        cygwin => 'Windows',
        darwin => 'OSx',
#        aix => 'Linux',
#        bsdos => 'Linux',
#        dgux => 'Linux',
#        dynixptx => 'Linux',
#        freebsd => 'Linux',
#        haiku => 'Linux',
        linux => 'Linux',
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
    print "platform determined to be '$this->current_OS}" if $this->{verbose} eq 'on';
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
    print "Ensureing all expected folders exist...\n" if $this->{verbose} eq 'on';
    push @{$this->{error_messages}}, "Failed to create folders" and return 0
        unless $this->ensure_folders_exist();

    print "Compiling all source files in source folders...\n" if $this->{verbose} eq 'on';
    push @{$this->{error_messages}}, "Failed to compile files" and return 0
        unless $this->compile_files();

    print "Linking project...\n" if $this->{verbose} eq 'on';
    push @{$this->{error_messages}}, "Failed to link program" and return 0
        unless $this->link_program();

    print "Success\n" if $this->{verbose};
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
    print "parsing src_folders string =>\n    $this->{src_folders}\n" if $this->{verbose} eq 'on';
    my $src_folders_to_search = parse_folder_matching_string($this->{src_folders});
    my @files;
    print "=> @{$src_folders_to_search{include}} <=\n";
    foreach (@src_folders_to_search{include}){
        push @files, files_in_folder($_, @{src_folders_to_search{exclude}});
    }    
#    print "parsing inc_folders string =>\n    $this->{inc_folders}\n" if $this->{verbose} eq 'on';
#    my $include_folders;
#    for (parse_folder_matching_string($this->{src_folders})->{include}){
#        $include_folders .= $_ . " ";
#    }
    print "List of all files:\n" and print @files if $this->{verbose} eq 'on';
    # get a list of all files that end in the '.cpp' extension
    my @cpp_files = grep { /\.c[p\+]{2}$/ } @files;
    print @cpp_files;
    for (@cpp_files){
        my $external_command = $this->{compiler} . ' ' . $_ . '-I ' . $include_folders;
        print "Compiling - $_\n    running the command > $external_command\n" if $this->{verbose} eq 'on';
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
    print "folder elements: ", @folder_elements, "";
    my %results = (
        include => [],
        exclude => []
    );
    for (@folder_elements){
        print "looking at $_\n" if $this->{verbose} eq 'on';
        # if this has no meta data, just add it the include list and move on
        unless($_ =~ /\^/){
            print "    including $_\n" if $this->{verbose} eq 'on';
            push @results{include}, $_;
            next;
        }
        my ($meta_data, $folder, $escape_string);
        # these two refex matches should up the last ^ or ~ character, but not capture them
        ($meta_data, $folder) = /(.*)^(.*)/;
        ($meta_data, $escape_string) = $meta_data =~ /(.*)~(.*)^/ and $folder = $escape_string . $folder if $meta_data =~ /~/;
        # These two take the last instance of the match, hence the '.*' at the start of the pattern
        my ($OS) = $meta_data =~ /.*((win|nix|osx))/;
        my ($arch) = $meta_data =~ /.*((x86|x64))/;
        unless($OS eq $this->{current_OS}){
            print "    skipping, this OS is not $OS\n" if $this->{verbose} eq 'on';
            next;
        }
        # next unless $arch eq *this arch*
        my $exclude = $meta_data =~ /!/;
        push @results{exclude}, $folder if $exclude;
        push @results{include}, $folder unless $exclude;
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
# currently a lot of debug stuff being printed that will need to be removed at some stage
sub files_in_folder{
    my $folder = shift;
    print "Generating list of files in '$folder'\n" if $this->{verbose} eq 'on';
    my @exlude = @_;
    opendir FOLDER, $folder;
    my @files;
    while (readdir FOLDER){
        print "$_\n";
        # skip '.' or '..' as these are not true files
        next if /^\.\.?$/;
        print "it's not one of those dotty things\n";
        # if files, add 'folder/file' to the list of files 
        push @files, $folder . '/' . $_ if -f;
        # if folder, get all fiels in that folder, and for each retruned file add 'folder/file' to the list of files
        map { 
            push @files, $folder . '/' . $_; 
        } files_in_folder($_) if -d;
    }
    return @files;
}

sub fancy_header{
    print "# - - - - - - - - - - - - - - - -\n";
    print "# Welcome to the pinkpill build system\n";
    print "# Version $pp_version\n";
    print "# Written by thecoshman\n";
    print "# - - - - - - - - - - - - - - - -\n\n";
}

sub error_logs{
    my $this = shift;
    return @{$this->{error_messages}};
}

1;