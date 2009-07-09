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
use WebGUI::Asset::Wobject::Survey;

my $toVersion = '7.7.12';
my $quiet; # this line required


my $session = start(); # this line required

# upgrade functions go here
surveyCleanUp($session);
addUTCMacro($session);

finish($session); # this line required


#----------------------------------------------------------------------------
# Describe what our function does
#sub exampleFunction {
#    my $session = shift;
#    print "\tWe're doing some stuff here that you should know about... " unless $quiet;
#    # and here's our code
#    print "DONE!\n" unless $quiet;
#}

#----------------------------------------------------------------------------
# Describe what our function does
sub addUTCMacro {
    my $session = shift;
    print "\tAdd ConvertUTCToTZ Macro to config files... " unless $quiet;
    # and here's our code
    $session->config->addToHash('macros', 'ConvertUTCToTZ', 'ConvertUTCToTZ' );
    print "DONE!\n" unless $quiet;
}

#----------------------------------------------------------------------------
sub surveyCleanUp {
    my $session = shift;
    print "\tRemoving extra properties that may have crept into surveyJSON... " unless $quiet;
    
    my $sth = $session->db->read('select assetId, revisionDate from Survey');
    
    while (my ($assetId, $revision) = $sth->array) {
        my $survey = WebGUI::Asset->new($session, $assetId, 'WebGUI::Asset::Wobject::Survey', $revision);
        
        # Remove recursive properties that snuck into the mold
        if (my $mold = $survey->surveyJSON->mold) {
            $mold->{question}{answers} = [];
            $mold->{section}{questions} = [];
        }
        
        # Remove keys that should never have been added to sections/questions/answers
        for my $s (@{$survey->surveyJSON->sections}) {
            for my $q (@{$s->{questions} || []}) {
                for my $a (@{$q->{answers} || []}) {
                    delete $a->{$_} for qw(delete copy removetype addtype func);
                }
                delete $q->{$_} for qw(delete copy removetype addtype func);
            }
            delete $s->{$_} for qw(delete copy removetype addtype func);
        }
        $survey->persistSurveyJSON;
    }
    
    print "DONE!\n" unless $quiet;
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
    my $package = eval { WebGUI::Asset->getImportNode($session)->importPackage( $storage ); };

    if ($package eq 'corrupt') {
        die "Corrupt package found in $file.  Stopping upgrade.\n";
    }
    if ($@ || !defined $package) {
        die "Error during package import on $file: $@\nStopping upgrade\n.";
    }

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
