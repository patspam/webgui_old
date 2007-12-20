#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2007 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use FindBin;
use strict;
use lib "$FindBin::Bin/../../../../lib";

## The goal of this test is to test the creation and deletion of photo assets

use Scalar::Util qw( blessed );
use WebGUI::Test;
use WebGUI::Session;
use Test::More; 

#----------------------------------------------------------------------------
# Init
my $session    = WebGUI::Test->session;
my $node       = WebGUI::Asset->getImportNode($session);
my $versionTag = WebGUI::VersionTag->getWorking($session);

$versionTag->set({name=>"Photo Test"});

my $gallery
    = $node->addChild({
        className           => "WebGUI::Asset::Wobject::Gallery",
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });
my $album
    = $gallery->addChild({
        className           => "WebGUI::Asset::Wobject::GalleryAlbum",
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });
my $photo;

#----------------------------------------------------------------------------
# Tests
plan tests => 5;

#----------------------------------------------------------------------------
# Test module compiles okay
# plan tests => 1
use_ok("WebGUI::Asset::File::Image::Photo");

#----------------------------------------------------------------------------
# Test creating a photo
$photo
    = $album->addChild({
        className           => "WebGUI::Asset::File::Image::Photo",
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });

$versionTag->commit;

is(
    blessed $photo, "WebGUI::Asset::File::Image::Photo",
    "Photo is a WebGUI::Asset::File::Image::Photo object",
);

isa_ok( 
    $photo, "WebGUI::Asset::File::Image",
);


is(
    blessed $photo->getGallery, "WebGUI::Asset::Wobject::Gallery",
    "Photo->getGallery gets the gallery containing this photo",
);

#----------------------------------------------------------------------------
# Test deleting a photo
my $properties  = $photo->get;
$photo->purge;

is(
    WebGUI::Asset->newByDynamicClass($session, $properties->{assetId}), undef,
    "Photo no longer able to be instanciated",
);

#----------------------------------------------------------------------------
# Cleanup
END {
    $versionTag->rollback;
}


