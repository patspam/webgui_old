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
use WebGUI::Form::FieldType;
use WebGUI::Form::DynamicField;
use WebGUI::Session;
use WebGUI::Utility;

#The goal of this test is to verify that the profileEnabled setting
#works on all form elements and that only the correct forms are profile
#enabled.

use Test::More; # increment this value for each test you create

my $numTests = 0;

my $session = WebGUI::Test->session;

# put your tests here

my @formTypes = sort @{ WebGUI::Form::FieldType->getTypes($session) };

##We have to remove DynamicField from this list, since when you call new
##it wants to return a type.  We'll check it manually.

$numTests = scalar @formTypes + 1;

plan tests => $numTests;


my @notEnabled = qw/Asset Button Captcha Checkbox Color Control List MimeType SubscriptionGroup Slider Submit User Attachments/;

foreach my $formType (@formTypes) {
	my $form = WebGUI::Form::DynamicField->new($session, fieldType => $formType);
	my $ref = (split /::/, ref $form)[-1];
	if (isIn($ref, @notEnabled)) {
		ok(!$form->get('profileEnabled'), " $ref should not be profile enabled");
	}
	else {
		ok($form->get('profileEnabled'), "$ref should be profile enabled");
	}
}

##Note: DynamicField will report true, but only because it's actually creating
##an object of type Text!
my $form = WebGUI::Form::DynamicField->new($session);

ok($form->get('profileEnabled'), 'DynamicField lies about being profile enable');
