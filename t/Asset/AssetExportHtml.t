# vim:syntax=perl
#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#------------------------------------------------------------------

#  These tests are for the shiny rewritten export functionality. it tries
#  really hard to test every permutation of the code.

use FindBin;
use strict;
use lib "$FindBin::Bin/../lib";
use Test::More;
use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::PseudoRequest;

use WebGUI::Session;
use WebGUI::Asset;
use WebGUI::Exception;

use Cwd;
use Exception::Class;
use File::Path;
use File::Temp qw/tempfile tempdir/;
use Path::Class;
use Test::Deep;

#----------------------------------------------------------------------------
# Init
my $session             = WebGUI::Test->session;

#----------------------------------------------------------------------------
# Tests

my $configExportPath = $session->config->get('exportPath');

my $testRan = 1;

if ($configExportPath) {
    plan tests => 145;        # Increment this number for each test you create
}
else {
    $testRan = 0;
    plan skip_all => 'No exportPath in the config file';
}

#----------------------------------------------------------------------------
# exportCheckPath()


my $e;

# ensure exportCheckPath barfs if not given a session as its first argument.
eval { WebGUI::Asset->exportCheckPath() };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidObject', 'exportCheckPath tests that its argument is a WebGUI::Session');
cmp_deeply(
    $e,
    methods(
        error       => "first param to exportCheckPath must be a WebGUI::Session",
    ),
    "exportCheckPath tests that its argument is a WebGUI::Session"
);

# need to test that exportCheckPath() barfs on an undefined exportPath. To do
# this, we need to make sure that exportPath is undefined. However, completely
# wiping out someone's exportPath setting isn't precisely the paragon of
# politeness. Take a backup of the current exportPath before undefining it.

my $originalExportPath = $session->config->get('exportPath');
my $config = $session->config;
$config->delete('exportPath');

eval { WebGUI::Asset->exportCheckPath($session) };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error', "exportCheckPath throws if exportPath isn't defined");
cmp_deeply(
    $e,
    methods(
        error       => 'exportPath must be defined and not ""',
    ),
    "exportCheckPath throws if exportPath isn't defined"
);

# we'll restore the original exportPath setting after performing these tests.
# for now, we need a controlled environment.

# first, let's test a directory to which we hopefully cannot write.
my $rootDirectory = Path::Class::Dir->new('');
$config->set('exportPath', $rootDirectory->stringify);

eval { WebGUI::Asset->exportCheckPath($session) };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error', "exportCheckPath throws if we can't access the exportPath");
cmp_deeply(
    $e,
    methods(
        error       => "can't access $rootDirectory",
    ),
    "exportCheckPath throws if we can't access the exportPath"
);

# next, let's set the exportPath to a non-directory file and make sure that it explodes.
my $exportPathFile;
(undef, $exportPathFile)          = tempfile('webguiXXXXX', UNLINK => 1);
$config->set('exportPath', $exportPathFile); 

eval { WebGUI::Asset->exportCheckPath($session) };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error', "exportCheckPath throws if exportPath is a file rather than a directory");
cmp_deeply(
    $e,
    methods(
        error       => "$exportPathFile isn't a directory",
    ),
    "exportCheckPath throws if exportPath is a file rather than a directory"
);

# next, let's find a directory to which we can write, but change it so that we
# *can't* write to it. exportCheckPath will try to create the exportPath if it's
# a subdirectory of a path that exists, so let's make sure this exception works.

my $tempDirectory           = tempdir('webguiXXXXX', CLEANUP => 1);
my $inaccessibleDirectory   = Path::Class::Dir->new($tempDirectory, 'unwritable');
chmod 0000, $tempDirectory; 
$config->set('exportPath', $inaccessibleDirectory->stringify); 

eval { WebGUI::Asset->exportCheckPath($session) };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error', "exportCheckPath throws if it can't create the directory it needs");
cmp_deeply(
    $e,
    methods(
        error       => "can't create exportPath $inaccessibleDirectory",
    ),
    "exportCheckPath throws if it can't create the directory it needs"
);

# we're finished making sure that the code explodes on bad stuff, so let's make
# sure that it really works when it's really supposed to.
my $returnCode;

# first, let's try the simplest route: a directory that we know exists, that we
# know we can write to. we already have a directory we know we can write to
# (created above as a temporary directory), so let's change its permissions back
# to something sane and then test to make sure it works.

chmod 0755, $tempDirectory; # $inaccessibleDirectory is now accessible
my $accessibleDirectory = $inaccessibleDirectory;
$config->set('exportPath', $tempDirectory); 


eval { $returnCode = WebGUI::Asset->exportCheckPath($session) };
is($@, '', "exportCheckPath with valid path lives");
is($returnCode, 1, "exportCheckPath returns true value");

# now, let's try a directory to which we know we have access, but a path within
# it that doesn't exist.

$config->set('exportPath', $accessibleDirectory->stringify); # now accessible!

eval { $returnCode = WebGUI::Asset->exportCheckPath($session) };
is($@, '', "exportCheckPath creating subdirectory lives");
is($returnCode, 1, "exportCheckPath creating subdirectory returns true value");
is(-d $accessibleDirectory, 1, "exportCheckPath creating subdirectory actually creates said subdirectory");

#----------------------------------------------------------------------------
# exportCheckExportable()

