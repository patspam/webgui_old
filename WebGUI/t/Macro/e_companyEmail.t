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

use Test::More; # increment this value for each test you create

my $session = WebGUI::Test->session;

my $numTests = 1 + 1;

plan tests => $numTests;

my $macro = 'WebGUI::Macro::e_companyEmail';
my $loaded = use_ok($macro);

SKIP: {

skip "Unable to load $macro", $numTests-1 unless $loaded;

my ($value) = $session->dbSlave->quickArray(
	"select value from settings where name='companyEmail'");
my $output = WebGUI::Macro::e_companyEmail::process($session);
is($output, $value, sprintf "Testing companyEmail");

}
