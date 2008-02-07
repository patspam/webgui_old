#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
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
use Test::Deep;
use WebGUI::Asset::File::Image::Photo;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;
my $node            = WebGUI::Asset->getImportNode($session);
my $versionTag      = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Photo Test"});
my $gallery
    = $node->addChild({
        className           => "WebGUI::Asset::Wobject::Gallery",
        imageResolutions    => "1024x768",
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
my $photo
    = $album->addChild({
        className           => "WebGUI::Asset::File::Image::Photo",
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });
$versionTag->commit;

#----------------------------------------------------------------------------
# Tests
plan tests => 2;

#----------------------------------------------------------------------------
# setFile also makes download versions
$photo->setFile( WebGUI::Test->getTestCollateralPath('page_title.jpg') );
my $storage = $photo->getStorageLocation;

cmp_deeply(
    $storage->getFiles, bag('page_title.jpg','1024x768.jpg'),
    "Storage location contains the resolution file",
);

ok(
    -e $storage->getPath($gallery->get('imageResolutions') . '.jpg'),
    "Generated resolution file exists on the filesystem",
);


#----------------------------------------------------------------------------
# Cleanup
END {
    $versionTag->rollback();
}