my $isExportable;
# simple test first. the asset we're checking isn't exportable. should of course return 0.
my $home = WebGUI::Asset->newByUrl($session, '/home');
$home->update({ isExportable => 0 });
$isExportable = $home->exportCheckExportable;
is($isExportable, 0, "exportCheckExportable simple check without lineage for non-exportable asset returns 0");

# next, make the parent exportable, but the child not exportable. test that this returns 0 as well.
$home->update({ isExportable => 1 });
my $gettingStarted = WebGUI::Asset->newByUrl($session, '/getting_started');
$gettingStarted->update({ isExportable => 0 });
$isExportable = $gettingStarted->exportCheckExportable;
is($isExportable, 0, "exportCheckExportable nonexportable asset, exportable parent returns 0");

# next, make both non-exportable. test that this returns 0.
$home->update({ isExportable => 0 });
$isExportable = $gettingStarted->exportCheckExportable;
is($isExportable, 0, "exportCheckExportable nonexportable asset, nonexportable parent returns 0");

# go another level deeper. asset, parent, grandparent.
my $grandChild = WebGUI::Asset->newByUrl($session, '/getting_started/getting-started');

# make it not exportable, but both parents are. still returning 0.
$grandChild->update({ isExportable => 0 });
$home->update({ isExportable => 1 });
$gettingStarted->update({ isExportable => 1 });
$isExportable = $grandChild->exportCheckExportable;
is($isExportable, 0, "exportCheckExportable nonexportable asset, exportable parent and grandparent returns 0");

# make parent not exportable. still returning 0.
$gettingStarted->update({ isExportable => 0 });
$isExportable = $grandChild->exportCheckExportable;
is($isExportable, 0, "exportCheckExportable nonexportable asset, parent, exportable grandparent returns 0");

# switch: exportable parent, nonexportable grandparent. still 0.
$gettingStarted->update({ isExportable => 1 });
$home->update({ isExportable => 0 });
$isExportable = $grandChild->exportCheckExportable;
is($isExportable, 0, "exportCheckExportable nonexportable asset, grandparent, exportable parent returns 0");

# none of asset, parent, grandparent are exportable. still 0.
$home->update({ isExportable => 0 });
$gettingStarted->update({ isExportable => 0 });
$isExportable = $grandChild->exportCheckExportable;
is($isExportable, 0, "exportCheckExportable nonexportable asset, grandparent, parent returns 0");

# finally, make everything exportable. make sure each one returns 1.
$home->update({ isExportable => 1 });
$gettingStarted->update({ isExportable => 1 });
$grandChild->update({ isExportable => 1 });

$isExportable = $home->exportCheckExportable;
is($isExportable, 1, "exportCheckExportable simple check without lineage for exportable asset returns 1");

$isExportable = $gettingStarted->exportCheckExportable;
is($isExportable, 1, "exportCheckExportable exportable asset, parent returns 1");

$isExportable = $grandChild->exportCheckExportable;
is($isExportable, 1, "exportCheckExportable exportable asset, parent, grandparent returns 1");

#----------------------------------------------------------------------------
# exportGetUrlAsPath()

# store the exportPath for future reference
my $exportPath = $config->get('exportPath');

my $litmus;
# start with something simple: export the root URL.
my $homeAsPath = $home->exportGetUrlAsPath('index.html');
$litmus = Path::Class::File->new($exportPath, $home->getUrl, 'index.html');
isa_ok($homeAsPath, 'Path::Class::File', 'exportGetUrlAsPath returns a Path::Class::File object');
is($homeAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, "exportGetUrlAsPath works for root directory");

# make sure that 'index.html' is the default file name if none given.
$homeAsPath = $home->exportGetUrlAsPath();
$litmus = Path::Class::File->new($exportPath, $home->getUrl, 'index.html');
isa_ok($homeAsPath, 'Path::Class::File', 'exportGetUrlAsPath without index file returns a Path::Class::File object');
is($homeAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, "exportGetUrlAsPath without index file works for root directory");

# let's go down a level. add a directory.
my $gsAsPath = $gettingStarted->exportGetUrlAsPath('index.html');
$litmus = Path::Class::File->new($exportPath, $gettingStarted->getUrl, 'index.html');
isa_ok($gsAsPath, 'Path::Class::File', 'exportGetUrlAsPath for getting_started returns a Path::Class::File object');
is($gsAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, "exportGetUrlAsPath for getting_started works for root directory");

# ensure 'index.html' works for a single directory.
$gsAsPath = $gettingStarted->exportGetUrlAsPath();
isa_ok($gsAsPath, 'Path::Class::File', 'exportGetUrlAsPath for getting_started without index file returns a Path::Class::File object');
is($gsAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, "exportGetUrlAsPath for getting_started without index file works for root directory");

# down another level.
my $gcAsPath = $grandChild->exportGetUrlAsPath('index.html');
$litmus = Path::Class::File->new($exportPath, $grandChild->getUrl, 'index.html');
isa_ok($gcAsPath, 'Path::Class::File', 'exportGetUrlAsPath for grandchild returns a Path::Class::File object');
is($gcAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, "exportGetUrlAsPath for grandchild works for root directory");

# without index.html
my $gcAsPath = $grandChild->exportGetUrlAsPath();
$litmus = Path::Class::File->new($exportPath, $grandChild->getUrl, 'index.html');
isa_ok($gcAsPath, 'Path::Class::File', 'exportGetUrlAsPath for grandchild without index file returns a Path::Class::File object');
is($gcAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, "exportGetUrlAsPath for grandchild without index file works for root directory");

