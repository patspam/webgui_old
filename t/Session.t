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

use WebGUI::Test;
use WebGUI::Session;

use WebGUI::User;

use Test::More;

plan tests => 3; # increment this value for each test you create

my $session = WebGUI::Test->session;

my $user = WebGUI::User->new($session, "new");

$session->user({user => $user});

my ($userId) = $session->db->quickArray("select userId from userSession where sessionId=?",[$session->getId]);

is($userId, $user->userId, 'changing session user changes sessionId inside userSession table');

$session->user({userId => 3});
is($session->user->profileField('uiLevel'), 9, 'Set session user to Admin, check uiLevel==9');

################################################################
#
# dbSlave
#
################################################################

##Manually build one dbSlave in the config file to use

my $slaveHash2 = {
    dsn  => $session->config->get('dsn'),
    user => $session->config->get('dbuser'),
    pass => $session->config->get('dbpass'),
};

$session->config->set('dbslave2', $slaveHash2);

my $slave2 = $session->dbSlave;
isa_ok($slave2, 'WebGUI::SQL');

END {
	foreach my $dude ($user) {
		$dude->delete if (defined $dude and ref $dude eq 'WebGUI::User');
	}
    $session->config->delete('dbslave2');
}
