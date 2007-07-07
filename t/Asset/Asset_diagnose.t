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
use lib "$FindBin::Bin/../lib";

##The goal of this test is to look for orphaned assetIds across
##all assets in the Asset's main table, and the asset and assetData tables.

use WebGUI::Test;
use WebGUI::Session;
use WebGUI::Utility;
use Test::More; # increment this value for each test you create
use Test::Deep;

my $session = WebGUI::Test->session;

my @assets = grep { !isIn($_, qw/WebGUI::Asset::FilePile/) } (
		@{ $session->config->get('assets') },
		@{ $session->config->get('utilityAssets') },
		@{ $session->config->get('assetContainers') },
);

my $numTests = scalar (2*@assets) + 2;
plan tests => $numTests;
	
my $assetIds     = $session->db->buildArrayRef("select distinct(assetId) from asset order by assetId");
my $assetDataIds = $session->db->buildArrayRef("select distinct(assetId) from assetData order by assetId");

##This is a quick test to see if details of mismatch are required
my $noDetails = is_deeply($assetIds, $assetDataIds, "Checking asset vs assetData");

SKIP: {
	skip("No need for details", 1) if $noDetails;
	##This test takes a very, very long time.
	cmp_bag($assetIds, $assetDataIds, "Checking asset vs assetData");
}

foreach my $asset ( @assets ) {
	eval "use $asset";
	my $def = $asset->definition($session);
	my $tableName = $def->[0]->{tableName};
	my $classIds = $session->db->buildArrayRef("select distinct(assetId) from asset where className LIKE ? order by assetId", [$asset.'%']);
	my $tableIds = $session->db->buildArrayRef(sprintf("select distinct(assetId) from %s order by assetId", $tableName));
	my $skipDetails = is_deeply($classIds, $tableIds,
			sprintf("Comparing assetIds for %s",$asset)
			);
	SKIP: {
		skip("No details needed for $asset", 1) if $skipDetails;
		cmp_bag($classIds, $tableIds, "Checking asset vs table for $asset");
	}
}
