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
use WebGUI::Form;
use WebGUI::Form::SelectList;
use WebGUI::Session;
use HTML::Form;
use Tie::IxHash;
use WebGUI::Form_Checking;

#The goal of this test is to verify that SelectList form elements work

use Test::More;
use Test::Deep;

my $session = WebGUI::Test->session;

# put your tests here

my %testBlock;

tie %testBlock, 'Tie::IxHash';

%testBlock = (
	LIST1 => [ [qw/a/],	'a',		'single element array, scalar', 'SCALAR'],
	LIST2 => [ [qw/a/],	'EQUAL',	'single element array, array', 'ARRAY'],
	LIST3 => [ [qw/a b c/],	"a\nb\nc",	'multi element array, scalar', 'SCALAR'],
	LIST4 => [ [qw/a b c/],	'EQUAL',	'multi element array, array', 'ARRAY'],
);

my $formClass = 'WebGUI::Form::SelectList';
my $formType = 'SelectList';

my $numTests = 11 + scalar keys %testBlock;

diag("Planning on running $numTests tests\n");

plan tests => $numTests;

my ($header, $footer) = (WebGUI::Form::formHeader($session), WebGUI::Form::formFooter($session));

my $html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'ListMultiple',
		options => { a=>'aa', b=>'bb', c=>'cc', d=>'dd', e=>'ee', ''=>'Empty' },
		value => [ qw(a c e), ''],
		sortByValue => 1,
	})->toHtml,
	$footer;

my @forms = HTML::Form->parse($html, 'http://www.webgui.org');

##Test Form Generation

is(scalar @forms, 1, '1 form was parsed');

my $form = $forms[0];
#use Data::Dumper;
#diag(Dumper $form);
my @inputs = $form->inputs;
is(scalar @inputs, 6, 'The form has 6 inputs');

#Basic tests

my @options = $form->find_input('ListMultiple');

is( scalar(grep {$_->type ne 'option'} @options), 0, 'All inputs are of type option');

is( scalar(grep {$_->{multiple} ne '1'} @options), 0, 'All inputs have multiple');

my @names = map { $_->name } @options;
cmp_deeply( [@names], bag(('ListMultiple')x6), 'correct number of names and names');

cmp_set([ $form->param('ListMultiple') ], [qw(a c e), ''], 'preselected values in order');

my @values = map { $_->possible_values } @options;
cmp_bag([ @values ], [qw(a b c d e), '', (undef)x6], 'list of all options');

my @value_names = map { $_->value_names } @options;
cmp_bag([ @value_names ], [qw(aa bb cc dd ee Empty), ('off')x6], 'list of all displayed value names');

$html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'ListMultiple',
		options => { a=>'aa', b=>'bb', c=>'cc', d=>'dd', e=>'ee' },
		defaultValue => [ qw(a b c) ],
		sortByValue => 1,
	})->toHtml,
	$footer;

@forms = HTML::Form->parse($html, 'http://www.webgui.org');
$form = $forms[0];

cmp_bag([ $form->param('ListMultiple') ], [qw(a b c)], 'defaultValue used if value is blank');


$html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'ListMultiple',
		options => { a=>'aa', b=>'bb', c=>'cc', d=>'dd', e=>'ee' },
		value => [ qw(d e) ],
		defaultValue => [ qw(a b c) ],
		sortByValue => 1,
	})->toHtml,
	$footer;

@forms = HTML::Form->parse($html, 'http://www.webgui.org');
$form = $forms[0];

cmp_bag([ $form->param('ListMultiple') ], [qw(d e)], 'defaultValue ignored if value is present');


$html = join "\n",
	$header, 
	$formClass->new($session, {
		name => 'ListMultiple',
		options => { a=>'aa', b=>'bb', c=>'cc', d=>'dd', e=>'ee' },
		value => [ qw(a b c d e) ],
		sortByValue => 1,
	})->toHtml,
	$footer;

@forms = HTML::Form->parse($html, 'http://www.webgui.org');
$form = $forms[0];

cmp_set([ $form->param('ListMultiple') ], [qw(a b c d e)], 'sorted value check');

##Test Form Output parsing

WebGUI::Form_Checking::auto_check($session, $formType, %testBlock);
