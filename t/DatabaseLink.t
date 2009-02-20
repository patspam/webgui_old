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

use WebGUI::DatabaseLink;

use Test::More;
use Test::Deep;

my $session = WebGUI::Test->session;

#DSNs for parsing tests, particularly the database name
my $DSNs = [
	{
		dsn     => 'DBI:mysql:colonSeparated:myHost:8008',
		dbName  => 'colonSeparated',
        comment => 'explicit',
	},
	{
		dsn     => 'DBI:mysql:database=myDatabase',
		dbName  => 'myDatabase',
        comment => 'database=',
	},
	{
		dsn     => 'DBI:mysql:dbName=myDbName',
		dbName  => undef,
        comment => 'dbName=, bad capitalization',
	},
	{
		dsn     => 'DBI:mysql:dbname=mydbname',
		dbName  => 'mydbname',
        comment => 'dbname=',
	},
	{
		dsn     => 'DBI:mysql:dbnane=myDbName',
		dbName  => undef,
        comment => 'dbnane=, misspelling',
	},
	{
		dsn     => 'DBI:mysql:db=myDb',
		dbName  => 'myDb',
        comment => 'db=',
	},
];

#Grants for parsing tests, particularly the database name
my $grants = [
	{
		dsn        => 'DBI:mysql:myDb:myHost:8008',
		privileges => [qw/ALTER CREATE INSERT DELETE/],
        grants     => [
            'GRANT ALTER, CREATE, INSERT, DELETE ON *.* to user@localhost',
        ],
        privileged => 1,
        comment    => 'ACID on *.*, privileged',
	},
	{
		dsn        => 'DBI:mysql:myDb:myHost:8008',
		privileges => [qw/ALTER CREATE INSERT DELETE/],
        grants     => [
            'GRANT ALL PRIVILEGES ON *.* to user@localhost',
        ],
        privileged => 1,
        comment    => 'ALL PRIVILEGES on *.*, privileged',
	},
	{
		dsn        => 'DBI:mysql:myDb:myHost:8008',
		privileges => [qw/ALTER CREATE INSERT DELETE/],
        grants     => [
            'GRANT ALTER, CREATE, INSERT ON *.* to user@localhost',
        ],
        privileged => 0,
        comment    => 'Missing DELETE on *.*, unprivileged',
	},
	{
		dsn        => 'DBI:mysql:myDb:myHost:8008',
		privileges => [qw/ALTER CREATE INSERT DELETE/],
        grants     => [
            'GRANT ALL PRIVILEGES ON myDb.* to user@localhost',
        ],
        privileged => 1,
        comment    => 'ALL PRIVILEGES on explicit db name, privileged',
	},
	{
		dsn        => 'DBI:mysql:myDb:myHost:8008',
		privileges => [qw/ALTER CREATE INSERT DELETE/],
        grants     => [
            'GRANT ALL PRIVILEGES ON `myDb`.* to user@localhost',
        ],
        privileged => 1,
        comment    => 'ALL PRIVILEGES on quoted, explicit db name, privileged',
	},
	{
		dsn        => 'DBI:mysql:myDb:myHost:8008',
		privileges => [qw/ALTER CREATE INSERT DELETE/],
        grants     => [
            'GRANT ALL PRIVILEGES ON `my%`.* to user@localhost',
        ],
        privileged => 1,
        comment    => 'ALL PRIVILEGES on quoted, wildcard name, privileged',
	},
	{
		dsn        => 'DBI:mysql:yourDb:myHost:8008',
		privileges => [qw/ALTER CREATE INSERT DELETE/],
        grants     => [
            'GRANT ALL PRIVILEGES ON `my%`.* to user@localhost',
        ],
        privileged => 0,
        comment    => 'ALL PRIVILEGES on wrong db, unprivileged',
	},
];


plan tests => 14 + scalar @{ $DSNs } + scalar @{ $grants };

