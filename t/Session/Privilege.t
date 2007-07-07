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

use WebGUI::Test;
use WebGUI::Session;
use WebGUI::International;

use Test::More; # increment this value for each test you create
use Test::Deep;

my @simpleTests = (
	{
		method => 'adminOnly',
		status => 401,
		description => 'Admin Only',
		titleCode => 35,
	},
	{
		method => 'insufficient',
		status => 401,
		description => 'Insufficient Privileges',
		titleCode => 37,
	},
	{
		method => 'locked',
		status => 401,
		description => 'Insufficient Privileges',
		titleCode => 37,
	},
	{
		method => 'notMember',
		status => 400,
		description => 'Not A Member',
		titleCode => 345,
	},
	{
		method => 'vitalComponent',
		status => 403,
		description => 'Vital Component',
		titleCode => 40,
	},
	{
		method => 'noAccess',
		status => 401,
		description => 'No Access',
		titleCode => 37,
	},

);

my $num_tests = 1;
$num_tests += 4 * scalar @simpleTests; ##For each simple privilege validation
$num_tests += 3; ##For noAccess as Visitor tests
$num_tests += 4; ##For insufficient with noStyle=1

plan tests => $num_tests;
 
my $session = WebGUI::Test->session;
 
# put your tests here

my $privilege = $session->privilege;

my ($versionTag, $userTemplate) = setup_assets($session);

isa_ok($privilege, 'WebGUI::Session::Privilege', 'session has correct object type');

##Override the original user style template to make verification easier
my $origUserStyle = $session->setting->get('userFunctionStyleId');
$session->setting->set('userFunctionStyleId', $userTemplate->getId);

#One of the tests has different behavior depending on how it is called.
#If the user is visitor, it passes them to the login screen. We'll set
#the user to a different user to do simple testing on that method, then
#we'll come back and do the specialized testing.
$session->user({userId=>3});

my $i18n = WebGUI::International->new($session);

foreach my $test (@simpleTests) {
	my $method = $test->{method};
	my $output = $privilege->$method;
	is($session->http->getStatus(), $test->{status}, "$method: status code");
	is($session->http->getStatusDescription(), $test->{description}, "$method: description");
	my $title = $i18n->get($test->{titleCode});
	like($output, qr{<h1>$title</h1>}, "$method: correct title");
	like($output, qr{^USERSTYLE}, "$method: renders in WebGUI User Style");
}


####################################################
#
# insufficient with empty style
#
####################################################

my $output = $privilege->insufficient(1);
is($session->http->getStatus(), '401', 'insufficient: status code with Visitor');
is($session->http->getStatusDescription(), 'Insufficient Privileges', 'insufficient: description with Visitor');
my $title = $i18n->get(37);
unlike($output, qr{^USERSTYLE}, "insufficient: when noStyle is true the user style is not used");
like($output, qr{<h1>$title</h1>}, "insufficient: when noStyle is true the title is still okay");

####################################################
#
# noAccess when the user is the Visitor
#
####################################################

$session->user({userId=>1});

my $output = $privilege->noAccess;
is($session->http->getStatus(), '401', 'noAccess: status code with Visitor');
is($session->http->getStatusDescription(), 'No Access', 'noAccess: description with Visitor');
##Is the auth screen returned, not validating the auth screen
is($output, WebGUI::Operation::Auth::www_auth($session, "init"), 'noAccess: visitor sees auth screen');

sub setup_assets {
	my $session = shift;
	my $importNode = WebGUI::Asset->getImportNode($session);
	my $versionTag = WebGUI::VersionTag->getWorking($session);
	$versionTag->set({name=>"Session Style test"});
	my $properties = {
		title => 'user template for printing',
		className => 'WebGUI::Asset::Template',
		url => 'user_style_printable',
		namespace => 'Style',
		##Note, at this point 
		template => "USERSTYLE:<tmpl_var body.content>",
		id => 'printableUser0Template',
		#     '1234567890123456789012'
	};
	my $userTemplate = $importNode->addChild($properties, $properties->{id});
	return ($versionTag, $userTemplate);
}


END {
	$session->setting->set('userFunctionStyleId', $origUserStyle);
	if (defined $versionTag and ref $versionTag eq 'WebGUI::VersionTag') {
		$versionTag->rollback;
	}
}