# now let's get tricky and test different file extensions
my $storage = WebGUI::Storage->create($session);
my $filename = 'somePerlFile_pl.txt';
$storage->addFileFromScalar($filename, $filename);
$session->user({userId=>3});
my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Asset Export Test"});
my $properties = {
    #     '1234567890123456789012'
    id          => 'ExportTest000000000001',
    title       => 'Export Test',
    className   => 'WebGUI::Asset::File',
    url         => 'export-test.pl',
};
my $defaultAsset = WebGUI::Asset->getDefault($session);
my $asset = $defaultAsset->addChild($properties, $properties->{id});
$asset->update({
        storageId => $storage->getId,
        filename => $filename,
});

my $fileAsPath = $asset->exportGetUrlAsPath('index.html');

# .pl files are recognised by apache, so are passed through as-is
$litmus = Path::Class::File->new($exportPath, $asset->getUrl);
isa_ok($fileAsPath, 'Path::Class::File', 'exportGetUrlAsPath for perl file returns a Path::Class::File object');
is($fileAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, 'exportGetUrlAsPath for perl file works');

# test a different extension, the .foobar extension
$storage = WebGUI::Storage->create($session);
$filename = 'someFoobarFile.foobar';
$storage->addFileFromScalar($filename, $filename);
$properties = {
    id          => 'ExportTest000000000002',
    title       => 'Export Test',
    className   => 'WebGUI::Asset::File',
    url         => 'export-test.foobar',
};
$asset = $defaultAsset->addChild($properties, $properties->{id});
$asset->update({
        storageId   => $storage->getId,
        filename    => $filename,
});

$fileAsPath = $asset->exportGetUrlAsPath('index.html');
# not recognised by apache, so it'll add an index.html, make sure it does so
$litmus = Path::Class::File->new($exportPath, $asset->getUrl, 'index.html');
isa_ok($fileAsPath, 'Path::Class::File', 'exportGetUrlAsPath for plain file returns a Path::Class::File object');
is($fileAsPath->absolute($exportPath)->stringify, $litmus->absolute($exportPath)->stringify, 'exportGetUrlAsPath for plain file works');

#----------------------------------------------------------------------------
# exportWriteFile()

# we'll be writing real on-disk files and directories for these tests. do our
# level best at cleaning up after ourselves. this is taken care of in the END
# block via rmtree().
# ideally, exportCheckPath will have been called before exportWriteFile(), but
# we can't be certain of that. this means that we may not have permission to
# write to the exportPath, or the exportPath may not even exist. there's also a
# race condition that exists between the time exportCheckPath() ran and the
# time exportWriteFile() attempts to write files to disk. it's pathological,
# yes, but I'm really not interested in tracking down the kinds of bugs that
# these race conditions can create. so exportWriteFile() will check for the
# actual ability to make all of the paths it requires and for the ability to
# write the files it needs.
# so, let's get started with a bad export path. set it to something that
# shouldn't exist first. this should try to create it. rather than testing two
# parts of the code (the nonexistent directory check and the creation success
# check) at once, let's make it something that we *can* create. probably the
# best way to generate something that we can guarantee doesn't exist is to use
# a GUID.

# we need to be tricky here and call code in wG proper which calls www_ methods
# even though we don't have access to modperl. the following hack lets us do
# that.
$session->http->{_http}->{noHeader} = 1;

$session->user( { userId => 1 } );
my $content;
my $guid = $session->id->generate;
my $guidPath = Path::Class::Dir->new($config->get('uploadsPath'), 'temp', $guid);
$config->set('exportPath', $guidPath->absolute->stringify);
eval { $home->exportWriteFile() };
is($@, '', "exportWriteFile works when creating exportPath");

# ensure that the file was actually written
ok(-e $home->exportGetUrlAsPath->absolute->stringify, "exportWriteFile actually writes the file when creating exportPath");

# now make sure that it contains the correct content
eval { $content = WebGUI::Test->getPage($home, 'exportHtml_view', { user => WebGUI::User->new($session, 1) } ) };
is(scalar $home->exportGetUrlAsPath->absolute->slurp, $content, "exportWriteFile puts the correct contents in exported home");


# now that we know that creating the export directory works, let's make sure
# that creating it, when we have no permission to do so, throws an exception.

# first, set the exportPath to a *sub*directory of $guid to ensure that it
# doesn't already exist, and then deny ourselves permissions to it.
my $unwritablePath = Path::Class::Dir->new($config->get('uploadsPath'), 'temp', $guid, $guid);
chmod 0000, $guidPath->stringify;
$config->set('exportPath', $unwritablePath->absolute->stringify);

$session->http->{_http}->{noHeader} = 1;
eval { $home->exportWriteFile() };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error', "exportWriteFile throws if it can't create the export path");
cmp_deeply(
    $e,
    methods(
        error       => "can't create exportPath $unwritablePath",
    ),
    "exportWriteFile throws if it can't create the export path"
);

# the exception was thrown, but make sure that the file also wasn't written
# can't call exportGetUrlAsPath on $home right now, since the path is
# inaccessible and exportGetUrlAsPath calls exportCheckPath which throws an
# exception. therefore, specify this single specific case specifically for the
# sake of the test.
ok(!-e Path::Class::File->new($unwritablePath, 'home', 'index.html')->absolute->stringify, "exportWriteFile does not write the file when it can't create the exportPath");

# let's go a level deeper
# but reset the exportPath first
$config->set('exportPath', $guidPath->absolute->stringify);

