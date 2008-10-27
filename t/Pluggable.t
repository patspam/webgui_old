#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#------------------------------------------------------------------

# Write a little about what this script tests.
# 
#

use FindBin;
use strict;
use lib "$FindBin::Bin/lib";
use Test::More;
use WebGUI::Test;
use File::Find;
use File::Spec;
use Test::Deep;

# Must load some Test::Deep modules before we start modifying @INC
use Test::Deep::Array;
use Test::Deep::ArrayLength;
use Test::Deep::ArrayLengthOnly;
use Test::Deep::ArrayElementsOnly;
use Test::Deep::RefType;
use Test::Deep::Shallow;
use Test::Deep::Blessed;
use Test::Deep::Isa;
use Test::Deep::Set;

use WebGUI::Pluggable;

#----------------------------------------------------------------------------
# Init


#----------------------------------------------------------------------------
# Tests

plan tests => 8;        # Increment this number for each test you create

#----------------------------------------------------------------------------
# put your tests here
eval { WebGUI::Pluggable::load("No::Way::In::Hell") };
isnt($@, '', "Module shouldn't load.");
eval { WebGUI::Pluggable::load("Config::JSON") };
is($@, '', "Module should load.");
my $string = WebGUI::Pluggable::run("Data::Dumper","Dumper",[ {color=>"black", make=>"honda"}]);
is($string, q|$VAR1 = {
          'make' => 'honda',
          'color' => 'black'
        };
|, "Can run a function.");
my $dumper = WebGUI::Pluggable::instanciate("Data::Dumper","new",[ [{color=>"black", make=>"honda"}]]);
is($dumper->Dump, q|$VAR1 = {
          'make' => 'honda',
          'color' => 'black'
        };
|, "Can instanciate an object.");

#----------------------------------------------------------------------------
# Test find and findAndLoad
{ # Block to localize @INC
    my $lib     = WebGUI::Test->lib;
    local @INC  = ( $lib );

    # Use the i18n files to test
    my @testFiles   = ();
    File::Find::find( 
        sub { 
            if ( !/^[.]/ && /[.]pm$/ ) {
                my $name    = $File::Find::name;
                $name   =~ s{^$lib[/]}{};
                $name   =~ s/[.]pm$//;
                $name   =~ s{/}{::}g;
                push @testFiles, $name;
            }
        },
        File::Spec->catfile( $lib, 'WebGUI', 'i18n' ),
    );
    
    cmp_deeply(
        [ WebGUI::Pluggable::find( 'WebGUI::i18n' ) ],
        bag( @testFiles ),
        "find() finds all modules by default",
    );

    cmp_deeply(
        [ WebGUI::Pluggable::find( 'WebGUI::i18n', { onelevel => 1 } ) ],
        bag( grep { /^WebGUI::i18n::[^:]+$/ } @testFiles ),
        "find() with onelevel",
    );

    cmp_deeply(
        [ WebGUI::Pluggable::find( 'WebGUI::i18n', { exclude => [ 'WebGUI::i18n::English::WebGUI' ] } ) ],
        bag( grep { $_ ne 'WebGUI::i18n::English::WebGUI' } @testFiles ),
        "find() with exclude",
    );
    
    cmp_deeply( 
        [ WebGUI::Pluggable::find( 'WebGUI::i18n', { onelevel => 1, return => "name" } ) ],
        bag( map { /::([^:]+)$/; $1 } grep { /^WebGUI::i18n::[^:]+$/ } @testFiles ),
        "find() with return => name",
    );
};

#----------------------------------------------------------------------------
# Cleanup

END {

}

