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
use WebGUI::Storage;

use Test::More; # increment this value for each test you create

my $session = WebGUI::Test->session;

my $i18n = WebGUI::International->new($session, 'Macro_Include');

my $configFile = WebGUI::Test->root .'/etc/'. WebGUI::Test->file;
my $spectreConf = WebGUI::Test->root . '/etc/spectre.conf';

my $goodFile = 'The contents of this file are accessible';
my $twoLines = "This file contains two lines of text\nThis is the second line";
my $storage = WebGUI::Storage->createTemp($session);
$storage->addFileFromScalar('goodFile', $goodFile);
$storage->addFileFromScalar('twoLines', $twoLines);
$storage->addFileFromScalar('unreadableFile', 'The contents of this file are not readable');
my $unreadable = $storage->getPath('unreadableFile');
chmod(0111, $unreadable);

my @testSets = (
	{
		file => '/etc/passwd',
		output => $i18n->get('security'),
		comment => q|passwd file|,
	},
	{
		file => '/passwd/foo.txt',
		output => $i18n->get('security'),
		comment => q|passwd path|,
	},
	{
		file => '/etc/shadow',
		output => $i18n->get('security'),
		comment => q|shadow file|,
	},
	{
		file => '/shadow/foo.txt',
		output => $i18n->get('security'),
		comment => q|shadow path|,
	},
	{
		file => $configFile,
		output => $i18n->get('security'),
		comment => q|WebGUI config file|,
	},
	{
		file => $spectreConf,
		output => $i18n->get('security'),
		comment => q|spectre config file|,
	},
	{
		file => $storage->getPath('non-existantFile'),
		output => $i18n->get('not found'),
		comment => q|Non-existant file returns NOT FOUND|,
	},
	{
		file => $storage->getPath('goodFile'),
		output => $goodFile,
		comment => q|Included a good file|,
	},
	{
		file => $storage->getPath('twoLines'),
		output => $twoLines,
		comment => q|Included a file with two lines|,
	},
);

my $numTests = scalar @testSets;

$numTests += 1; #For the use_ok
$numTests += 1; #For the unreadable file test

plan tests => $numTests;

my $macro = 'WebGUI::Macro::Include';
my $loaded = use_ok($macro);

SKIP: {

skip "Unable to load $macro", $numTests-1 unless $loaded;

foreach my $testSet (@testSets) {
	my $output = WebGUI::Macro::Include::process($session, $testSet->{file});
	is($output, $testSet->{output}, $testSet->{comment} . ":" .$testSet->{file});
}

SKIP: {
	skip "Root will cause this test to fail since it does not obey file permissions", 1
		if $< == 0;
	my $file = $storage->getPath('unreadableFile');
	my $output = WebGUI::Macro::Include::process($session, $file);
	is($output, $i18n->get('not found'),  q|Unreadable file returns NOT FOUND|. ":" .$file);
}

}

END {
	$storage->delete;
}