# and clean up the temp directory
chmod 0755, $guidPath->stringify;
$unwritablePath->remove;

$session->http->{_http}->{noHeader} = 1;
eval { $gettingStarted->exportWriteFile() };
is($@, '', "exportWriteFile works for getting_started");

# ensure that the file was actually written
ok(-e $gettingStarted->exportGetUrlAsPath->absolute->stringify, "exportWriteFile actually writes the getting_started file");

# verify it has the correct contents
eval { $content = WebGUI::Test->getPage($gettingStarted, 'exportHtml_view') };
is(scalar $gettingStarted->exportGetUrlAsPath->absolute->slurp, $content, "exportWriteFile puts the correct contents in exported getting_started");

# and one more level. remove the export path to ensure directory creation keeps
# working.
$guidPath->rmtree;

$session->http->{_http}->{noHeader} = 1;
$session->user( { userId => 1 } );
eval { $grandChild->exportWriteFile() };
is($@, '', "exportWriteFile works for grandchild");

# ensure that the file was written
ok(-e $grandChild->exportGetUrlAsPath->absolute->stringify, "exportWriteFile actually writes the grandchild file");

# finally, check its contents
eval { $content = WebGUI::Test->getPage($grandChild, 'exportHtml_view', { user => WebGUI::User->new($session, 1) }) };
is(scalar $grandChild->exportGetUrlAsPath->absolute->slurp, $content, "exportWriteFile puts correct content in exported grandchild");

# test different extensions
$guidPath->rmtree;
$asset = WebGUI::Asset->new($session, 'ExportTest000000000001');
$session->http->{_http}->{noHeader} = 1;
eval { $asset->exportWriteFile() };
is($@, '', 'exportWriteFile for perl file works');

ok(-e $asset->exportGetUrlAsPath->absolute->stringify, "exportWriteFile actually writes the perl file");

eval { $content = WebGUI::Test->getPage($asset, 'exportHtml_view') };
is(scalar $asset->exportGetUrlAsPath->absolute->slurp, $content, "exportWriteFile puts correct content in exported perl file");

$guidPath->rmtree;
$asset = WebGUI::Asset->new($session, 'ExportTest000000000002');
eval { $asset->exportWriteFile() };
is($@, '', 'exportWriteFile for plain file works');

ok(-e $asset->exportGetUrlAsPath->absolute->stringify, "exportWriteFile actuall writes the plain file");

eval { $content = WebGUI::Test->getPage($asset, 'exportHtml_view') };
is(scalar $asset->exportGetUrlAsPath->absolute->slurp, $content, "exportWriteFile puts correct content in exported plain file");

$guidPath->rmtree;

# next, make sure an exception is thrown if the user we're exporting as doesn't
# have permission to view the page that we want to export. by default, there's
# nothing actually in a stock WebGUI installation that any particular user
# isn't allowed to see. this means that we'll need to temporarily change the
# permissions on something.
$home->update( { groupIdView => 3 } ); # admins
$session->http->{_http}->{noHeader} = 1;
eval { $home->exportWriteFile() }; 
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error', "exportWriteFile throws when user can't view asset");
cmp_deeply(
    $e,
    methods(
        error       => "user can't view asset at " . $home->getUrl . " to export it",
    ),
    "exportWriteFile throws when user can't view asset"
);

# now that we're sure that it throws the correct exception, make sure there's
# no directory or file written
ok(!-e $home->exportGetUrlAsPath->absolute->stringify, "exportWriteFile doesn't write file when user can't view asset");
ok(!-e $home->exportGetUrlAsPath->absolute->parent, "exportWriteFile doesn't write directory when user can't view asset");

# undo our viewing changes
$home->update( { groupIdView => 7 } ); # everyone
$guidPath->rmtree;

#----------------------------------------------------------------------------
# exportSymlinkExtrasUploads()

# another class method. need to make sure it knows to check its first parameter
# for whether it's actually a WebGUI::Session. we don't need to fiddle with
# different paths or the permissions on them because if those paths are broken,
# other parts of the site will be utterly b0rked.

# ensure it checks whether its first argument is a session object

eval { WebGUI::Asset->exportSymlinkExtrasUploads };
$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidObject', 'exportSymlinkExtrasUploads without session object throws');
cmp_deeply(
    $e,
    methods(
        error       => 'first param to exportSymlinkExtrasUploads must be a WebGUI::Session',
    ),
    'exportSymlinkExtrasUploads without session object throws',
);

# call it with something that isn't a session
eval { WebGUI::Asset->exportSymlinkExtrasUploads('srsly? no wai!') };
$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidObject', 'exportSymlinkExtrasUploads called with memetic parameter throws');
cmp_deeply(
    $e,
    methods(
        error       => 'first param to exportSymlinkExtrasUploads must be a WebGUI::Session',
    ),
    'exportSymlinkExtrasUploads called with memetic parameter throws',
);


# now test that it works as it should, when it should
#$config->set('exportPath', $originalExportPath);
#$exportPath             = Path::Class::Dir->new($originalExportPath);
$exportPath             = $config->get('exportPath');
my $extrasPath          = $config->get('extrasPath');
my $extrasUrl           = $config->get('extrasURL');
my $uploadsPath         = $config->get('uploadsPath');
my $uploadsUrl          = $config->get('uploadsURL');

eval { WebGUI::Asset->exportSymlinkExtrasUploads($session) };

