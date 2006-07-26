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
use WebGUI::Macro::a_account;
use WebGUI::Session;
use HTML::TokeParser;
use Data::Dumper;

use Test::More; # increment this value for each test you create

my $session = WebGUI::Test->session;

# <a class="myAccountLink" href="<tmpl_var account.url>"><tmpl_var account.text></a>
my ($versionTag, $template) = addTemplate();

my $homeAsset = WebGUI::Asset->getDefault($session);

$session->asset($homeAsset);

my $i18n = WebGUI::International->new($session,'Macro_a_account');

my @testSets = (
	{
		label => q!linkonly!,
		template => q!!,
		output => $session->url->append($homeAsset->getUrl(),'op=auth;method=init'),
		comment => 'linkonly argument',
	},
	{
		label => $i18n->get(46),
		template => q!!,
		url => $session->url->page('op=auth;method=init'), ##already validated URL above
		output => \&simpleHTMLParser,
		comment => 'default macro call',
	},
	{
		label => q!This is your account!,
		template => q!!,
		url => $session->url->page('op=auth;method=init'),
		output => \&simpleHTMLParser,
		comment => 'custom label',
	},
	{
		label => q!Custom label!,
		template => $template->get('url'),
		url => $session->url->page('op=auth;method=init'),
		output => \&simpleTextParser,
		comment => 'custom template',
	},
);

my $numTests = 0;
foreach my $testSet (@testSets) {
	$numTests += 1 + (ref $testSet->{output} eq 'CODE');
}

plan tests => $numTests;

foreach my $testSet (@testSets) {
	my $output = WebGUI::Macro::a_account::process( $session,
		$testSet->{label}, $testSet->{template} );
	if (ref $testSet->{output} eq 'CODE') {
		my ($url, $label) = $testSet->{output}->($output);
		is($label, $testSet->{label}, $testSet->{comment}.", label");
		is($url,   $testSet->{url},   $testSet->{comment}.", url");
	}
	else {
		is($output, $testSet->{output}, $testSet->{comment});
	}
}

sub addTemplate {
	$session->user({userId=>3});
	my $importNode = WebGUI::Asset->getImportNode($session);
	my $versionTag = WebGUI::VersionTag->getWorking($session);
	$versionTag->set({name=>"a_account test"});
	my $properties = {
		title => 'a_account test template',
		className => 'WebGUI::Asset::Template',
		url => 'a_account-test',
		namespace => 'Macro/a_account',
		template => "HREF=<tmpl_var account.url>\nLABEL=<tmpl_var account.text>",
		id => 'testTemplatea_account1'
	};
	my $template = $importNode->addChild($properties, $properties->{id});
	$versionTag->commit;
	return ($versionTag, $template);
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

END {
	if (defined $versionTag and ref $versionTag eq 'WebGUI::VersionTag') {
		$versionTag->rollback;
	}
}
