#!/usr/bin/env perl

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

our ($webguiRoot);

BEGIN {
    $webguiRoot = "../..";
    unshift (@INC, $webguiRoot."/lib");
}

use strict;
use Getopt::Long;
use WebGUI::Session;
use WebGUI::Storage;
use WebGUI::Asset;
use WebGUI::FilePump::Bundle;

my $toVersion = '7.7.7';
my $quiet; # this line required

my $session = start(); # this line required

addOgoneToConfig( $session );
addUseEmailAsUsernameToSettings( $session );
alterVATNumberTable( $session );
addRedirectAfterLoginUrlToSettings( $session );
addSurveyTestResultsTemplateColumn( $session );
fixSMSUserProfileI18N($session);
addMapAsset( $session );
installFilePumpHandler($session);
installFilePumpTable($session);
installFilePumpAdminGroup($session);

finish($session); # this line required


#----------------------------------------------------------------------------
sub fixSMSUserProfileI18N {
    my $session = shift;
    print "\tFixing bad I18N in SMS user profile fields..." unless $quiet;
    my $field = WebGUI::ProfileField->new($session, 'receiveInboxEmailNotifications');
    my $properties = $field->get();
    $properties->{label} = q!WebGUI::International::get('receive inbox emails','WebGUI')!;
    $field->set($properties);

    $field = WebGUI::ProfileField->new($session, 'receiveInboxSmsNotifications');
    $properties = $field->get();
    $properties->{label} = q!WebGUI::International::get('receive inbox sms','WebGUI')!;
    $field->set($properties);

    print "Done\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub addOgoneToConfig {
    my $session = shift;
    print "\tAdding Ogone payment plugin..." unless $quiet;

    $session->config->addToArray('paymentDrivers', 'WebGUI::Shop::PayDriver::Ogone');
    
    print "Done\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub addUseEmailAsUsernameToSettings {
    my $session = shift;
    print "\tAdding webguiUseEmailAsUsername to settings \n" unless $quiet;

    $session->db->write("insert into settings (name, value) values ('webguiUseEmailAsUsername',0)");

    print "Done.\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub addRedirectAfterLoginUrlToSettings {
    my $session = shift;
    print "\tAdding redirectAfterLoginUrl to settings \n" unless $quiet;

    $session->db->write("insert into settings (name, value) values ('redirectAfterLoginUrl',NULL)");

    print "Done.\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub alterVATNumberTable {
    my $session = shift;
    print "\tAdapting VAT Number table..." unless $quiet;

    $session->db->write('alter table tax_eu_vatNumbers change column approved viesValidated tinyint(1)');
    $session->db->write('alter table tax_eu_vatNumbers add column approved tinyint(1)');

    print "Done\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub addSurveyTestResultsTemplateColumn {
    my $session = shift;
    print "\tAdding columns for Survey Test Results Template..." unless $quiet;
    $session->db->write("alter table Survey add column `testResultsTemplateId` char(22)");

    print "Done\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub installFilePumpAdminGroup {
    my $session = shift;
    print "\tAdding FilePump admin group setting... \n" unless $quiet;
    ##Content Handler
    #if (! $session->setting->has('groupIdAdminFilePump')) {
        $session->setting->add('groupIdAdminFilePump','8');
        print "\tAdded FilePump admin group ... \n" unless $quiet;
    #}
    print "Done.\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub installFilePumpHandler {
    my $session = shift;
    print "\tAdding FilePump content handler... \n" unless $quiet;
    ##Content Handler
    my $contentHandlers = $session->config->get('contentHandlers');
    $session->config->addToArray('contentHandlers', 'WebGUI::Content::FilePump');
    $session->config->addToHash( 'macros',          { FilePump => 'FilePump' });

    ##Admin Console
    $session->config->addToHash('adminConsole', 'filePump', {
      "icon" => "filePump.png",
      "groupSetting" => "groupIdAdminFilePump",
      "uiLevel" => 5,
      "url" => "^PageUrl(\"\",op=filePump);",
      "title" => "^International(File Pump,FilePump);"
    });
    ##Setting for custom group
    print "Done.\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub installFilePumpTable {
    my $session = shift;
    print "\tAdding FilePump database table via CRUD... \n" unless $quiet;
    WebGUI::FilePump::Bundle->crud_createTable($session);
    print "Done.\n" unless $quiet;
}


#----------------------------------------------------------------------------
# Add the map asset
sub addMapAsset {
    my $session = shift;
    print "\tAdding Google Map asset..." unless $quiet;
    
    # Map asset
    $session->db->write(<<'ENDSQL');
CREATE TABLE IF NOT EXISTS Map (
    assetId CHAR(22) BINARY NOT NULL,
    revisionDate BIGINT NOT NULL,
    groupIdAddPoint CHAR(22) BINARY,
    mapApiKey TEXT,
    mapHeight CHAR(12),
    mapWidth CHAR(12),
    startLatitude FLOAT,
    startLongitude FLOAT,
    startZoom TINYINT UNSIGNED,
    templateIdEditPoint CHAR(22) BINARY,
    templateIdView CHAR(22) BINARY,
    templateIdViewPoint CHAR(22) BINARY,
    workflowIdPoint CHAR(22) BINARY,
    PRIMARY KEY (assetId, revisionDate)
);
ENDSQL

    # MapPoint asset
    $session->db->write(<<'ENDSQL');
CREATE TABLE IF NOT EXISTS MapPoint (
    assetId CHAR(22) BINARY NOT NULL,
    revisionDate BIGINT NOT NULL,
    latitude FLOAT,
    longitude FLOAT,
    website VARCHAR(255),
    address1 VARCHAR(255),
    address2 VARCHAR(255),
    city VARCHAR(255),
    state VARCHAR(255),
    zipCode VARCHAR(255),
    country VARCHAR(255),
    phone VARCHAR(255),
    fax VARCHAR(255),
    email VARCHAR(255),
    storageIdPhoto CHAR(22) BINARY,
    userDefined1 TEXT,
    userDefined2 TEXT,
    userDefined3 TEXT,
    userDefined4 TEXT,
    userDefined5 TEXT,
    PRIMARY KEY (assetId, revisionDate)
);
ENDSQL

    # Add to assets
    $session->config->addToHash( "assets", 'WebGUI::Asset::Wobject::Map', {
       "category" => "basic",
    });

    print "Done!\n" unless $quiet;
}

# -------------- DO NOT EDIT BELOW THIS LINE --------------------------------

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

    # Turn off the package flag, and set the default flag for templates added
    my $assetIds = $package->getLineage( ['self','descendants'] );
    for my $assetId ( @{ $assetIds } ) {
        my $asset   = WebGUI::Asset->newByDynamicClass( $session, $assetId );
        if ( !$asset ) {
            print "Couldn't instantiate asset with ID '$assetId'. Please check package '$file' for corruption.\n";
            next;
        }
        my $properties = { isPackage => 0 };
        if ($asset->isa('WebGUI::Asset::Template')) {
            $properties->{isDefault} = 1;
        }
        $asset->update( $properties );
    }

    return;
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
    return $session;
}

#-------------------------------------------------
sub finish {
    my $session = shift;
    updateTemplates($session);
    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->commit;
    $session->db->write("insert into webguiVersion values (".$session->db->quote($toVersion).",'upgrade',".$session->datetime->time().")");
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

#vim:ft=perl
