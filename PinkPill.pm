#!/usr/bin/perl
package PinkPill;

# these default values should be private to this class
my %default_config = (
    src_folder => '.',
    inc_folder => '.',
    program_name => 'pinkpill_program',
    config_file => 'pinkpill.config',
    build_folder => 'bin',
    build_folder => 'bin/obj',
    compiler => 'gcc',
    verbose => 'on',
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
    $this->{verbose} = '0' if $this->{verbose} eq 'off';
    return $this;
}

sub build{
    $this = shift;
    fancy_header();
    print "Ensureing all expected folders exist...\n" if $this->{verbose} eq 'on';
    push @{$this->{error_messages}}, "Failed to create folders" and return 0
        unless $this->ensure_folders_exist();

    print "Compiling all source files in source folder...\n" if $this->{verbose} eq 'on';
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
    push @{$this->{error_messages}}, "Source folder '" . $this->{src_folder} . "' not found" and return 0
        unless -d $this->{src_folder};
    push @{$this->{error_messages}}, "Include folder '" . $this->{inc_folder} . "' not found" and return 0
        unless -d $this->{inc_folder};
    mkdir $this->{build_folder} unless -d $this->{build_folder};
    mkdir $this->{obj_folder} unless -d $this->{obj_folder};
    return 1;
}

# takes a list of files to compile
sub compile_files{
    my $this = shift;
    local $, = "\n";
    my @files = files_in_folder($this->{src_folder});
    print "List of all files:\n" if $this->{verbose} eq 'on';
    print @files;
    # get a list of all files that end in the '.cpp' extension
    my @cpp_files = grep { /\.c[p\+]{2}$/ } @files;
    print @cpp_files;
    for (@cpp_files){
        print "Compiling - $_" if $this->{verbose} eq 'on';
        my $external_command = $this->{compiler} . ' ' . $_ . '-I ' . $this->{inc_folder};
    }

    push @{$this->{error_messages}}, "Compilation process is still WIP";
    return 0;
}

sub link_program{
    my $this  = shift;
    print "link_program\nThis is a stub\nThis function still needs to be fleshed out\n";
    return 0;
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

# This is no intended to be a class/instance function, it is to be used as just a free function
sub files_in_folder{
    my $folder = shift;
    print "Generating list of files in '$folder'\n" if $this->{verbose} eq 'on';
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