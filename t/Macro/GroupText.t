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
use WebGUI::Macro;
use WebGUI::Session;
use WebGUI::Group;
use WebGUI::User;
use WebGUI::Macro_Config;

my $session = WebGUI::Test->session;

use Test::More; # increment this value for each test you create

plan tests => 3 + 4;

unless ($session->config->get('macros')->{'GroupText'}) {
	Macro_Config::insert_macro($session, 'GroupText', 'GroupText');
}

my $macroText = q!^GroupText("Admins","admin","visitor");!;
my $output;

$session->user({userId => 1});
$output = $macroText;
WebGUI::Macro::process($session, \$output);
is($output, 'visitor', 'user is not admin');

$session->user({userId => 3});
$output = $macroText;
WebGUI::Macro::process($session, \$output);
is($output, 'admin', 'user is admin');

$output = q!^GroupText("Not a Group","in group","outside group");!;
WebGUI::Macro::process($session, \$output);
is($output, 'Group Not a Group was not found', 'Non-existant group returns an error message');

##Bug test setup

##Create a small database
$session->db->dbh->do('DROP TABLE IF EXISTS myUserTable');
$session->db->dbh->do(q!CREATE TABLE myUserTable (userId varchar(22) binary NOT NULL default '', PRIMARY KEY(userId)) TYPE=InnoDB!);

##Create a bunch of users and put them in the table.

my @mob = map { WebGUI::User->new($session, "new") } 0..3;
my $sth = $session->db->prepare('INSERT INTO myUserTable VALUES(?)');
foreach my $mob (@mob) {
	$sth->execute([ $mob->userId ]);
}

##Create the 3 groups

my $ms_users = WebGUI::Group->new($session, "new");
my $ms_distributors = WebGUI::Group->new($session, "new");
my $ms_int_distributors = WebGUI::Group->new($session, "new");

$ms_users->name('MS Users');
$ms_distributors->name('MS Distributors');
$ms_int_distributors->name('MS International Distributors');

##MS Users has an SQL query
$ms_users->dbQuery(q!select userId from myUserTable!);

ok($mob[0]->isInGroup($ms_users->getId), 'mob[0] is in $ms_users');

##Establish group hierarchy
##MS International Distributors is a member of MS Distributors
##MS Distributors is a member of MS Users

$ms_users->addGroups([$ms_distributors->getId]);
$ms_distributors->addGroups([$ms_int_distributors->getId]);

##Add two users for testing the two groups

my $disti = WebGUI::User->new($session, 'new');
my $int_disti = WebGUI::User->new($session, 'new');

$ms_distributors->addUsers([$disti->userId]);
$ms_int_distributors->addUsers([$int_disti->userId]);

$macroText = q!^GroupText("MS Users","user","not");,^GroupText("MS Distributors","disti","not");,^GroupText("MS International Distributors","int_disti","not");!;

$session->user({userId => $mob[0]->userId});
$output = $macroText;
WebGUI::Macro::process($session, \$output);
is($output, 'user,not,not', 'user is ms user');

$session->user({userId => $disti->userId});
$output = $macroText;
WebGUI::Macro::process($session, \$output);
is($output, 'user,disti,not', 'user is ms user and distributor');

$session->user({userId => $int_disti->userId});
$output = $macroText;
WebGUI::Macro::process($session, \$output);
is($output, 'user,disti,int_disti', 'user is in all three groups');

##clean up everything
END {
	foreach my $testGroup ($ms_users, $ms_distributors, $ms_int_distributors, ) {
		$testGroup->delete if (defined $testGroup and ref $testGroup eq 'WebGUI::Group');
	}
	foreach my $dude (@mob, $disti, $int_disti, ) {
		$dude->delete if (defined $dude and ref $dude eq 'WebGUI::User');
	}
	$session->db->dbh->do('DROP TABLE IF EXISTS myUserTable');
}

