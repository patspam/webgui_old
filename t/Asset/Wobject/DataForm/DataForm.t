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
use lib "$FindBin::Bin/../../../lib";

##The goal of this test is to test the creation of Article Wobjects.

use WebGUI::Test;
use WebGUI::Session;
use Test::More 'no_plan'; # tests => 23; # increment this value for each test you create
use WebGUI::Asset::Wobject::Article;

my $session = WebGUI::Test->session;

# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

# Lets create an article wobject using all defaults then test to see if those defaults were set
#
#     This is all commented out right now because it seems the API is not intended to set defaultValues
#     based on an assets defintion.  This may change down the line, so lets just comment this out for now.
#
#my $articleDefaults = {
#	cacheTimeout => 3600,
#	templateId   => 'PBtmpl0000000000000002',
#	linkURL	     => undef,
#	linkTitle    => undef,
#	storageId    => undef,
#};

my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Article Test"});
my $article = $node->addChild({className=>'WebGUI::Asset::Wobject::Article'});

# Test for a sane object type
isa_ok($article, 'WebGUI::Asset::Wobject::Article');

# Test to see if all of the default properties are correct
#foreach my $defaultProperty (keys %{$articleDefaults}) {
#	is ($article->get($defaultProperty), $articleDefaults->{$defaultProperty}, "default $defaultProperty is ".$articleDefaults->{$defaultProperty});
#}

# Test to see if we can set new values
my $newArticleSettings = {
	cacheTimeout => 124,
	templateId   => "PBtmpl0000000000000084",
	linkURL      => "http://www.snapcount.org",
	linkTitle    => "I'm thinking of getting metal legs",
	storageId    => "ImadeThisUp",
};
$article->update($newArticleSettings);

foreach my $newSetting (keys %{$newArticleSettings}) {
	is ($article->get($newSetting), $newArticleSettings->{$newSetting}, "updated $newSetting is ".$newArticleSettings->{$newSetting});
}

# Test the duplicate method... not for assets, just the extended duplicate functionality of the article wobject
my $filename = "page_title.jpg";
my $pathedFile = WebGUI::Test->getTestCollateralPath($filename);

# Use some test collateral to create a storage location and assign it to our article
my $storage = WebGUI::Storage->create($session);
my $storedFilename = $storage->addFileFromFilesystem($pathedFile);
my $filenameOK = is ($storedFilename, $filename, 'storage created correctly');

diag(join("\n", @{ $storage->getErrors })) unless $filenameOK;

$article->update({storageId=>$storage->getId});
my $storageOK = is($article->get('storageId'), $storage->getId, 'correct storage id stored');

SKIP: {

skip 'storage test setup problem', 3 unless $filenameOK and $storageOK;

my $duplicateArticle = $article->duplicate();
isa_ok($duplicateArticle, 'WebGUI::Asset::Wobject::Article');

my $duplicateStorageId = $duplicateArticle->get("storageId");
my $duplicateStorage = WebGUI::Storage->get($session,$duplicateStorageId);
my $duplicateFilename = $duplicateStorage->getFiles->[0];

is ($duplicateFilename, $filename, "duplicate method copies collateral");

# Test the purge method to see if it gets rid of the collateral

$duplicateArticle->purge();

# The get method will create the directory if it doesnt exist... very strange.
$duplicateStorage = WebGUI::Storage->get($session,$duplicateStorageId);

# so lets check for the file instead
$duplicateFilename = $duplicateStorage->getFiles->[0];

is ($duplicateFilename, undef, 'purge method deletes collateral');

}

# Lets make sure the view method returns something.
# This is not a very good test but I need to do it to test the purgeCache method anyways =)

is ($article->{_viewTemplate}, undef, 'internal template cache unset until prepareView is called');
$article->prepareView;
isnt ($article->{_viewTemplate}, undef, 'internal template cache set by prepare view');
isa_ok ($article->{_viewTemplate}, 'WebGUI::Asset::Template', 'internal template cache');
my $output = $article->view;
isnt ($output, "", 'view method returns something');

# Lets see if caching works
my $cachedOutput = WebGUI::Cache->new($session, 'view_'.$article->getId)->get;
is ($output, $cachedOutput, 'view method caches output');

# Lets see if the purgeCache method works
$article->purgeCache;
$cachedOutput = WebGUI::Cache->new($session, 'view_'.$article->getId)->get;  # Check cache post purge
isnt ($output, $cachedOutput, 'purgeCache method deletes cache');


TODO: {
        local $TODO = "Tests to make later";
        ok(0, 'Test exportAssetData method');
	ok(0, 'Test getStorageLocation method');
	ok(0, 'Test indexContent method');
	ok(0, 'Test purgeRevision method');
	ok(0, 'Test www_deleteFile method');
	ok(0, 'Test www_view method... maybe?');
}

END {
	# Clean up after thy self
	$versionTag->rollback();
}

