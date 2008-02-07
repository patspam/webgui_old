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
use lib "$FindBin::Bin/../lib";

use WebGUI::Test;
use WebGUI::Form;
use WebGUI::Form::ClassName;
use WebGUI::Session;
use HTML::Form;
use WebGUI::Form_Checking;

#The goal of this test is to verify that ClassName form elements work

use Test::More; # increment this value for each test you create

my $session = WebGUI::Test->session;

# put your tests here

my $testBlock = [
	{
		key => 'Class1',
		testValue => 'WebGUI-test::Asset',
		expected  => 'WebGUItest::Asset',
		comment   => 'invalid: dash',
	},
	{
		key => 'Class2',
		testValue => 'WebGUI/test::Asset',
		expected  => 'WebGUItest::Asset',
		comment   => 'invalid: slash',
	},
	{
		key => 'Class3',
		testValue => 'WebGUI::Test Class',
		expected => 'WebGUI::TestClass',
		comment   => 'invalid: space',
	},
	{
		key => 'Class4',
		testValue => 'WebGUI::Class4',
		expected  => 'EQUAL',
		comment   => 'valid: digit',
	},
	{
		key => 'Class5',
		testValue => 'WebGUI::Image::XY_Graph',
		expected  => 'EQUAL',
		comment   => 'valid: underscore',
	},
	{
		key => 'Class6',
		testValue => 'WebGUI::Class',
		expected  => 'EQUAL',
		comment   => 'valid: simple module',
	},
];

my $formClass = 'WebGUI::Form::ClassName';
my $formType = 'ClassName';

my $numTests = 11 + scalar @{ $testBlock } + 3;


plan tests => $numTests;

my ($header, $footer) = (WebGUI::Form::formHeader($session), WebGUI::Form::formFooter($session));

my $html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'TestClass',
		value => 'WebGUI::Asset::File',
	})->toHtml,
	$footer;

my @forms = HTML::Form->parse($html, 'http://www.webgui.org');

##Test Form Generation

is(scalar @forms, 1, '1 form was parsed');

my @inputs = $forms[0]->inputs;
is(scalar @inputs, 1, 'The form has 1 input');

#Basic tests

my $input = $inputs[0];
is($input->name, 'TestClass', 'Checking input name');
is($input->type, 'text', 'Checking input type');
is($input->value, 'WebGUI::Asset::File', 'Checking default value');
is($input->{size}, 30, 'Default size');
is($input->{maxlength}, 255, 'Default maxlength');

##Test Form Output parsing

my $html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'StorageClass',
		value => 'WebGUI::Storage::Image',
		size => 15,
		maxlength => 20,
	})->toHtml,
	$footer;

@forms = HTML::Form->parse($html, 'http://www.webgui.org');
@inputs = $forms[0]->inputs;
my $input = $inputs[0];
is($input->name, 'StorageClass', 'Checking input name');
is($input->value, 'WebGUI::Storage::Image', 'Checking default value');
is($input->{size}, 15, 'set size');
is($input->{maxlength}, 20, 'set maxlength');

##Test Form Output parsing

#diag $formType;
WebGUI::Form_Checking::auto_check($session, $formType, $testBlock);

#
# test WebGUI::FormValidator::ClassName(undef,@values)
#
is(WebGUI::Form::ClassName->new($session)->getValueFromPost('t*est'), 'test', '$cname->getValueFromPost(arg)');
is($session->form->className(undef,'t*est'),                          'test', 'WebGUI::FormValidator::className');
