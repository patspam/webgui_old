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

# Write a little about what this script tests.
# 
#

use FindBin;
use strict;
use lib "$FindBin::Bin/lib";
use Test::More;
use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Auth;
use WebGUI::Session;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;

my @cleanupUsernames    = ();   # Will be cleaned up when we're done
my $AUTH_METHOD     = "TEST";   # Used as second argument to WebGUI::Auth->new
my $auth;   # will be used to create auth instances
my ($request, $oldRequest, $output);

#----------------------------------------------------------------------------
# Tests

plan tests => 2;        # Increment this number for each test you create

#----------------------------------------------------------------------------
# Test createAccountSave and returnUrl together
# Set up request
$oldRequest  = $session->request;
$request     = WebGUI::PseudoRequest->new;
$request->setup_param({
    returnUrl       => 'REDIRECT_URL',
});
$session->{_request} = $request;

$auth           = WebGUI::Auth->new( $session, $AUTH_METHOD );
my $username    = $session->id->generate;
push @cleanupUsernames, $username;
$output         = $auth->createAccountSave( $username, { }, "PASSWORD" ); 

is(
    $session->http->getRedirectLocation, 'REDIRECT_URL',
    "returnUrl field is used to set redirect after createAccountSave",
);

# Session Cleanup
$session->{_request} = $oldRequest;

#----------------------------------------------------------------------------
# Test login and returnUrl together
# Set up request
$oldRequest  = $session->request;
$request     = WebGUI::PseudoRequest->new;
$request->setup_param({
    returnUrl       => 'REDIRECT_LOGIN_URL',
});
$session->{_request} = $request;

$auth           = WebGUI::Auth->new( $session, $AUTH_METHOD, 3 );
my $username    = $session->id->generate;
push @cleanupUsernames, $username;
$output         = $auth->login; 

is(
    $session->http->getRedirectLocation, 'REDIRECT_LOGIN_URL',
    "returnUrl field is used to set redirect after login",
);

# Session Cleanup
$session->{_request} = $oldRequest;


#----------------------------------------------------------------------------
# Cleanup
END {
    for my $username ( @cleanupUsernames ) {
        # We don't create actual, real users, so we have to cleanup by hand
        my $userId  = $session->db->quickScalar(
            "SELECT userId FROM users WHERE username=?",
            [ $username ]
        );
        
        my @tableList
            = qw{authentication users userProfileData groupings inbox userLoginLog};

        for my $table ( @tableList ) {
            $session->db->write(
                "DELETE FROM $table WHERE userId=?",
                [ $userId ]
            );
        }
    }
}
