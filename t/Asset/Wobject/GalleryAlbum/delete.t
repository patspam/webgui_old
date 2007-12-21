# $vim: syntax=perl
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
use lib "$FindBin::Bin/../../../lib";

## The goal of this test is to test the deleting of GalleryAlbums

use Scalar::Util qw( blessed );
use WebGUI::Test;
use WebGUI::Test::Maker::HTML;
use WebGUI::Session;
use Test::More; 

#----------------------------------------------------------------------------
# Init
my $maker           = WebGUI::Test::Maker::HTML->new;
my $session         = WebGUI::Test->session;
my $node            = WebGUI::Asset->getImportNode($session);
my $versionTag      = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Album Test"});
my $gallery
    = $node->addChild({
        className           => "WebGUI::Asset::Wobject::Gallery",
        groupIdAddComment   => 2,   # Registered Users
        groupIdAddFile      => 2,   # Registered Users
        groupIdView         => 7,   # Everyone
        groupIdEdit         => 3,   # Admins
        ownerUserId         => 3,   # Admin
    });
my $album
    = $gallery->addChild({
        className           => "WebGUI::Asset::Wobject::GalleryAlbum",
        ownerUserId         => "3", # Admin
    },
    undef,
    undef,
    {
        skipAutoCommitWorkflows => 1,
    });

$versionTag->commit;

#----------------------------------------------------------------------------
# Tests
plan tests => 5;

SKIP: {

    skip "test_permission is not working yet", 2;
    #----------------------------------------------------------------------------
    # Delete page gives error for those who can't edit the GalleryAlbum
    $maker->prepare({
        object          => $album,
        method          => "www_delete",
        test_privilege  => "insufficient",
        userId          => 1,
    }, {
        object          => $album, 
        method          => "www_deleteConfirm",
        test_privilege  => "insufficient",
        userId          => 1,
    });
    $maker->run;

}

#----------------------------------------------------------------------------
# Delete confirm page appears for those allowed to edit the GalleryAlbum
$maker->prepare({
    object          => $album, 
    method          => "www_delete",
    test_regex      => [ qr/func=deleteConfirm/, ],
    userId          => 3,
});
$maker->run;

#----------------------------------------------------------------------------
# www_deleteConfirm deletes the asset
my $assetId     = $album->getId;
$maker->prepare({
    object          => $album,
    method          => "www_deleteConfirm",
    test_regex      => [ qr/has been deleted/, ],
    userId          => 3,
});
$maker->run;

is(
    WebGUI::Asset->newByDynamicClass( $session, $assetId ),
    undef,
    "GalleryAlbum cannot be instanciated after www_deleteConfirm",
);


#----------------------------------------------------------------------------
# Cleanup
END {
    $versionTag->rollback();
}
