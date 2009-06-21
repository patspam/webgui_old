#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use FindBin;
use strict;
use File::Spec;
use lib "$FindBin::Bin/../../lib";

##The goal of this test is to test the creation of UserList Wobjects.

use WebGUI::Test;
use WebGUI::Session;
use Test::More tests => 21; # increment this value for each test you create
use Test::Deep;
use JSON;
use WebGUI::Asset::Wobject::Matrix;

my $session = WebGUI::Test->session;

# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Matrix Test"});
my $matrix = $node->addChild({className=>'WebGUI::Asset::Wobject::Matrix'});

# Test for a sane object type
isa_ok($matrix, 'WebGUI::Asset::Wobject::Matrix');

# Test to see if we can set new values
my $newMatrixSettings = {
	maxComparisons                  => 20,
	defaultSort                     => 'lineage',
	compareColorNo                  => '#aaffaa',
	submissionApprovalWorkflowId    => 'pbworkflow000000000005',
    categories                      => "category1\ncategory2",
    statisticsCacheTimeout          => 7200,
};
$matrix->update($newMatrixSettings);

foreach my $newSetting (keys %{$newMatrixSettings}) {
    unless ($newSetting eq 'categories'){
    	is ($matrix->get($newSetting), $newMatrixSettings->{$newSetting}, "updated $newSetting is ".$newMatrixSettings->{$newSetting});
    }
}

is ($matrix->getCompareColor('4'),'#aaffaa',"Getting compareColorYes");

cmp_deeply (
    $matrix->getCategories,
    {
        category1=>'category1',
        category2=>'category2'
    },
    'getCategories method returned correct hashref'
    );


# add a new attribute

$session->user({userId => 3});

my $attributeProperties = {
    name        =>'test attribute',
    description =>'description of the test attribute',
    category    =>'category1',
    };

my $newAttributeId = $matrix->editAttributeSave($attributeProperties);

my $newAttribute = $matrix->getAttribute($newAttributeId);

my $isValidId = $session->id->valid($newAttributeId);

is($isValidId,1,"editAttributeSave returnes a valid guid");

is($newAttribute->{name},'test attribute',"Adding a new attribute, attribute name was set correctly");
is($newAttribute->{fieldType},'MatrixCompare',"Adding a new attribute, undefined fieldType was set correctly to default value");

# delete new attribute

$matrix->deleteAttribute($newAttributeId);

my $newAttribute = $matrix->getAttribute($newAttributeId);

is($newAttribute->{attributeId},undef,"The new attribute was successfully deleted.");

# TODO: test deleting of listing data for attribute

# add a listing

my $matrixListing = $matrix->addChild({className=>'WebGUI::Asset::MatrixListing'});

my $secondVersionTag = WebGUI::VersionTag->new($session,$matrixListing->get("tagId"));
$secondVersionTag->commit;

# Test for sane object type
isa_ok($matrixListing, 'WebGUI::Asset::MatrixListing');

is($matrixListing->getAutoCommitWorkflowId,undef,"The matrix listings getAutoCommitWorkflowId method correctly returns undef, because the auto commit workflow should only be used on adding a new matrix listing.");

is($matrixListing->hasRated,'0',"The matrix listings hasRated method returns correct value.");

$matrixListing->www_click;

is($matrixListing->get('clicks'),'1','Clicks were incremented');

$matrixListing->www_view;

is($matrixListing->get('views'),'1','Views were incremented');

# Test getListings

my $expectedAssetId = $matrixListing->getId;

my $listings = $matrix->getListings;

cmp_deeply(
        $listings,
        [{
            views=>"1",
            lastUpdated=>$matrixListing->get('lastUpdated'),
            clicks=>"1",
            compares=>"0",
            assetId=>$expectedAssetId,
            url=>$session->url->gateway($matrixListing->get('url')),
            title=>$matrixListing->get('title')
        }]
        ,
        'getListings returns correct data.'
    );


# Test Listings Caching

my $listingsEncoded = WebGUI::Cache->new($session,"matrixListings_".$matrix->getId)->get;
$listings = JSON->new->decode($listingsEncoded);

cmp_deeply(
        $listings,
        [{
            views=>"1",
            lastUpdated=>$matrixListing->get('lastUpdated'),
            clicks=>"1",
            compares=>"0",
            assetId=>$expectedAssetId,
            url=>$session->url->gateway($matrixListing->get('url')),
            title=>$matrixListing->get('title')
        }]
        ,
        'Listings were cached correctly.'
    );

# Test getting compareFormData including the newly added listing

$session->user({userId => 3});
my $json = $matrix->www_getCompareFormData('score');

my $compareFormData = JSON->new->decode($json);

$expectedAssetId =~ s/-/_____/g;

cmp_deeply(
        $compareFormData,
        {ResultSet=>{
            Result=>[{
                    views=>"1",
                    lastUpdated=>$matrixListing->get('lastUpdated'),
                    clicks=>"1",
                    compares=>"0",
                    assetId=>$expectedAssetId,
                    url=>'/'.$matrixListing->get('url'),
                    title=>$matrixListing->get('title')
                    }]
            }
        },
        'Getting compareFormData as JSON: www_getCompareFormData returns correct data as JSON.'
    );        

# Test statistics caching by view method

$matrix->view;

my $varStatisticsEncoded = WebGUI::Cache->new($session,"matrixStatistics_".$matrix->getId)->get;
my $varStatistics = JSON->new->decode($varStatisticsEncoded);

cmp_deeply(
        $varStatistics,
        {
        alphanumeric_sortButton=>"<span id='sortByName'><button type='button'>Sort by name</button></span><br />",
        bestViews_url=>'/'.$matrixListing->get('url'),
        bestViews_count=>1,
        bestViews_name=>$matrixListing->get('title'),
        bestViews_sortButton=>"<span id='sortByViews'><button type='button'>Sort by views</button></span><br />",
        bestCompares_url=>'/'.$matrixListing->get('url'),
        bestCompares_count=>0,
        bestCompares_name=>$matrixListing->get('title'),
        bestCompares_sortButton=>"<span id='sortByCompares'><button type='button'>Sort by compares</button></span><br />",
        bestClicks_url=>'/'.$matrixListing->get('url'),
        bestClicks_count=>1,
        bestClicks_name=>$matrixListing->get('title'),
        bestClicks_sortButton=>"<span id='sortByClicks'><button type='button'>Sort by clicks</button></span><br />",
        last_updated_loop=>[{
                url         => $matrixListing->getUrl,
                name        => $matrixListing->get('title'),
                lastUpdated => $session->datetime->epochToHuman($matrixListing->get('lastUpdated'),"%z")
            }],
        lastUpdated_sortButton=>"<span id='sortByUpdated'><button type='button'>Sort by updated</button></span><br />",
        best_rating_loop=>[{
            url=>'/',
            category=>'category1',
            name=>undef,
            mean=>undef,
            median=>undef,
            count=>undef,
            },
            {
            url=>'/',
            category=>'category2',
            name=>undef,
            mean=>undef,
            median=>undef,
            count=>undef,
            }],
        worst_rating_loop=>[{
            url=>'/',
            category=>'category1',
            name=>undef,
            mean=>undef,
            median=>undef,
            count=>undef,
            },
            {
            url=>'/',
            category=>'category2',
            name=>undef,
            mean=>undef,
            median=>undef,
            count=>undef,
            }],
        listingCount=>1,
        },
        'Statistics were cached by view method.'
    );

END {
	# Clean up after thy self
	$versionTag->rollback();
    $secondVersionTag->rollback();
}

