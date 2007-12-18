# $vim: syntax=perl
#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2007 Plain Black Corporation.
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

## The goal of this test is to test the SelectRichEditor form control

use Scalar::Util qw( blessed );
use WebGUI::Test;
use WebGUI::Session;
use Test::More; 
use Test::Deep;

use WebGUI::Form::SelectRichEditor;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;
my $root            = WebGUI::Asset->getRoot( $session );

#----------------------------------------------------------------------------
# Cleanup
END {

}

#----------------------------------------------------------------------------
# Tests
plan tests => 1;

#----------------------------------------------------------------------------
# Test that SelectRichEditor control contains all RichEdit assets.
my $richEditAssets 
    = $root->getLineage( ['descendants'], { 
        returnObjects           => 1,
        includeOnlyClasses      => ['WebGUI::Asset::RichEdit'],
    });
my $richEditOptions
    = { 
        map { $_->getId => $_->get("title") } @$richEditAssets 
    };

my $control 
    = WebGUI::Form::SelectRichEditor->new( $session, { name => "richEditId" } );
cmp_deeply( 
    $control->get("options"), 
    $richEditOptions,
    "SelectRichEditor control has options for all Rich Editors in this site",
);
