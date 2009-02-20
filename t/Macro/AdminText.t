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
use WebGUI::Session;
use Data::Dumper;

my $session = WebGUI::Test->session;

use Test::More; # increment this value for each test you create

my $numTests = 6 + 1;

plan tests => $numTests;

my $macro = 'WebGUI::Macro::AdminText';
my $loaded = use_ok($macro);

SKIP: {

skip "Unable to load $macro", $numTests-1 unless $loaded;

my $output;

$session->user({userId => 1});
$output = WebGUI::Macro::AdminText::process($session, 'admin');
is($output, '', 'user is not admin');

$session->user({userId => 3});
$output = WebGUI::Macro::AdminText::process($session, 'admin');
is($output, '', 'user is admin, not in admin mode');

$session->var->switchAdminOn;
$output = WebGUI::Macro::AdminText::process($session, 'admin');
is($output, 'admin', 'admin in admin mode');

$output = WebGUI::Macro::AdminText::process($session, '');
is($output, '', 'null text');

$output = WebGUI::Macro::AdminText::process($session);
is($output, undef, 'undef text');

$session->var->switchAdminOff;
$output = WebGUI::Macro::AdminText::process($session, 'admin');
is($output, '', 'user is admin, not in admin mode');

}
