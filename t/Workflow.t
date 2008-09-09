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
use lib "$FindBin::Bin/lib";
use WebGUI::Test;
use WebGUI::Session;
use WebGUI::Workflow;
use WebGUI::Workflow::Cron;
use WebGUI::Utility qw/isIn/;
use Test::More tests => 38; # increment this value for each test you create

my $session = WebGUI::Test->session;
my $wf = WebGUI::Workflow->create($session, {title => 'Title', description => 'Description',
					     type => 'None'});
ok(defined $wf, 'can create workflow');
isa_ok($wf, 'WebGUI::Workflow', 'workflow');

my $wfId = $wf->getId;
ok(defined $wfId, 'workflow has an ID');
ok($session->id->valid($wfId), 'Workflow has a valid Id');
ok(defined WebGUI::Workflow->new($session, $wfId), 'workflow can be retrieved');

is($wf->get('title'), 'Title', 'workflow title is set');
is($wf->get('description'), 'Description', 'workflow description is set');
is($wf->get('type'), 'None', 'workflow type is set');
ok(!$wf->get('enabled'), 'workflow is not enabled');
# TODO: test other properties
is_deeply($wf->getActivities, [], 'workflow has no activities');
is_deeply($wf->getInstances, [], 'workflow has no instances');
is_deeply($wf->getCrons, [], 'workflow has no crons');

isa_ok(WebGUI::Workflow->getList($session), 'HASH', 'getList returns a hashref');

ok(!isIn($wfId, keys %{WebGUI::Workflow->getList($session)}), 'workflow not in enabled list');

$wf->set({enabled => 1});
ok($wf->get('enabled'), 'workflow is enabled');
ok(isIn($wfId, keys %{WebGUI::Workflow->getList($session)}), 'workflow in enabled list');
$wf->set({enabled => 0});
ok(!$wf->get('enabled'), 'workflow is disabled again');

##################################################
#
# Mode tests
#
##################################################

is($wf->get('mode'), 'parallel', 'default mode for created workflows is parallel');
ok(! $wf->isSingleton, 'Is not singleton');
ok(! $wf->isSerial,    'Is not serial');
ok(  $wf->isParallel,  'Is parallel');
$wf->set({'mode', 'serial'});
is(join('', $wf->isSingleton, $wf->isSerial, $wf->isParallel), '010', 'Is checks after setting mode to serial');
$wf->set({'mode', 'singleton'});
is(join('', $wf->isSingleton, $wf->isSerial, $wf->isParallel), '100', 'Is checks after setting mode to singleton');

$wf->delete;
ok(!defined WebGUI::Workflow->new($session, $wfId), 'deleted workflow cannot be retrieved');

my $wf2 = WebGUI::Workflow->create($session, {title => 'Title', description => 'Description',
					      type => 'WebGUI::VersionTag'});
ok(defined $wf2, 'can create version tag workflow');
isa_ok($wf2, 'WebGUI::Workflow', 'workflow');

require WebGUI::Workflow::Activity::UnlockVersionTag;
my $activity = WebGUI::Workflow::Activity::UnlockVersionTag->create($session, $wf2->getId);
ok(defined $activity, 'can create activity');
isa_ok($activity, 'WebGUI::Workflow::Activity::UnlockVersionTag', 'activity');
isa_ok($activity, 'WebGUI::Workflow::Activity', 'activity');
my $actId = $activity->getId;
ok(defined $actId, 'activity has an ID');
is(scalar @{$wf2->getActivities}, 1, 'workflow has one activity');
is($wf2->getActivities->[0]->getId, $actId, 'Workflow has the correct activity');

TODO: {
	local $TODO = "Tests that test things that do not work yet";
	# Mismatched activity with workflow.
	require WebGUI::Workflow::Activity::DecayKarma;
	my $badActivity = WebGUI::Workflow::Activity::DecayKarma->create($session, $wf2->getId);
	ok(!defined $badActivity, 'cannot create mismatched activity');
	is(scalar @{$wf2->getActivities}, 1, 'workflow still has one activity');
}

my $cron = WebGUI::Workflow::Cron->create($session,
					  {monthOfYear => '*', dayOfMonth => '5', hourOfDay => '2',
					   minuteOfHour => '15', dayOfWeek => '*', enabled => 1,
					   runOnce => 0, priority => 2, workflowId => $wf2->getId,
					   title => 'Test Cron'});
ok(defined $cron, 'can create cron');
isa_ok($cron, 'WebGUI::Workflow::Cron', 'cron');
is(scalar @{$wf2->getCrons}, 1, 'workflow has one cron');
is($wf2->getCrons->[0]->getId, $cron->getId, 'one cron is same cron');
$cron->delete;

# More activity and cron tests here?

$wf2->delete;

# Local variables:
# mode: cperl
# End:
