#!/usr/bin/perl
package PinkPill;

# these default values should be private to this class
my %default_config = {
    src_folder => '.',
    program_name => 'pinkpill_program',
    config_file => 'pinkpill.config',
    object_folder => 'objects',
    compiler => 'gcc',
};
my $pp_version = '0.0.1';

sub new{
    my $class_name = shift;
    my $obj = {};
    bless %obj, $class_name;
    my %params = @_;
    $obj->Init(%params);
    # allow the name of the config file to be passed into the contructor. 
    $obj->{config_file} = $params{'config_file'} if exists $params{'config_file'};
    return $obj;
}

# In theory, this could be called at any time to reset the class back to default
sub Init {
    my $this = shift;
    my %params = @_;
    # copy the default values into this object
    @this->{keys %dafault_config} = values %default_config;
    return $this;
}


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
sub set_option{
    my $this = shift;
    my %params = @_;
    for (config_options){
        $this->{$_} = $params{$_} if exists $params{$_};
    }
    return $this;
}

sub build{
    $this = shift;
    fancy_header();
    push @{$this->{'error_messages'}}, "Failed to create folders" and return 0
        unless $this->ensure_folders_exist();

    push @{$this->{'error_messages'}}, "faied to compile files!" and return 0
        unless $this->compile_files();

    push @{$this->{'error_messages'}}, "faied to link!" and return 0
        unless $this->link_program();

    delete $this->{'error_messages'};
    return 1;
}

sub ensure_folders_exist{
    my $this = shift;
    mkdir $this->{'object_folder'} unless -d $this->{'object_folder'};
    return 1;
}

# takes a list of files to compile
sub compile_files{
    my $this = shift;
    my @files = files_in_folder($this->{'src_folder'});
    # get a list of all files that end in the '.cpp' extension
    my @cpp_files = grep { /\.cpp$/ } @files;

    #(files_in_folder($this->{'src_folder'})_;
    return 0;
}

sub link_program{
    my $this  = shift;
    print "link_program\nThis is a stub\nThis function still needs to be fleshed out\n";
    return 0;
}
# Can be used to get the list of options that can be set
sub config_options{
    return keys %default_config;
}

# This is no intended to be a class/instance function, it is to be used as just a free function
sub files_in_folder{
    my $folder = shift;
    opendir FOLDER, $folder;
    my @files;
    while (readdir FOLDER){
        # skip '.' or '..' as these are not true files
        next if /^\.\.?$/;
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
    print "# - - - - - - - - - - - - - - - -\n";
}

1;