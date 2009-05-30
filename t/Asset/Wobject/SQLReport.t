# vim:syntax=perl
#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#------------------------------------------------------------------

# Write a little about what this script tests.
# 
#

use FindBin;
use strict;
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Test::Deep;
use Data::Dumper;

use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;

################################################################
#
#  setup session, users and groups for this test
#
################################################################

my $session         = WebGUI::Test->session;

my $tests = 4
          ;
plan tests => 1
            + $tests;

#----------------------------------------------------------------------------
# put your tests here

my $class  = 'WebGUI::Asset::Wobject::SQLReport';
my $loaded = use_ok($class);

SKIP: {

skip "Unable to load module $class", $tests unless $loaded;


my $defaultNode = WebGUI::Asset->getDefault($session);

my $report = $defaultNode->addChild({
    className     => $class,
    title         => 'test report',
    cacheTimeout  => 50,
    dqQuery1      => 'select * from users',
});

my $versionTag = WebGUI::VersionTag->getWorking($session);
WebGUI::Test->tagsToRollback($versionTag);
$versionTag->commit;

isa_ok($report, 'WebGUI::Asset::Wobject::SQLReport');

is($report->get('cacheTimeout'), 50, 'cacheTimeout set correctly');
ok(abs($report->getContentLastModified - (time - 50)) < 2, 'getContentLastModified overridden correctly');

$report->update({cacheTimeout => 250});
ok(abs($report->getContentLastModified - (time - 250)) < 2, '... tracks cacheTimeout');

}
