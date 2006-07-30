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

use WebGUI::Test;
use WebGUI::Session;
use Data::Dumper;

use Test::More; # increment this value for each test you create
use HTML::TokeParser;

my $session = WebGUI::Test->session;

my $homeAsset = WebGUI::Asset->getDefault($session);
my ($versionTag, $template, $groups, $users) = setupTest($session, $homeAsset);

my @testSets = (
	{
		comment => 'Empty macro call returns null string',
		groupName => '',
		text => '',
		template => '',
		empty => 1,
		userId => $users->[2]->userId,
	},
	{
		comment => 'Empty group returns null string',
		groupName => '',
		text => 'Join up',
		template => '',
		empty => 1,
		userId => $users->[2]->userId,
	},
	{
		comment => 'Empty text returns null string',
		groupName => $groups->[0]->name,
		text => '',
		template => '',
		empty => 1,
		userId => $users->[2]->userId,
	},
	{
		comment => 'Visitor sees empty string with valid group and text',
		groupName => $groups->[0]->name(),
		text => 'Join up!',
		template => '',
		empty => 1,
		userId => 1,
	},
	{
		comment => 'Non-existant group returns null string',
		groupName => "Dudes of the day",
		text => 'Join up!',
		template => '',
		empty => 1,
		userId => $users->[2]->userId,
	},
	{
		comment => 'Group without autoAdd returns null string',
		groupName => $groups->[1]->name,
		text => 'Join up!',
		template => '',
		empty => 1,
		userId => $users->[2]->userId,
	},
	{
		comment => 'Existing member of group sees empty string',
		groupName => $groups->[0]->name,
		text => 'Join up!',
		template => '',
		empty => 1,
		userId => $users->[0]->userId,
	},
	{
		comment => 'Non-member of group sees text and link',
		groupName => $groups->[0]->name,
		groupId => $groups->[0]->getId,
		text => 'Join up!',
		template => '',
		empty => 0,
		userId => $users->[2]->userId,
		parser => \&simpleHTMLParser,
	},
	{
		comment => 'Member of different group sees text and link',
		groupName => $groups->[0]->name,
		groupId => $groups->[0]->getId,
		text => 'Join up!',
		template => '',
		empty => 0,
		userId => $users->[1]->userId,
		parser => \&simpleHTMLParser,
	},
	{
		comment => 'Custom template check',
		groupName => $groups->[0]->name,
		groupId => $groups->[0]->getId,
		text => 'Join up!',
		template => $template->get('url'),
		empty => 0,
		userId => $users->[1]->userId,
		parser => \&simpleTextParser,
	},
);

my $numTests = 0;
foreach my $testSet (@testSets) {
	$numTests += 1 + ($testSet->{empty} == 0);
}

$numTests += 1; #For the use_ok

plan tests => $numTests;

my $macro = 'WebGUI::Macro::GroupAdd';
my $loaded = use_ok($macro);

SKIP: {

skip "Unable to load $macro", $numTests-1 unless $loaded;

foreach my $testSet (@testSets) {
	$session->user({ userId => $testSet->{userId} });
	my $output = WebGUI::Macro::GroupAdd::process($session,
		$testSet->{groupName}, $testSet->{text}, $testSet->{template});
	if ($testSet->{empty}) {
		is($output, '', $testSet->{comment});
	}
	else {
		my ($url, $text) = $testSet->{parser}->($output);
		is($text, $testSet->{text}, 'TEXT: '.$testSet->{comment});
		my $expectedUrl = $session->url->page('op=autoAddToGroup;groupId='.$testSet->{groupId});
		is($url, $expectedUrl, 'URL: '.$testSet->{comment});
	}
}

}

sub setupTest {
	my ($session, $defaultNode) = @_;
	my @groups;
	##Two groups, one with Group Add and one without
	$groups[0] = WebGUI::Group->new($session, "new");
	$groups[0]->name('AutoAdd Group');
	$groups[0]->autoAdd(1);
	$groups[1] = WebGUI::Group->new($session, "new");
	$groups[1]->name('Regular Old Group');
	$groups[1]->autoAdd(0);

	##Three users.  One in each group and one with no group membership
	my @users = map { WebGUI::User->new($session, "new") } 0..2;
	$users[0]->addToGroups([$groups[0]->getId]);
	$users[1]->addToGroups([$groups[1]->getId]);

	my $versionTag = WebGUI::VersionTag->getWorking($session);
	$versionTag->set({name=>"GroupAdd test"});
	my $properties = {
		title => 'GroupAdd test template',
		className => 'WebGUI::Asset::Template',
		url => 'groupadd-test',
		namespace => 'Macro/GroupAdd',
		template => "HREF=<tmpl_var group.url>\nLABEL=<tmpl_var group.text>",
		#     '1234567890123456789012'
		id => 'GroupAdd001100Template',
	};
	my $asset = $defaultNode->addChild($properties, $properties->{id});
	$versionTag->commit;

	return $versionTag, $asset, \@groups, \@users;
}

sub simpleHTMLParser {
	my ($text) = @_;
	my $p = HTML::TokeParser->new(\$text);

	my $token = $p->get_tag("a");
	my $url = $token->[1]{href} || "-";
	my $label = $p->get_trimmed_text("/a");

	return ($url, $label);
}

sub simpleTextParser {
	my ($text) = @_;

	my ($url)   = $text =~ /^HREF=(.+)$/m;
	my ($label) = $text =~ /^LABEL=(.+)$/m;

	return ($url, $label);
}


END { ##Clean-up after yourself, always
	foreach my $testGroup (@{ $groups }, ) {
		$testGroup->delete if (defined $testGroup and ref $testGroup eq 'WebGUI::Group');
	}
	foreach my $dude (@{ $users }, ) {
		$dude->delete if (defined $dude and ref $dude eq 'WebGUI::User');
	}
	if (defined $versionTag and ref $versionTag eq 'WebGUI::VersionTag') {
		$versionTag->rollback;
	}
}