####################################################
#
# create
#
####################################################

my $startingDbLinks = scalar keys %{WebGUI::DatabaseLink->getList($session)}; 

my $dbLink = WebGUI::DatabaseLink->create($session);
isa_ok($dbLink, 'WebGUI::DatabaseLink', 'create made an object');
ok($session->id->valid($dbLink->getId), 'create makes an object with a valid GUID');
cmp_deeply(
    $dbLink->get(),
    {
        databaseLinkId => re(".{22}"),
        DSN        => undef,
        username   => undef,
        identifier => undef,
        title      => undef,
        allowedKeywords => undef,
        allowMacroAccess => 0,
        additionalParameters => '',
    },
    'create: passing no params autovivifies the databaseLinkId, but that is all',
);

is(scalar keys %{WebGUI::DatabaseLink->getList($session)}, $startingDbLinks+1, 'new DatabaseLink created');
$dbLink->delete();
is(scalar keys %{WebGUI::DatabaseLink->getList($session)}, $startingDbLinks, 'new DatabaseLink deleted');

my $dbLinkParams = {
                    DSN        => 'DBI:mysql:myDb:myHost',
                    username   => 'dbUser',
                    identifier => 'dbPass',
                    title      => 'Access to my Awesome DB',
                    allowedKeywords => 'SELECT UPDATE',
                    databaseLinkId  => 'fooBarBaz',
                    allowMacroAccess => 0,
                    additionalParameters => '',
                   };

$dbLink = WebGUI::DatabaseLink->create($session, $dbLinkParams);
$dbLinkParams->{databaseLinkId} = ignore();

cmp_deeply(
    $dbLink->get(),
    $dbLinkParams,
    'create: params sent to create are embedded in the object correctly',
);
isnt($dbLink->getId, 'fooBarBaz', 'requested databaseLinkId was not used as the linkId');
ok($session->id->valid($dbLink->getId), 'create made a valid GUID instead of that thing I asked for');

####################################################
#
# queryIsValid
#
####################################################

####################################################
#
# new
#
####################################################

my $wgDbLink = WebGUI::DatabaseLink->new($session, 0);
is($wgDbLink->get->{DSN}, $session->config->get('dsn'), 'DSN set correctly for default database link');
my ($databaseName) = $session->db->quickArray('SELECT DATABASE()');
is ($wgDbLink->databaseName, $databaseName, 'databaseName parsed default DSN from config file');
is ($wgDbLink->getId, 0, 'databaseLinkId set correctly');

is(WebGUI::DatabaseLink->new($session), undef, 'new returns undef unless you specify a databaseLinkId');
is(WebGUI::DatabaseLink->new($session,'foobar'), undef, 'new returns undef with a non-existant databaseLinkId');

####################################################
#
# delete
#
####################################################



####################################################
#
# databaseName
#
####################################################

my $dbs = WebGUI::DatabaseLink->getList($session);

foreach my $dsn (@{ $DSNs }) {
    my $dbl = WebGUI::DatabaseLink->create($session, { DSN => $dsn->{dsn} });
	is( $dbl->databaseName(), $dsn->{dbName}, $dsn->{comment} );
    $dbl->delete;
}

####################################################
#
# checkPrivileges
#
####################################################

foreach my $grant (@{ $grants }) {
    my $dbl = WebGUI::DatabaseLink->create($session, { DSN => $grant->{dsn} });
	is(
        $dbl->checkPrivileges($grant->{privileges}, $grant->{grants}),
        $grant->{privileged},
        $grant->{comment}
    );
    $dbl->delete;
}

my $dbsAfter = WebGUI::DatabaseLink->getList($session);

cmp_deeply($dbs, $dbsAfter, 'delete cleaned up all temporarily created DatabaseLinks');

END {
	foreach my $link ($dbLink, $wgDbLink) {
		$link->delete if (defined $link and ref $link eq 'WebGUI::DatabaseLink');
	}
}
