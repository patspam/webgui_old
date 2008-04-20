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
use WebGUI::Text;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;

#----------------------------------------------------------------------------
# Tests

my $tests = 22;
plan tests => 1 + $tests;

#----------------------------------------------------------------------------
# put your tests here

my $loaded = use_ok('WebGUI::Shop::AddressBook');

my $storage;

SKIP: {

skip 'Unable to load module WebGUI::Shop::AddressBook', $tests unless $loaded;
my $e;
my $book;

#######################################################################
#
# new
#
#######################################################################

eval { $book = WebGUI::Shop::AddressBook->new(); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'new takes exception to not giving it a session object');
cmp_deeply(
    $e,
    methods(
        error    => 'Need a session.',
        expected => 'WebGUI::Session',
        got      => '',
    ),
    'new takes exception to not giving it a session object',
);

eval { $book = WebGUI::Shop::AddressBook->new($session); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'new takes exception to not giving it a addressBookId');
cmp_deeply(
    $e,
    methods(
        error => 'Need an addressBookId.',
    ),
    'new takes exception to not giving it a addressBook Id',
);

eval { $book = WebGUI::Shop::AddressBook->new($session, 'neverAGUID'); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::ObjectNotFound', 'new takes exception to not giving it an existing addressBookId');
cmp_deeply(
    $e,
    methods(
        error => 'No such address book.',
        id    => 'neverAGUID',
    ),
    'new takes exception to not giving it a addressBook Id',
);


#######################################################################
#
# create
#
#######################################################################

eval { $book = WebGUI::Shop::AddressBook->create(); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'create takes exception to not giving it a session object');
cmp_deeply(
    $e,
    methods(
        error    => 'Need a session.',
        expected => 'WebGUI::Session',
        got      => '',
    ),
    'create takes exception to not giving it a session object',
);

$session->user({userId => 1});

$book = WebGUI::Shop::AddressBook->create($session);
isa_ok($book, 'WebGUI::Shop::AddressBook', 'create returns the right kind of object');

isa_ok($book->session, 'WebGUI::Session', 'session method returns a session object');

is($session->getId, $book->session->getId, 'session method returns OUR session object');

ok($session->id->valid($book->getId), 'create makes a valid GUID style addressBookId');

is(undef, $book->get('userId'), 'create does not automatically set the userId');

my $bookCount = $session->db->quickScalar('select count(*) from addressBook');
is($bookCount, 1, 'only 1 address book was created');

my $alreadyHaveBook = WebGUI::Shop::AddressBook->create($session);
is($book->getId, $alreadyHaveBook->getId, 'creating an addressbook as visitor, when you already have one, returns the one already created');

#######################################################################
#
# getId
#
#######################################################################

is($book->getId, $book->get('addressBookId'), 'getId is a shortcut for ->get');

#######################################################################
#
# addAddress
#
#######################################################################

my $address1 = $book->addAddress({ label => q{Red's cell} });
isa_ok($address1, 'WebGUI::Shop::Address', 'addAddress returns an object');

my $address2 = $book->addAddress({ label => q{Norton's office} });

#######################################################################
#
# getAddresses
#
#######################################################################

my @addresses = @{ $book->getAddresses() };

cmp_deeply(
    \@addresses,
    [$address1, $address2],
    'getAddresses returns all address objects for this book'
);

#######################################################################
#
# update
#
#######################################################################

$book->update({ lastShipId => $address1->getId, lastPayId => $address2->getId});

cmp_deeply(
    $book->get(),
    {
        userId     => ignore,
        sessionId  => ignore,
        addressBookId  => ignore,
        lastShipId => $address1->getId,
        lastPayId  => $address2->getId,
    },
    'update updates the object properties cache'
);

my $bookClone = WebGUI::Shop::AddressBook->new($session, $book->getId);

cmp_deeply(
    $bookClone,
    $book,
    'update updates the db, too'
);

#######################################################################
#
# delete
#
#######################################################################

$bookClone->delete();
$bookCount = $session->db->quickScalar('select count(*) from addressBook');
my $addrCount = $session->db->quickScalar('select count(*) from address');

is($bookCount, 0, 'delete: book deleted');
is($addrCount, 0, 'delete: also deletes addresses in the book');
undef $book;

}

END: {
    $session->db->write('delete from addressBook');
    $session->db->write('delete from address');
}
