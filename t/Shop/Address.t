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
use lib "$FindBin::Bin/../lib";
use Test::More;
use Test::Deep;
use Exception::Class;

use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;
use WebGUI::Shop::AddressBook;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;

#----------------------------------------------------------------------------
# Tests

my $tests = 27;
plan tests => 1 + $tests;

#----------------------------------------------------------------------------
# put your tests here

my $loaded = use_ok('WebGUI::Shop::Address');

my $storage;

SKIP: {

skip 'Unable to load module WebGUI::Shop::Address', $tests unless $loaded;
my $e;
my $address;

#######################################################################
#
# create
#
#######################################################################

eval { $address = WebGUI::Shop::Address->create(); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidObject', 'create takes exception to not giving it an address book');
cmp_deeply(
    $e,
    methods(
        error    => 'Need an address book.',
        expected => 'WebGUI::Shop::AddressBook',
        got      => '',
        param    => undef,
    ),
    'create takes exception to not giving it address book',
);

eval { $address = WebGUI::Shop::Address->create($session); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidObject', 'create takes exception to not giving it a session variable');
cmp_deeply(
    $e,
    methods(
        error    => 'Need an address book.',
        expected => 'WebGUI::Shop::AddressBook',
        got      => 'WebGUI::Session',
        param    => $session,
    ),
    'create takes exception to giving it a session variable',
);

my $book = WebGUI::Shop::AddressBook->create($session);

eval { $address = WebGUI::Shop::Address->create($book); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'create takes exception to not giving it address data');
cmp_deeply(
    $e,
    methods(
        error    => 'Need a hash reference.',
        param    => undef,
    ),
    'create takes exception to giving it address data',
);

$address = WebGUI::Shop::Address->create($book, {});
isa_ok($address, 'WebGUI::Shop::Address', 'create returns an Address object with an empty hashref');

#######################################################################
#
# addressBook
#
#######################################################################

cmp_deeply(
    $address->addressBook,
    $book,
    'The address has a reference back to the book used to create it'
);

#######################################################################
#
# getId
#
#######################################################################

ok( $session->id->valid($address->getId), 'Address has a valid GUID');

#######################################################################
#
# get
#
#######################################################################

ok( $session->id->valid($address->getId), 'Address has a valid GUID');
is($address->getId, $address->get('addressId'), 'getId is an alias for get addressId');
cmp_deeply(
    $address->get,
    {
        label       => undef,
        name        => undef,
        address1    => undef,
        address2    => undef,
        address3    => undef,
        city        => undef,
        state       => undef,
        country     => undef,
        code        => undef,
        phoneNumber => undef,
        addressId   => ignore(), #checked elsewhere
        addressBookId  => $book->getId,
    },
    'get the whole thing and check a new, blank object'
);

my $addressGuts = $address->get();
$addressGuts->{'label'} = 'hacked';
is($address->get('label'), undef, 'get returns a safe copy of the hash');

#######################################################################
#
# update
#
#######################################################################

$address->update({ label => 'home'});
is($address->get('label'), 'home', 'update updates the object properties cache');
$address->update({ address1 => 'Shawshank Prison', 'state' => 'Maine'});
is($address->get('address1'), 'Shawshank Prison', 'update updates the object properties cache for more than one key');
is($address->get('state'), 'Maine', 'update updates the object properties cache for more than one key');

#######################################################################
#
# new
#
#######################################################################

eval { $address = WebGUI::Shop::Address->new(); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidObject', 'new takes exception to not giving it an address book');
cmp_deeply(
    $e,
    methods(
        error    => 'Need an address book.',
        expected => 'WebGUI::Shop::AddressBook',
        got      => '',
        param    => ignore,
    ),
    'new takes exception to not giving it address book',
);

eval { $address = WebGUI::Shop::Address->new($session); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidObject', 'new takes exception to not giving it a session variable');
cmp_deeply(
    $e,
    methods(
        error    => 'Need an address book.',
        expected => 'WebGUI::Shop::AddressBook',
        got      => 'WebGUI::Session',
        param    => ignore,
    ),
    'new takes exception to giving it a session variable',
);

eval { $address = WebGUI::Shop::Address->new($book); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'new takes exception to not giving it an address to instanciate');
cmp_deeply(
    $e,
    methods(
        error    => 'Need an addressId.',
        param    => undef,
    ),
    'new takes exception to giving it an address to instanciate',
);

eval { $address = WebGUI::Shop::Address->new($book, 'neverAnId'); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::ObjectNotFound', 'new takes exception to not giving it a bad address instanciate');
cmp_deeply(
    $e,
    methods(
        error    => 'Address not found.',
        id    => 'neverAnId',
    ),
    'new takes exception to giving it a bad address to instanciate',
);

TODO: {
    local $TODO = 'More tests for new';
    ok(0, 'Make a second address book, add an address to it, then try to call a valid address from the wrong book');
}

my $addressCopy = WebGUI::Shop::Address->new($book, $address->getId);
cmp_deeply(
    $address,
    $addressCopy,
    'new: gets an exact copy of the object from the db.  Also checks that update writes to the db correctly.'
);

#######################################################################
#
# delete
#
#######################################################################

$address->delete;
my $check = $session->db->quickScalar('select count(*) from address where addressId=?',[$address->getId]);
is( $check, 0, 'delete worked');

}

END {
    $session->db->write('delete from addressBook');
    $session->db->write('delete from address');
}
