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

## The goal of this test is to test the default view and associated subs

use Scalar::Util qw( blessed );
use WebGUI::Test;
use WebGUI::Session;
use Test::More; 
use Test::Deep;
use WebGUI::Test::Maker::HTML;

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
        groupIdView         => 2,   # Registered Users
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
my @photos;
for my $i ( 0 .. 5 ) {
    $photos[ $i ] 
        = $album->addChild({
            className           => "WebGUI::Asset::File::Image::Photo",
            filename            => "$i.jpg",
        },
        undef,
        undef,
        {
            skipAutoCommitWorkflows => 1,
        });
}

$versionTag->commit;

#----------------------------------------------------------------------------
# Tests
plan tests => 7;

#----------------------------------------------------------------------------
# Test getFileIds and getFilePaginator
cmp_bag( $album->getFileIds, [ map { $_->getId } @photos ] );

my $p   = $album->getFilePaginator;
isa_ok( $p, "WebGUI::Paginator" );
cmp_deeply( $p->getPageData, subbagof( map { $_->getId } @photos ) );

#----------------------------------------------------------------------------
# Test getTemplateVars 

# Is a superset of Asset->get
# NOTE: url is Asset->getUrl
cmp_deeply( $album->getTemplateVars, superhashof( { %{$album->get}, url => $album->getUrl, } ) );

# Contains specific keys/values
my $expected = {
    "url_addPhoto" 
        => all( 
            re( qr/class=WebGUI::Asset::File::Image::Photo/ ), 
            re( qr/func=add/ ),
            re( $album->getUrl ),
        ),
    "url_addNoClass"
        => all(
            re( $album->getUrl ),
            re( qr/func=add$/ ),
        ),
    "url_slideshow"
        => all(
            re( $album->getUrl ),
            re( qr/func=slideshow/ ),
        ),
    "url_thumbnails"
        => all(
            re( $album->getUrl ),
            re( qr/func=thumbnails/ ),
        ),
    "url_viewRss"
        => all(
            re( $album->getUrl ),
            re( qr/func=viewRss/ ),
        ),
    "ownerUsername"
        => WebGUI::User->new($session, 3)->username,
};

cmp_deeply( $album->getTemplateVars, superhashof( $expected ) );

#----------------------------------------------------------------------------
# Test appendTemplateVarsFileLoop
$expected   = {
    "file_loop"     => [ map { $_->getTemplateVars } @photos ],
};

TODO: {
    local $TODO = 'assetSize in the file loop differs between expected and actual';
    cmp_deeply( 
        $album->appendTemplateVarsFileLoop({},$album->getFilePaginator->getPageData), 
        $expected 
    );
}

#----------------------------------------------------------------------------
# Test www_view() for those without permission to view
SKIP: {
    skip "test_privilege doesn't work yet", 1;
    $maker->prepare({
        object          => $album,
        method          => "www_view",
        test_privilege  => "insufficient",
    });
    $maker->run;
}
#----------------------------------------------------------------------------
# Cleanup
END {
    $versionTag->rollback();
}