# make sure it doesn't throw any exceptions
is($@, '', 'exportSymlinkExtrasUploads works when it should');
my $extrasSymlink       = Path::Class::File->new($exportPath, $extrasUrl);
my $uploadsSymlink      = Path::Class::File->new($exportPath, $uploadsUrl);
ok(-e $extrasSymlink->absolute->stringify, "exportSymlinkExtrasUploads writes extras symlink");
is($extrasPath, readlink $extrasSymlink->absolute->stringify, "exportSymlinkExtrasUploads extras symlink points to right place");
ok(-e $uploadsSymlink->absolute->stringify, "exportSymlinkExtrasUploads writes uploads symlink");
is($uploadsPath, readlink $uploadsSymlink->absolute->stringify, "exportSymlinkExtrasUploads uploads symlink points to right place");

#----------------------------------------------------------------------------
# exportSymlinkRoot

# This class method functions almost exactly the same as
# exportSymlinkExtrasUploads except that it puts a symlink in a diferent place.
# test that it verifies its parameter is a session object and that it does what
# it's supposed to do.

eval { WebGUI::Asset->exportSymlinkRoot };
$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidObject', 'exportSymlinkRoot without session object throws');
cmp_deeply($e,
    methods(
        error       => 'first param to exportSymlinkRoot must be a WebGUI::Session'
    ),
    'exportSymlinkRoot without session object throws',
);

# okay, so calling it without any parameters breaks. let's call it with
# something nonsensical
eval { WebGUI::Asset->exportSymlinkRoot('srsly! wai!') };
$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidObject', 'exportSymlinkRoot called with memetic parameter throws');
cmp_deeply($e,
    methods(
        error       => 'first param to exportSymlinkRoot must be a WebGUI::Session'
    ),
    'exportSymlinkRoot called with memetic parameter throws',
);

# we need to make sure the code validates other parameters as well
eval { WebGUI::Asset->exportSymlinkRoot($session) };
$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidParam', 'exportSymlinkRoot called without a default asset throws');
cmp_deeply(
    $e,
    methods(
        error       => 'second param to exportSymlinkRoot must be the default asset',
        param       => undef,
    ),
    'exportSymlinkRoot called without a default asset throws',
);

# give it something not a default asset
eval { WebGUI::Asset->exportSymlinkRoot($session, "wai. can't be!") };
$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidParam', 'exportSymlinkRoot called with memetic default asset throws');
cmp_deeply(
    $e,
    methods(
        error       => 'second param to exportSymlinkRoot must be the default asset',
        param       => "wai. can't be!",
    ),
    'exportSymlinkRoot called with memetic default asset throws',
);

# it breaks when it's supposed to, so let's make sure it works when it's
# supposed to. first, leave out the index parameter to ensure it sets up the
# default correctly.
$home->exportWriteFile;
my $symlinkedRoot   = Path::Class::File->new($exportPath, 'index.html');
my $homePath        = $home->exportGetUrlAsPath;
eval { WebGUI::Asset->exportSymlinkRoot($session, $home, '', 1) };
is($@, '', 'exportSymlinkRoot works when it should');
ok(-e $symlinkedRoot->stringify, 'exportSymlinkRoot sets up link correctly and supplies default index');
is($homePath, readlink $symlinkedRoot->stringify, 'exportSymlinkRoot sets up link correctly and supplies default index');
unlink $symlinkedRoot->stringify;


# give it an index and ensure it works
eval { WebGUI::Asset->exportSymlinkRoot($session, $home, 'index.html', 1) };
is($@, '', 'exportSymlinkRoot works when it should');
ok(-e $symlinkedRoot->stringify, 'exportSymlinkRoot sets up link correctly and supplies default index');
is($homePath, readlink $symlinkedRoot->stringify, 'exportSymlinkRoot sets up link correctly and supplies default index');
unlink $symlinkedRoot->stringify;


#----------------------------------------------------------------------------
# exportGetDescendants()

# clear these out now so that they don't interfere with the lineage tests
$asset = WebGUI::Asset->new($session, 'ExportTest000000000001');
$asset->purge;
$asset = WebGUI::Asset->new($session, 'ExportTest000000000002');
$asset->purge;

$session->user( { userId => 1 } );
my $descendants;
# next, make sure that we get the right list of assets to export.
my $homeDescendants = $home->getLineage( ['self', 'descendants'], {
        endingLineageLength => $home->getLineageLength + 99,
        orderByClause       => 'assetData.url DESC',
    }
);
$descendants = $home->exportGetDescendants( WebGUI::User->new($session, 1), 99 );

cmp_deeply($descendants, $homeDescendants, "exportGetDescendants returns correct data for home");

my $gsDescendants = $gettingStarted->getLineage( ['self', 'descendants'], {
        endingLineageLength => $gettingStarted->getLineageLength + 99,
        orderByClause       => 'assetData.url DESC',
    }
);
$descendants = $gettingStarted->exportGetDescendants( WebGUI::User->new($session, 1), 99 );

cmp_deeply($descendants, $gsDescendants, "exportGetDescendants returns correct data for getting-started");

my $gcDescendants = $grandChild->getLineage( ['self', 'descendants'], {
        endingLineageLength => $grandChild->getLineageLength + 99,
        orderByClause       => 'assetData.url DESC',
    }
);
$descendants = $grandChild->exportGetDescendants( WebGUI::User->new($session, 1), 99 );

cmp_deeply($descendants, $gcDescendants, "exportGetDescendants returns correct data for getting-started");

