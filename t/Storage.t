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
use lib "$FindBin::Bin/lib";
our $todo;

use WebGUI::Test;
use WebGUI::Session;
use WebGUI::Storage;

use Test::More;

plan tests => 22; # increment this value for each test you create

my $session = WebGUI::Test->session;

my $uploadDir = $session->config->get('uploadsPath');

ok ($uploadDir, "uploadDir defined in config");

ok ((-e $uploadDir and -d $uploadDir), "uploadDir exists and is a directory");

my $storage1 = WebGUI::Storage->get($session);

is( $storage1, undef, "get requires id to be passed");

$storage1 = WebGUI::Storage->get($session, 'foobar');

is( ref $storage1, "WebGUI::Storage", "storage will accept non GUID arguments");

is( $storage1->getErrorCount, 0, "No errors during path creation");

is( $storage1->getLastError, undef, "No errors during path creation");

my $storageDir1 = join '/', $uploadDir, 'fo', 'ob', 'foobar';

is ($storageDir1, $storage1->getPath, 'path calculated correctly');

ok( (-e $storageDir1 and -d $storageDir1), "Storage location created and is a directory");

$storage1->delete;

ok( !(-e $storageDir1), "Storage location deleted");

undef $storage1;

$storage1 = WebGUI::Storage->get($session, 'notAGUID');
my $storage2 = WebGUI::Storage->get($session, 'notAGoodId');

ok(! $storage2->getErrorCount, 'No errors due to a shared common root');

ok( (-e $storage1->getPath and -d $storage1->getPath), "Storage location 1 created and is a directory");
ok( (-e $storage2->getPath and -d $storage2->getPath), "Storage location 2 created and is a directory");

$storage1->delete;
undef $storage1;

ok( (-e $storage2->getPath and -d $storage2->getPath), "Storage location 2 not touched");

$storage2->delete;

my $storageDir2 = join '/', $uploadDir, 'no';

ok (!(-e $storageDir2), "Storage2 cleaned up properly");

undef $storage2;

my $storage3 = WebGUI::Storage->get($session, 'bad');

is( $storage3->getErrorCount, 1, 'Error during creation of object due to short GUID');

my $dir3 = join '/', $uploadDir, 'ba';

ok(!(-e $dir3 and -d $dir3), 'No directories created for short guid');

TODO: {
	local $TODO = "Tests to make later";
	ok(0, 'Create object with 1 character GUID');
	ok(0, 'Add a file to the storage location via addFileFromScalar');
	ok(0, 'getSize works correctly');
	ok(0, 'Add a file to the storage location via addFileFromFilesystem');
	ok(0, 'Add a file to the storage location via addFileFromHashref');
	ok(0, 'Test renaming of files inside of a storage location');
}

END {
	foreach my $stor ($storage1, $storage2, $storage3) {
		ref $stor eq "WebGUI::Storage" and $stor->delete;
	}
}
