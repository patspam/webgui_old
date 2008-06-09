#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

our ($webguiRoot);

BEGIN {
    $webguiRoot = "..";
    unshift (@INC, $webguiRoot."/lib");
}

use strict;
use Getopt::Long;
use WebGUI::Session;
use WebGUI::Storage;
use WebGUI::Asset;


my $toVersion = '7.5.5';
my $quiet; # this line required


my $session = start(); # this line required

# upgrade functions go here
addGalleryEditCommentTemplate( $session );
addGalleryRichEditAlbum( $session );
migrateToGalleryFile( $session );

finish($session); # this line required


##---------------------------------------------------------------------------
#sub exampleFunction {
#	my $session = shift;
#	print "\tWe're doing some stuff here that you should know about.\n" unless ($quiet);
#	# and here's our code
#}

#----------------------------------------------------------------------------
# Add a column to the Gallery
sub addGalleryEditCommentTemplate {
    my $session     = shift;
    print "\tAdding Edit Comment Template... " unless $quiet;

    $session->db->write( q{
        ALTER TABLE Gallery ADD COLUMN templateIdEditComment VARCHAR(22) BINARY
    } );

    print "DONE!\n" unless $quiet;
}

#----------------------------------------------------------------------------
# Add a column to select rich editor for albums
sub addGalleryRichEditAlbum {
    my $session     = shift;
    print "\tAdding Select Rich Editor for Gallery Albums..." unless $quiet;

    $session->db->write( q{
        ALTER TABLE Gallery ADD COLUMN richEditIdAlbum VARCHAR(22) BINARY
    } );
    $session->db->write( q{
        ALTER TABLE Gallery ADD COLUMN richEditIdFile VARCHAR(22) BINARY
    } );

    print "DONE!\n" unless $quiet;
}

#----------------------------------------------------------------------------
# Move File::Image::Photos to File::GalleryFile::Photos
sub migrateToGalleryFile {
    my $session     = shift;
    print "\tMigrating Image::Photos to GalleryFile::Photos (this may take time)..." unless $quiet;

    # Change WebGUI::Asset::File::Image::Photo to WebGUI::Asset::File::GalleryFile::Photo
    $session->db->write( q{
        UPDATE asset SET className='WebGUI::Asset::File::GalleryFile::Photo' WHERE 
        className='WebGUI::Asset::File::Image::Photo'
    });

    # Delete Photos from ImageAsset table
    $session->db->write(
        "DELETE FROM ImageAsset WHERE assetId IN ( SELECT assetId FROM Photo )"
    );

    print "DONE!\n" unless $quiet;
}

# --------------- DO NOT EDIT BELOW THIS LINE --------------------------------

#----------------------------------------------------------------------------
# Add a package to the import node
sub addPackage {
    my $session     = shift;
    my $file        = shift;

    # Make a storage location for the package
    my $storage     = WebGUI::Storage->createTemp( $session );
    $storage->addFileFromFilesystem( $file );

    # Import the package into the import node
    my $package = WebGUI::Asset->getImportNode($session)->importPackage( $storage );

    # Make the package not a package anymore
    $package->update({ isPackage => 0 });
}

#-------------------------------------------------
sub start {
    my $configFile;
    $|=1; #disable output buffering
    GetOptions(
        'configFile=s'=>\$configFile,
        'quiet'=>\$quiet
    );
    my $session = WebGUI::Session->open($webguiRoot,$configFile);
    $session->user({userId=>3});
    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->set({name=>"Upgrade to ".$toVersion});
    $session->db->write("insert into webguiVersion values (".$session->db->quote($toVersion).",'upgrade',".$session->datetime->time().")");
    updateTemplates($session);
    return $session;
}

#-------------------------------------------------
sub finish {
    my $session = shift;
    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->commit;
    $session->close();
}

#-------------------------------------------------
sub updateTemplates {
    my $session = shift;
    return undef unless (-d "packages-".$toVersion);
    print "\tUpdating packages.\n" unless ($quiet);
    opendir(DIR,"packages-".$toVersion);
    my @files = readdir(DIR);
    closedir(DIR);
    my $newFolder = undef;
    foreach my $file (@files) {
        next unless ($file =~ /\.wgpkg$/);
        # Fix the filename to include a path
        $file       = "packages-" . $toVersion . "/" . $file;
        addPackage( $session, $file );
    }
}

