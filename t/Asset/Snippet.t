#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use FindBin;
use strict;
use lib "$FindBin::Bin/../lib";

##The goal of this test is to test the creation of Snippet Assets.

use WebGUI::Test;
use WebGUI::Session;
use Test::More tests => 10; # increment this value for each test you create
use WebGUI::Asset::Snippet;

my $session = WebGUI::Test->session;
my $node = WebGUI::Asset->getImportNode($session);
my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Snippet Test"});
my $snippet = $node->addChild({className=>'WebGUI::Asset::Snippet'});

# Test for a sane object type
isa_ok($snippet, 'WebGUI::Asset::Snippet');

# Test to see if we can set values
my $properties = {
	cacheTimeout => 124,
	processAsTemplate => 1,
	mimeType => 'text/plain',
	snippet => "Gooey's milkshake brings all the girls to the yard...",
};
$snippet->update($properties);

foreach my $property (keys %{$properties}) {
	is ($snippet->get($property), $properties->{$property}, "updated $property is ".$properties->{$property});
}

TODO: {
        local $TODO = "Tests to make later";
        ok(0, 'Test getToolbar method');
	ok(0, 'Test indexContent method');
	ok(0, 'Test view method');
	ok(0, 'Test www_edit method');
	ok(0, 'Test www_view method... maybe?');
}

END {
	# Clean up after thy self
	$versionTag->rollback($versionTag->getId);
}

