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
use lib "$FindBin::Bin/lib";
use WebGUI::Test;
use WebGUI::Session;
use Test::More; # increment this value for each test you create
use File::Copy;
use File::Spec;

my $session = WebGUI::Test->session;

my $numTests  = 1; ##For conditional load check
my $langTests = 4; ##For language look-up tests
$numTests    += 11 + $langTests;

plan tests => $numTests;

my $loaded = use_ok('WebGUI::International');

SKIP: {

skip 'Module was not loaded, skipping all tests', $numTests-1 unless $loaded;

my $i18n = WebGUI::International->new($session, undef, 'English');

isa_ok($i18n, 'WebGUI::International', 'object of correct type created');

is($i18n->getNamespace(), 'WebGUI', 'getNamespace: default namespace is undef');
is($i18n->get('topicName'), 'WebGUI', 'get: get English label for topicName with default namespace: WebGUI');

$i18n->setNamespace('WebGUI');
is($i18n->getNamespace(), 'WebGUI', 'getNamespace: set namespace to WebGUI');
is($i18n->get('topicName'), 'WebGUI', 'get: get English label for topicName: WebGUI');
is($i18n->get('84'), 'Group Name', 'get: get English label for 84: Group Name');

$i18n->setNamespace('Asset');
is($i18n->getNamespace(), 'Asset', 'getNamespace: set namespace to Asset');
is($i18n->get('topicName'), 'Assets', 'get: get English label for topicName in Asset: Assets');
is($i18n->get('topicName', 'WebGUI'), 'WebGUI', 'get: test manual namespace override');

installPigLatin();

my $languages = $i18n->getLanguages();

my $gotPigLatin = exists $languages->{PigLatin};

SKIP: {
	skip 'No PigLatin language pack for testing', $langTests unless $gotPigLatin;
	is(
		$i18n->get('account','WebGUI','English'),
		$i18n->get('account','WebGUI','PigLatin'),
		'Language check: missing key returns English key'
	);
	is(
		$i18n->get('webgui','WebGUI','PigLatin'),
		'ebGUIWay',
		'Language check: existing key returns native language key'
	);
	is(
		$i18n->get('104','Asset','PigLatin'),
		$i18n->get('104', 'WebGUI', 'English'),
		'Language check: key from missing file return English key'
	);
	is(
		$i18n->get('neverAValidKey','notAValidFile','PigLatin'),
		undef,
		'Language check: key from non-existant file returns an empty string'
	);

}

is($i18n->getLanguage('English', 'label'), 'English', 'getLanguage, specific property');

isa_ok($i18n->getLanguage('English'), 'HASH', 'getLanguage, without a specific property returns a hashref');

}

sub installPigLatin {
	mkdir File::Spec->catdir(WebGUI::Test->lib, 'WebGUI', 'i18n', 'PigLatin');
	copy( 
		WebGUI::Test->getTestCollateralPath('WebGUI.pm'),
		File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin WebGUI.pm/)
	);
	copy(
		WebGUI::Test->getTestCollateralPath('PigLatin.pm'),
		File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin.pm/)
	);
}

END {
	unlink File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin WebGUI.pm/);
	unlink File::Spec->catfile(WebGUI::Test->lib, qw/WebGUI i18n PigLatin.pm/);
	rmdir File::Spec->catdir(WebGUI::Test->lib, qw/WebGUI i18n PigLatin/);
}
