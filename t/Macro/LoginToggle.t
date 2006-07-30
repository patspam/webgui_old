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
use HTML::TokeParser;
use Data::Dumper;

use Test::More; # increment this value for each test you create

my $session = WebGUI::Test->session;

my $homeAsset = WebGUI::Asset->getDefault($session);
$session->asset($homeAsset);
my ($versionTag, $template) = setupTest($session, $homeAsset);

my $i18n = WebGUI::International->new($session,'Macro_LoginToggle');

my @testSets = (
	{
		comment     => 'linkonly test, Visitor',
		userId      => 1,
		loginText   => 'linkonly',
		logoutText  => '',
		template    => q!!,
		parser      => '',
	},
	{
		comment     => 'linkonly test, Admin',
		userId      => 3,
		loginText   => 'linkonly',
		logoutText  => '',
		template    => q!!,
		parser      => '',
	},
	{
		comment     => 'loginToggle, default text, Visitor',
		userId      => 1,
		loginText   => '',
		logoutText  => '',
		template    => q!!,
		parser      => \&simpleHTMLParser,
	},
	{
		comment     => 'loginToggle, default text, Admin',
		userId      => 3,
		loginText   => '',
		logoutText  => '',
		template    => q!!,
		parser      => \&simpleHTMLParser,
	},
	{
		comment     => 'loginToggle, custom login text, Visitor',
		userId      => 1,
		loginText   => 'Log in, dude',
		logoutText  => '',
		template    => q!!,
		parser      => \&simpleHTMLParser,
	},
	{
		comment     => 'loginToggle, custom logout text, Admin',
		userId      => 3,
		loginText   => '',
		logoutText  => 'I am outta here',
		template    => q!!,
		parser      => \&simpleHTMLParser,
	},
	{
		comment     => 'loginToggle, custom text, Visitor',
		userId      => 1,
		loginText   => 'Log in, dude',
		logoutText  => 'I am outta here',
		template    => q!!,
		parser      => \&simpleHTMLParser,
	},
	{
		comment     => 'loginToggle, custom text, Admin',
		userId      => 3,
		loginText   => 'Log in, dude',
		logoutText  => 'I am outta here',
		template    => q!!,
		parser      => \&simpleHTMLParser,
	},
	{
		comment     => 'loginToggle, default text, custom template, Visitor',
		userId      => 1,
		loginText   => '',
		logoutText  => '',
		template    => $template->getUrl,
		parser      => \&simpleTextParser,
	},
	{
		comment     => 'loginToggle, default text, Admin',
		userId      => 3,
		loginText   => '',
		logoutText  => '',
		template    => $template->getUrl,
		parser      => \&simpleTextParser,
	},
	{
		comment     => 'loginToggle, custom text and template, Visitor',
		userId      => 1,
		loginText   => 'Log in, dude',
		logoutText  => 'I am outta here',
		template    => $template->getUrl,
		parser      => \&simpleTextParser,
	},
	{
		comment     => 'loginToggle, custom text and template, Admin',
		userId      => 3,
		loginText   => 'Log in, dude',
		logoutText  => 'I am outta here',
		template    => $template->getUrl,
		parser      => \&simpleTextParser,
	},
);

my $numTests = 0;
foreach my $testSet (@testSets) {
	$numTests += 1 + (ref $testSet->{parser} eq 'CODE');
}

$numTests += 1; #for the use_ok
plan tests => $numTests;

my $macro = 'WebGUI::Macro::LoginToggle';
my $loaded = use_ok($macro);

SKIP: {

skip "Unable to load $macro", $numTests-1 unless $loaded;

foreach my $testSet (@testSets) {
	$session->user({userId=>$testSet->{userId}});
	if ($testSet->{userId} eq '1') {
		$testSet->{label} = $testSet->{loginText} || $i18n->get(716);
		$testSet->{url} = $session->url->page('op=auth;method=init'),
	}
	else {
		$testSet->{label} = $testSet->{logoutText} || $i18n->get(717);;
		$testSet->{url} = $session->url->page('op=auth;method=logout'),
	}
	my $output = WebGUI::Macro::LoginToggle::process($session,
		$testSet->{loginText}, $testSet->{logoutText}, $testSet->{template});
	if (ref $testSet->{parser} eq 'CODE') {
		my ($url, $label) = $testSet->{parser}->($output);
		is($label, $testSet->{label}, $testSet->{comment}.", label");
		is($url,   $testSet->{url},   $testSet->{comment}.", url");
	}
	else {
		is($output, $testSet->{url}, $testSet->{comment});
	}
}

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

sub setupTest {
	my ($session, $defaultNode) = @_;
	$session->user({userId=>3});
	my $editGroup = WebGUI::Group->new($session, "new");
	my $tao = WebGUI::Group->find($session, "Turn Admin On");
	##Create an asset with specific editing privileges
	my $versionTag = WebGUI::VersionTag->getWorking($session);
	$versionTag->set({name=>"LoginToggle test"});
	my $properties = {
		title => 'LoginToggle test template',
		className => 'WebGUI::Asset::Template',
		url => 'editabletoggle-test',
		namespace => 'Macro/LoginToggle',
		template => "HREF=<tmpl_var toggle.url>\nLABEL=<tmpl_var toggle.text>",
		groupIdEdit => $editGroup->getId(),
		#     '1234567890123456789012'
		id => 'LoginToggleTemplateA01',
	};
	my $template = $defaultNode->addChild($properties, $properties->{id});
	$versionTag->commit;
	return ($versionTag, $template);
}

END { ##Clean-up after yourself, always
	if (defined $versionTag and ref $versionTag eq 'WebGUI::VersionTag') {
		$versionTag->rollback;
	}
}