# finally, ensure that calling exportGetDescendants without a userID throws an exception.

eval { $home->exportGetDescendants };

$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidObject', 'exportGetDescendants called without a user object throws');
cmp_deeply(
    $e,
    methods(
        expected    => 'WebGUI::User',
        got         => '',
        error       => 'Need a WebGUI::User object',
        param       => undef,
    ),
    "exportGetDescendants called without a user object throws",
);

# make sure calling exportGetDescendants without a depth throws an exception.

eval { $home->exportGetDescendants( WebGUI::User->new($session, 1) ) };
$e = Exception::Class->caught;
isa_ok($e, 'WebGUI::Error::InvalidParam', 'exportGetDescendants called without a depth throws');
cmp_deeply(
    $e,
    methods(
        error       => 'Need a depth',
        param       => undef,
    ),
    "exportGetDescendants called without a depth throws",
);

$session->user( { userId => 3 } );

#----------------------------------------------------------------------------
# exportAsHtml

# the big one. exportAsHtml is the central logic hub for all of the methods
# tested above. we don't need to test that the other methods work; that's what
# the other 70 tests above do. what we need to do is ensure that exportAsHtml:
#   * processes its arguments correctly
#   * calls the right methods in the right order
#   * handles any exceptions
#   * produces correct output
#   * fails if it needs to fail
# in other words, we need to test that the ultimate results of calling
# exportAsHtml are what they should be, given the inputs we provide.
my (@createdFiles, @shouldExist, $success, $message);
my $exportPath = Path::Class::Dir->new($session->config->get('exportPath'));

# first things first. let's make sure the code checks for the proper arguments.
# quiet is optional, so don't test that. userId is a bit smart and will take
# either a numeric userId or a real WebGUI::User object. everything else has a
# default. exportAsHtml is supposed to catch exceptions, not throw them, so
# we'll be testing the return values rather than for an exception.

($success, $message) = $home->exportAsHtml;
is($success, 0, "exportAsHtml returns 0 when not given a userId");
is($message, "need a userId parameter", "exportAsHtml returns correct message when not given a userId");

# omitting the userId works, so let's give it a bogus userId
($success, $message) = $home->exportAsHtml( { userId => '<rizen> perlDreamer is a 500 lb test mandating gorilla' } );
is($success, 0, "exportAsHtml returns 0 when given a bogus (but nonetheless funny) userId");
is($message, "'<rizen> perlDreamer is a 500 lb test mandating gorilla' is not a valid userId", "exportAsHtml returns correct message when given a bogus (but nonetheless funny) userId");

# checking userId works, so check extrasUploadAction next.
($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99, extrasUploadAction => 'o hai' } );
is($success, 0, "exportAsHtml returns 0 when given bogus, memetic extrasUploadAction parameter");
is($message, "'o hai' is not a valid extrasUploadAction", "exportAsHtml returns 0 when given bogus, memetic extrasUploadAction parameter");

# rootUrlAction
($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99, rootUrlAction => 'NO U' } );
is($success, 0, "exportAsHtml returns 0 when given bogus, memetic rootUrlAction parameter");
is($message, "'NO U' is not a valid rootUrlAction", "exportAsHtml returns correct message when given bogus, memetic extrasUploadAction parameter");

# finally, depth
($success, $message) = $home->exportAsHtml( { userId => 3 } );
is($success, 0, "exportAsHtml returns 0 when not given depth");
is($message, "need a depth", "exportAsHtml returns correct message when not given a depth");

($success, $message) = $home->exportAsHtml( { userId => 3, depth => 'orly? yarly!' } );
is($success, 0, "exportAsHtml returns 0 when given bogus, memetic depth");
is($message, "'orly? yarly!' is not a valid depth", "exportAsHtml returns correct message when given bogus, memetic depth");

# next, let's make sure some simple exports work. export 'home', but clean up
# the exportPath first to make sure there are no residuals from the tests
# above.
$exportPath->rmtree;
($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99, quiet => 1 } );

# list of files that should exist. obtained by running previous known working
# export function on a full stock asset tree
@createdFiles = (
    [ qw/ getting_started getting-started index.html /],
    [ qw/ getting_started getting-started-part2 index.html /],
    [ qw/ getting_started index.html /],
    [ qw/ home ad index.html /],
    [ qw/ home ad2 index.html /],
    [ qw/ home index.html /],
    [ qw/ home key-benefits index.html /],
    [ qw/ home welcome index.html /],
    [ qw/ site_map index.html /],
    [ qw/ site_map site_map index.html /],
    [ qw/ tell_a_friend index.html /],
    [ qw/ tell_a_friend tell_a_friend index.html /],
    [ qw/ the_latest_news index.html /],
    [ qw/ the_latest_news the_latest_news index.html /],
    [ qw/ yns docs index.html /],
    [ qw/ yns experts index.html /],
    [ qw/ yns features index.html /],
    [ qw/ yns hosting index.html /],
    [ qw/ yns promotion index.html /],
    [ qw/ yns style index.html /],
    [ qw/ yns support index.html /],
    [ qw/ yns translated index.html /],
    [ qw/ your_next_step index.html /],
);

# turn them into Path::Class::File objects
my @shouldExist = map { Path::Class::File->new($exportPath, @{$_})->absolute->stringify } @createdFiles;

