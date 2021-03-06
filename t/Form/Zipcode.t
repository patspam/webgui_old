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
use lib "$FindBin::Bin/../lib";

use WebGUI::Test;
use WebGUI::Form;
use WebGUI::Form::Zipcode;
use WebGUI::Session;
use HTML::Form;
use WebGUI::Form_Checking;

#The goal of this test is to verify that Zipcode form elements work

use Test::More; # increment this value for each test you create

my $session = WebGUI::Test->session;

# put your tests here

my $testBlock = [
	{
		key => 'Zip1',
		testValue => 'ABCDE',
		expected  => 'EQUAL',
		comment   => 'alpha',
	},
	{
		key => 'Zip2',
		testValue => '02468',
		expected  => 'EQUAL',
		comment   => 'numeric',
	},
	{
		key => 'Zip3',
		testValue => 'NO WHERE',
		expected  => 'EQUAL',
		comment   => 'alpha space',
	},
	{
		key => 'Zip4',
		testValue => '-',
		expected  => 'EQUAL',
		comment   => 'bare dash',
	},
	{
		key => 'Zip5',
		testValue => 'abcde',
		expected  => undef,
		comment   => 'lower case',
	},
];

my $formClass = 'WebGUI::Form::Zipcode';

my $numTests = 12 + scalar @{ $testBlock } + 11;


plan tests => $numTests;

my ($header, $footer) = (WebGUI::Form::formHeader($session), WebGUI::Form::formFooter($session));

my $html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'TestZip',
		value => '97123-ORST',
	})->toHtml,
	$footer;

my @forms = HTML::Form->parse($html, 'http://www.webgui.org');

##Test Form Generation

is(scalar @forms, 1, '1 form was parsed');

my @inputs = $forms[0]->inputs;
is(scalar @inputs, 1, 'The form has 1 input');

#Basic tests

my $input = $inputs[0];
is($input->name, 'TestZip', 'Checking input name');
is($input->type, 'text', 'Checking input type');
is($input->value, '97123-ORST', 'Checking default value');
is($input->{size}, 30, 'Checking size param, default');
is($input->{maxlength}, 10, 'Checking maxlength param, default');

$html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'TestZip2',
		value => '97229-MXIM',
		size => 12,
		maxlength => 13,
	})->toHtml,
	$footer;

my @forms = HTML::Form->parse($html, 'http://www.webgui.org');
@inputs = $forms[0]->inputs;
$input = $inputs[0];
is($input->name, 'TestZip2', 'Checking input name');
is($input->type, 'text', 'Checking input type');
is($input->value, '97229-MXIM', 'Checking default value');
is($input->{size}, 12, 'Checking size param, default');
is($input->{maxlength}, 13, 'Checking maxlength param, default');

##Test Form Output parsing

WebGUI::Form_Checking::auto_check($session, 'Zipcode', $testBlock);

# test that we can process non-POST values correctly
my $cntl = WebGUI::Form::Zipcode->new($session,{ defaultValue => 4242 });
is($cntl->getValue('ABCDE'), 'ABCDE', 'alpha');
is($cntl->getValue('02468'), '02468', 'numeric');
is($cntl->getValue('NO WHERE'), 'NO WHERE', 'alpha space');
is($cntl->getValue('-'), '-', 'bare dash');
is($cntl->getValue('abcde'), undef, 'lower case');

is($session->form->zipcode(undef,'ABCDE'), 'ABCDE', 'alpha');
is($session->form->zipcode(undef,'02468'), '02468', 'numeric');
is($session->form->zipcode(undef,'NO WHERE'), 'NO WHERE', 'alpha space');
is($session->form->zipcode(undef,'-'), '-', 'bare dash');
is($session->form->zipcode(undef,'abcde'), undef, 'lower case');


__END__

