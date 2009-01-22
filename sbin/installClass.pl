#!/usr/bin/env perl


#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use lib "../lib";
use strict;
use Getopt::Long;
use Pod::Usage;
use WebGUI::Pluggable;
use WebGUI::Session;

$|++;

# Get options
my ( $configFile, $remove, $check, $upgrade, $help, $man );
GetOptions(
    'configFile=s' => \$configFile,
    'remove'       => \$remove,
    'check'        => \$check,
    'upgrade'      => \$upgrade,
    'help'         => \$help,
    'man'          => \$man,
);

# Get arguments
my $class = $ARGV[0];

pod2usage( -verbose => 1 )
    if $help;

pod2usage( -verbose => 2 )
    if $man;

pod2usage("$0: Must specify a configFile")
    if !$configFile;

die "Config file '$configFile' does not exist!\n"
    if !-f '../etc/' . $configFile;

# Open the session
my $session = WebGUI::Session->open( "..", $configFile );
$session->user( { userId => 3 } );

# Install or uninstall the asset
WebGUI::Pluggable::load($class);
if ($check) {
    if ( $class->isInstalled($session) ) {
        print "$class is installed!\n";
    }
    else {
        print "$class is NOT installed!\n";
    }
}
elsif ($remove) {
    print "Removing $class... ";
    if ( !$class->isInstalled($session) ) {
        die "Can't remove $class because: Not installed\n";
    }
    $class->uninstall($session);
    print "DONE!\n";
    print "Please restart Apache.\n";
}
elsif ( $upgrade || $class->isInstalled($session) ) {
    print "Upgrading $class... ";
    $class->upgrade($session);
    print "DONE!\n";
    print "Please restart Apache.\n";
}
else {
    print "Installing $class... ";
    $class->install($session);
    print "DONE!\n";
    print "Please restart Apache.\n";
}

# End the session
$session->var->end;
$session->close;

__END__

=head1 NAME

installClass.pl -- Run class install methods

=head1 SYNOPSIS

 installAsset.pl [--remove|--check|--upgrade] <class> --configFile=<configFile>

=head1 DESCRIPTION

This helper script installs a class that is using the correct interface. 

If your class has not told you to use this script, then it probably won't work!

=head1 ARGUMENTS

=over 4

=item class

The class name of the class to install. Something like WebGUI::Asset::Yourasset

=back

=head1 OPTIONS

=over 4

=item check

If specified, will check if the class is installed or not.

=item upgrade

If specified, will upgrade the class.

=item remove

If specified, will uninstall the class. 

=item configFile 

The configuration file for the site to install the class into

=back

=head1 SEE ALSO

WebGUI::AssetAspect::Installable