# ensure that the files that should exist do exist
my @doExist;
$exportPath->recurse( callback => sub { my $o = shift; $o->is_dir ? return : push @doExist, $o->absolute->stringify } );
cmp_deeply(sort @shouldExist, sort @doExist, "exportAsHtml on home writes correct files");
is($success, 1, "exportAsHtml on home returns true");
like($message, qr/Exported 23 pages/, "exportAsHtml on home returns correct message");

$exportPath->rmtree;
@doExist = ();

# previous tests ensure that the contents of the exported files are right. so
# let's go a level deeper and ensure that the right files are present.
($success, $message) = $gettingStarted->exportAsHtml( { userId => 3, depth => 99, quiet => 1 } );
@createdFiles = (
    [ qw/ getting_started getting-started index.html /],
    [ qw/ getting_started getting-started-part2 index.html /],
    [ qw/ getting_started index.html /],
    [ qw/ home ad2 index.html /], # I have no idea why but ad2 is a descendant of getting-started
);
@shouldExist = map { Path::Class::File->new($exportPath, @{$_})->absolute->stringify } @createdFiles;

$exportPath->recurse( callback => sub { my $o = shift; $o->is_dir ? return : push @doExist, $o->absolute->stringify } );
cmp_deeply(sort @shouldExist, sort @doExist, "exportAsHtml on getting-started writes correct files");
is($success, 1, "exportAsHtml on getting-started returns true");
like($message, qr/Exported 4 pages/, "exportAsHtml on getting-started returns correct message");

$exportPath->rmtree;
@doExist = ();

# test the grandchild.
($success, $message) = $grandChild->exportAsHtml( { userId => 3, depth => 99, quiet => 1 } );
@createdFiles = (
    [ qw/ getting_started getting-started index.html /],
);

@shouldExist = map { Path::Class::File->new($exportPath, @{$_})->absolute->stringify } @createdFiles;

$exportPath->recurse( callback => sub { my $o = shift; $o->is_dir ? return : push @doExist, $o->absolute->stringify } );
cmp_deeply(sort @shouldExist, sort @doExist, "exportAsHtml on grandchild writes correct files");
is($success, 1, "exportAsHtml on grandchild returns true");
like($message, qr/Exported 1 pages/, "exportAsHtml on grandchild returns correct message");

$exportPath->rmtree;
@doExist = ();

# fiddle with the isExportable setting and make sure appropriate files are
# written 
$home->update({ isExportable => 0 });
($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99, quiet => 1 } );

@shouldExist = ();
is(@shouldExist, @doExist, "exportAsHtml on nonexportable home doesn't write anything");
is($success, 1, "exportAsHtml on nonexportable home returns true (but doesn't do anything)");
like($message, qr/Exported 0 pages/, "exportAsHtml on nonexportable home returns correct message");

# restore the original setting
$home->update({ isExportable => 1 });

# go a level deeper

# shouldn't be necessary if the tests pass, but be nice and clean up after ourselves
$exportPath->rmtree; 

@doExist = ();
$gettingStarted->update({ isExportable => 0 });

($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99, quiet => 1 } );

# since getting-started isn't exportable, it shouldn't be written. remove it
# and its descendants from the list.
@createdFiles = (
    [ qw/ home ad index.html /],
    #[ qw/ home ad2 index.html /], # I have no idea why but ad2 is a descendant of getting-started
    [ qw/ home index.html /],
    [ qw/ home key-benefits index.html /],
    [ qw/ home welcome index.html /],
    [ qw/ site_map index.html /],
    [ qw/ site_map site_map index.html /],
    [ qw/ tell_a_friend index.html /],
    [ qw/ tell_a_friend tell_a_friend index.html /],
    [ qw/ the_latest_news index.html /],
    [ qw/ the_latest_news the_latest_news index.html /],
    [ qw/ yns docs index.html /],
    [ qw/ yns experts index.html /],
    [ qw/ yns features index.html /],
    [ qw/ yns hosting index.html /],
    [ qw/ yns promotion index.html /],
    [ qw/ yns style index.html /],
    [ qw/ yns support index.html /],
    [ qw/ yns translated index.html /],
    [ qw/ your_next_step index.html /],
);
@shouldExist = map { Path::Class::File->new($exportPath, @{$_})->absolute->stringify } @createdFiles;

$exportPath->recurse( callback => sub { my $o = shift; $o->is_dir ? return : push @doExist, $o->absolute->stringify } );
cmp_deeply(sort @shouldExist, sort @doExist, "exportAsHtml on home with non-exportable getting-started writes correct files");
is($success, 1, "exportAsHtml on home with non-exportable getting-started returns true");
like($message, qr/Exported 19 pages/, "exportAsHtml on home with non-exportable getting-started returns correct message");

# restore the original setting
$gettingStarted->update({ isExportable => 1 });

$exportPath->rmtree;
@doExist = ();

# now that we're sure that it works when everything is set up properly, let's
# test the code under inclement circumstances. let's cover each method that
# exportAsHtml calls in turn. we'll make sure it catches each exception that we
# can generate here. exceptions shouldn't propagate to the www_ methods. they
# should be caught before that point and a message returned to the user. the
# best way to do these is to mimic the order that they're tested above. we
# can't test the invalid argument exceptions, though, because the environment
# for those tests is the actual code of the exportAsHtml method. however,
# everything that's external to the code of the method itself we can test, like
# an unset exportPath. we'll test a couple of things. note that these
# exceptions should be *caught* by exportAsHtml, so the code needs to live.
# also, we need to test that appropriate status messages based on those
# exceptions are returned to the calling method. given the above, we'll test
# the following situations and verify that the following things occur properly:
#  checkExportPath:
#   1. lack of defined exportPath
#   2. inaccessible exportPath
#   3. exportPath is a file, not a directory
#   4. can't create path for whatever reason
#  exportCheckExportable:
#   doesn't throw exceptions
#  exportWriteFile:
#   1. user can't view asset
#  exportGetDescendants:
#   doesn't throw exceptions we can test (they're all method usage-related)

# let's start with an invalid exportPath
$config->delete('exportPath');

# undefined exportPath
eval { ($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99 } ) };
is($@, '', "exportAsHtml catches undefined exportPath exception");
is($success, 0, "exportAsHtml returns 0 for undefined exportPath");
is($message, 'exportPath must be defined and not ""', "exportAsHtml returns correct message for undefined exportPath");

# inaccessible exportPath
$config->set('exportPath', Path::Class::Dir->new('')->stringify);

eval { ($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99 } ) };
is($@, '', "exportAsHtml catches inaccessible exportPath ");
is($success, 0, "exportAsHtml returns 0 for inaccessible exportPath");
is($message, "can't access " . Path::Class::Dir->new('')->stringify, "exportAsHtml returns correct message for inaccessible exportPath");

# exportPath is a file, not a directory
$config->set('exportPath', $exportPathFile);

eval { ($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99 } ) };
is($@, '', "exportAsHtml catches exportPath is file exception");
is($success, 0, "exportAsHtml returns 0 if exportPath is a file");
is($message, "$exportPathFile isn't a directory", "exportAsHtml returns correct message if exportPath is a file");

# can't create export path
chmod 0000, $tempDirectory;
$config->set('exportPath', $inaccessibleDirectory->stringify);

eval { ($success, $message) = $home->exportAsHtml( { userId => 3, depth => 99 } ) };
is($@, '', "exportAsHtml catches uncreatable exportPath exception");
is($success, 0, "exportAsHtml returns 0 for uncreatable exportPath");
is($message, "can't create exportPath $inaccessibleDirectory", "exportAsHtml returns correct message for uncreatable exportPath");

# user can't view asset
$home->update( { groupIdView => 3 } );
$session->http->{_http}->{noHeader} = 1;

chmod 0755, $tempDirectory;
eval { ($success, $message) = $home->exportAsHtml( { userId => 1, depth => 99 } ) };
is($@, '', "exportAsHtml catches unviewable asset exception");
is($success, 0, "exportAsHtml returns 0 for unviewable asset");
is($message, "can't view asset at URL /home", "exportAsHtml returns correct message for unviewable asset");

# fix viewing the asset
$home->update( { groupIdView => 7 } );

# the "can't write file" exceptions for exportWriteFile are largely related to
# the exportPath being broken somehow. That's already been tested. next, let's
# make sure symlinking works. start with extrasUploadAction. no use checking
# for valid paths and URLs for these values in the config file. the site would
# be horridly, totally broken if they were incorrect. assume that they're
# valid.
$config->set('exportPath', $originalExportPath);
$exportPath         = Path::Class::Dir->new($originalExportPath);
$extrasPath         = $config->get('extrasPath');
$extrasUrl          = $config->get('extrasURL');
$uploadsPath        = $config->get('uploadsPath');
$uploadsUrl         = $config->get('uploadsURL');

$exportPath->rmtree;

($success, $message)    = $home->exportAsHtml( { userId => 3, depth => 99, extrasUploadAction => 'symlink', quiet => 1 } );
$extrasSymlink          = Path::Class::File->new($exportPath, $extrasUrl);
$uploadsSymlink         = Path::Class::File->new($exportPath, $uploadsUrl);
is($success, 1, "exportAsHtml when linking extras and uploads returns true");
like($message, qr/Exported 23 pages/, "exportAsHtml when linking extras and uploads returns correct message");
ok(-e $extrasSymlink->absolute->stringify, "exportAsHtml writes extras symlink");
is($extrasPath, readlink $extrasSymlink->absolute->stringify, "exportAsHtml extras symlink points to right place");
ok(-e $uploadsSymlink->absolute->stringify, "exportAsHtml writes uploads symlink");
is($uploadsPath, readlink $uploadsSymlink->absolute->stringify, "exportAsHtml uploads symlink points to right place");

# next, make sure the root URL symlinking works.
($success, $message)    = $home->exportAsHtml( { userId => 3, depth => 99, rootUrlAction => 'symlink', quiet => 1 } );
my $rootUrlSymlink      = Path::Class::File->new($exportPath, 'index.html');
is($success, 1, 'exportAsHtml when linking root URL returns true');
like($message, qr/Exported 23 pages/, "exportAsHtml when linking root URL returns correct message");
ok(-e $rootUrlSymlink->absolute->stringify, "exportAsHtml writes root URL symlink");
is($home->exportGetUrlAsPath->absolute->stringify, readlink $rootUrlSymlink->absolute->stringify, "exportAsHtml root URL symlink points to right place");


#----------------------------------------------------------------------------
# Cleanup
END {
    if ($testRan) {
        # remove $tempDirectory since it now exists in the filesystem
        rmtree($tempDirectory);

        # restore the original exportPath setting, now that we're done testing
        # exportCheckPath.
        $session->config->set('exportPath', $originalExportPath);

        # we created a couple of assets; roll them back so they don't stick around
        $versionTag->rollback();

        # make sure people can view /home
        $home->update( { groupIdView => 7 } ); # everyone
    }
}
