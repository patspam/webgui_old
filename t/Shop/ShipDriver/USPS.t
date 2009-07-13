# vim:syntax=perl
#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
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
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Test::Deep;
use XML::Simple;
use Data::Dumper;

use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;

#----------------------------------------------------------------------------
# Init
my $session   = WebGUI::Test->session;
my $user      = WebGUI::User->create($session);
WebGUI::Test->usersToDelete($user);
$session->user({user => $user});

#----------------------------------------------------------------------------
# Tests

my $tests = 41;
plan tests => 1 + $tests;

#----------------------------------------------------------------------------
# put your tests here

my $loaded = use_ok('WebGUI::Shop::ShipDriver::USPS');

my $storage;
my ($driver, $cart);
my $versionTag = WebGUI::VersionTag->getWorking($session);

my $home = WebGUI::Asset->getDefault($session);

my $rockHammer = $home->addChild({
    className          => 'WebGUI::Asset::Sku::Product',
    isShippingRequired => 1,     title => 'Rock Hammers',
    shipsSeparately    => 0,
});

my $smallHammer = $rockHammer->setCollateral('variantsJSON', 'variantId', 'new',
    {
        shortdesc => 'Small rock hammer', price     => 7.50,
        varSku    => 'small-hammer',      weight    => 1.5,
        quantity  => 9999,
    }
);

my $bigHammer = $rockHammer->setCollateral('variantsJSON', 'variantId', 'new',
    {
        shortdesc => 'Big rock hammer', price     => 19.99,
        varSku    => 'big-hammer',      weight    => 12,
        quantity  => 9999,
    }
);

my $bible = $home->addChild({
    className          => 'WebGUI::Asset::Sku::Product',
    isShippingRequired => 1,     title => 'Bibles, individuall wrapped and shipped',
    shipsSeparately    => 1,
});

my $kjvBible = $bible->setCollateral('variantsJSON', 'variantId', 'new',
    {
        shortdesc => 'King James Bible',  price     => 17.50,
        varSku    => 'kjv-bible',         weight    => 2.5,
        quantity  => 99999,
    }
);

my $nivBible = $bible->setCollateral('variantsJSON', 'variantId', 'new',
    {
        shortdesc => 'NIV Bible',    price     => 22.50,
        varSku    => 'niv-bible',    weight    => 2.0,
        quantity  => 999999,
    }
);

$versionTag->commit;

SKIP: {

skip 'Unable to load module WebGUI::Shop::ShipDriver::USPS', $tests unless $loaded;

#######################################################################
#
# definition
#
#######################################################################

my $definition;
my $e; ##Exception variable, used throughout the file

eval { $definition = WebGUI::Shop::ShipDriver::USPS->definition(); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'definition takes an exception to not giving it a session variable');
cmp_deeply(
    $e,
    methods(
        error => 'Must provide a session variable',
    ),
    '... checking error message',
);


isa_ok(
    $definition = WebGUI::Shop::ShipDriver::USPS->definition($session),
    'ARRAY'
);


#######################################################################
#
# create
#
#######################################################################

my $options = {
                label   => 'USPS Driver',
                enabled => 1,
              };

$driver = WebGUI::Shop::ShipDriver::USPS->create($session, $options);

isa_ok($driver, 'WebGUI::Shop::ShipDriver::USPS');
isa_ok($driver, 'WebGUI::Shop::ShipDriver');

#######################################################################
#
# getName
#
#######################################################################

is (WebGUI::Shop::ShipDriver::USPS->getName($session), 'U.S. Postal Service', 'getName returns the human readable name of this driver');

#######################################################################
#
# delete
#
#######################################################################

my $driverId = $driver->getId;
$driver->delete;

my $count = $session->db->quickScalar('select count(*) from shipper where shipperId=?',[$driverId]);
is($count, 0, 'delete deleted the object');

undef $driver;

#######################################################################
#
# calculate, and private methods.
#
#######################################################################

$driver = WebGUI::Shop::ShipDriver::USPS->create($session, {
    label    => 'Shipping from Shawshank',
    enabled  => 1,
    shipType => 'PARCEL',
});

eval { $driver->calculate() };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'calculate throws an exception when no zipcode has been set');
cmp_deeply(
    $e,
    methods(
        error => 'Driver configured without a source zipcode.',
    ),
    '... checking error message',
);

my $properties = $driver->get();
$properties->{sourceZip} = '97123';
$driver->update($properties);

eval { $driver->calculate() };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'calculate throws an exception when no userId');
cmp_deeply(
    $e,
    methods(
        error => 'Driver configured without a USPS userId.',
    ),
    '... checking error message',
);

$cart = WebGUI::Shop::Cart->newBySession($session);
my $addressBook = $cart->getAddressBook;
my $workAddress = $addressBook->addAddress({
    label => 'work',
    organization => 'Plain Black Corporation',
    address1 => '1360 Regent St. #145',
    city => 'Madison', state => 'WI', code => '53715',
    country => 'USA',
});
my $wucAddress = $addressBook->addAddress({
    label => 'wuc',
    organization => 'Madison Concourse Hotel',
    address1 => '1 W Dayton St',
    city => 'Madison', state => 'WI', code => '53703',
    country => 'USA',
});
$cart->update({shippingAddressId => $workAddress->getId});

cmp_deeply(
    [$driver->_getShippableUnits($cart)],
    [(), ],
    '_getShippableUnits: empty cart'
);

$rockHammer->addToCart($rockHammer->getCollateral('variantsJSON', 'variantId', $smallHammer));
cmp_deeply(
    [$driver->_getShippableUnits($cart)],
    [[ ignore() ], ],
    '_getShippableUnits: one loose item in the cart'
);

$rockHammer->addToCart($rockHammer->getCollateral('variantsJSON', 'variantId', $bigHammer));
cmp_deeply(
    [$driver->_getShippableUnits($cart)],
    [[ ignore(), ignore() ], ],
    '_getShippableUnits: two loose items in the cart'
);

$bible->addToCart($bible->getCollateral('variantsJSON', 'variantId', $kjvBible));
cmp_bag(
    [$driver->_getShippableUnits($cart)],
    [[ ignore(), ignore() ], [ ignore(), ], ],
    '_getShippableUnits: two loose items, and 1 ships separately item in the cart'
);

my $bibleItem = $bible->addToCart($bible->getCollateral('variantsJSON', 'variantId', $nivBible));
$bibleItem->setQuantity(5);
cmp_bag(
    [$driver->_getShippableUnits($cart)],
    [[ ignore(), ignore() ], [ ignore() ], [ ignore() ], ],
    '_getShippableUnits: two loose items, and 2 ships separately item in the cart, regarless of quantity for the new item'
);

my $rockHammer2 = $bible->addToCart($rockHammer->getCollateral('variantsJSON', 'variantId', $smallHammer));
$rockHammer2->update({shippingAddressId => $wucAddress->getId});
cmp_bag(
    [$driver->_getShippableUnits($cart)],
    [[ ignore(), ignore() ], [ ignore() ], [ ignore() ], [ ignore() ], ],
    '_getShippableUnits: two loose items, and 2 ships separately item in the cart, and another loose item sorted by zipcode'
);

$cart->empty;
$bible->addToCart($bible->getCollateral('variantsJSON', 'variantId', $nivBible));
cmp_deeply(
    [$driver->_getShippableUnits($cart)],
    [ [ ignore() ], ],
    '_getShippableUnits: only 1 ships separately item in the cart'
);
$cart->empty;

my $userId = $session->config->get('testing/USPS_userId');
my $hasRealUserId = 1;
##If there isn't a userId, set a fake one for XML testing.
if (! $userId) {
    $hasRealUserId = 0;
    $userId = "blahBlahBlah";
}
$properties = $driver->get();
$properties->{userId}    = $userId;
$properties->{sourceZip} = '97123';
$driver->update($properties);

$rockHammer->addToCart($rockHammer->getCollateral('variantsJSON', 'variantId', $smallHammer));
my @shippableUnits = $driver->_getShippableUnits($cart);

my $xml = $driver->buildXML($cart, @shippableUnits);
like($xml, qr/<RateV3Request USERID="[^"]+"/, 'buildXML: checking userId is an attribute of the RateV3Request tag');
like($xml, qr/<Package ID="0"/, 'buildXML: checking ID is an attribute of the Package tag');

my $xmlData = XMLin($xml,
    KeepRoot   => 1,
    ForceArray => ['Package'],
);
cmp_deeply(
    $xmlData,
    {
        RateV3Request => {
            USERID => $userId,
            Package => [
                {
                    ID => 0,
                    ZipDestination => '53715',    ZipOrigination => '97123',
                    Pounds         => '1',        Ounces => '8',
                    Size           => 'REGULAR',  Service        => 'PARCEL',
                    Machinable     => 'true',
                },
            ],
        }
    },
    'buildXML: PARCEL service, 1 item in cart'
);

like($xml, qr/RateV3Request USERID.+?Package ID=.+?Service.+?ZipOrigination.+?ZipDestination.+?Pounds.+?Ounces.+?Size.+?Machinable/, '... and tag order');

SKIP: {

    skip 'No userId for testing', 2 unless $hasRealUserId;

    my $response = $driver->_doXmlRequest($xml);
    ok($response->is_success, '_doXmlRequest to USPS successful');
    my $xmlData = XMLin($response->content, ForceArray => [qw/Package/],);
    cmp_deeply(
        $xmlData,
        {
            Package => [
                {
                    ID             => 0,
                    ZipOrigination => ignore(), ZipDestination => ignore(),
                    Machinable     => ignore(), Ounces         => ignore(),
                    Pounds         => ignore(), Size           => ignore(),
                    Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(10,10),  ##A number around 10...
                    }
                },
            ],
        },
        '... returned data from USPS in correct format.  If this test fails, the driver may need to be updated'
    );

}

my $cost = $driver->_calculateFromXML({
    Package => [
        {
            ID => 0,
            Postage => {
                Rate => 5.25,
            },
        },
    ],
    },
    @shippableUnits
);

is($cost, 5.25, '_calculateFromXML calculates shipping cost correctly for 1 item in the cart');

$bibleItem = $bible->addToCart($bible->getCollateral('variantsJSON', 'variantId', $nivBible));
@shippableUnits = $driver->_getShippableUnits($cart);
$xml = $driver->buildXML($cart, @shippableUnits);

$xmlData = XMLin( $xml,
    KeepRoot   => 1,
    ForceArray => ['Package'],
);

cmp_deeply(
    $xmlData,
    {
        RateV3Request => {
            USERID => $userId,
            Package => [
                {
                    ID => 0,
                    ZipDestination => '53715',    ZipOrigination => '97123',
                    Pounds         => '2',        Ounces => '0',
                    Size           => 'REGULAR',  Service        => 'PARCEL',
                    Machinable     => 'true',
                },
                {
                    ID => 1,
                    ZipDestination => '53715',    ZipOrigination => '97123',
                    Pounds         => '1',        Ounces => '8',
                    Size           => 'REGULAR',  Service        => 'PARCEL',
                    Machinable     => 'true',
                },
            ],
        }
    },
    'Validate XML structure and content for 2 items in the cart'
);

SKIP: {

    skip 'No userId for testing', 2 unless $hasRealUserId;

    my $response = $driver->_doXmlRequest($xml);
    ok($response->is_success, '_doXmlRequest to USPS successful for 2 items in cart');
    my $xmlData = XMLin($response->content, ForceArray => [qw/Package/],);
    cmp_deeply(
        $xmlData,
        {
            Package => [
                {
                    ID             => 0,
                    ZipOrigination => ignore(), ZipDestination => ignore(),
                    Machinable     => ignore(), Ounces         => 0,
                    Pounds         => 2,        Size           => ignore(),
                    Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(10,10),  ##A number around 10...
                    }
                },
                {
                    ID             => 1,
                    ZipOrigination => ignore(), ZipDestination => ignore(),
                    Machinable     => ignore(), Ounces         => 8,
                    Pounds         => 1,        Size           => ignore(),
                    Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(10,10),  ##A number around 10...
                    }
                },
            ],
        },
        '... returned data from USPS in correct format for 2 items in cart.  If this test fails, the driver may need to be updated'
    );

}

$cost = $driver->_calculateFromXML({
    Package => [
        {
            ID => 0,
            Postage => {
                Rate => 7.00,
            },
        },
        {
            ID => 1,
            Postage => {
                Rate => 5.25,
            },
        },
    ],
    },
    @shippableUnits
);

is($cost, 12.25, '_calculateFromXML calculates shipping cost correctly for 2 items in the cart');

$bibleItem->setQuantity(2);
@shippableUnits = $driver->_getShippableUnits($cart);

$cost = $driver->_calculateFromXML({
    Package => [
        {
            ID => 0,
            Postage => {
                Rate => 7.00,
            },
        },
        {
            ID => 1,
            Postage => {
                Rate => 5.25,
            },
        },
    ],
    },
    @shippableUnits
);
is($cost, 19.25, '_calculateFromXML calculates shipping cost correctly for 2 items in the cart, with quantity of 2');

$rockHammer2 = $rockHammer->addToCart($rockHammer->getCollateral('variantsJSON', 'variantId', $bigHammer));
$rockHammer2->update({shippingAddressId => $wucAddress->getId});
@shippableUnits = $driver->_getShippableUnits($cart);
$xml = $driver->buildXML($cart, @shippableUnits);

$xmlData = XMLin( $xml,
    KeepRoot   => 1,
    ForceArray => ['Package'],
);

cmp_deeply(
    $xmlData,
    {
        RateV3Request => {
            USERID => $userId,
            Package => [
                {
                    ID => 0,
                    ZipDestination => '53715',    ZipOrigination => '97123',
                    Pounds         => '2',        Ounces => '0',
                    Size           => 'REGULAR',  Service        => 'PARCEL',
                    Machinable     => 'true',
                },
                {
                    ID => 1,
                    ZipDestination => '53715',    ZipOrigination => '97123',
                    Pounds         => '1',        Ounces => '8',
                    Size           => 'REGULAR',  Service        => 'PARCEL',
                    Machinable     => 'true',
                },
                {
                    ID => 2,
                    ZipDestination => '53703',    ZipOrigination => '97123',
                    Pounds         => '12',       Ounces => '0',
                    Size           => 'REGULAR',  Service        => 'PARCEL',
                    Machinable     => 'true',
                },
            ],
        }
    },
    'Validate XML structure and content for 3 items in the cart, 3 shippable items'
);

SKIP: {

    skip 'No userId for testing', 2 unless $hasRealUserId;

    my $response = $driver->_doXmlRequest($xml);
    ok($response->is_success, '_doXmlRequest to USPS successful for 3 items in cart');
    my $xmlData = XMLin($response->content, ForceArray => [qw/Package/],);
    cmp_deeply(
        $xmlData,
        {
            Package => [
                {
                    ID             => 0,
                    ZipOrigination => ignore(), ZipDestination => ignore(),
                    Machinable     => ignore(), Ounces         => 0,
                    Pounds         => 2,        Size           => ignore(),
                    Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(10,10),  ##A number around 10...
                    }
                },
                {
                    ID             => 1,
                    ZipOrigination => ignore(), ZipDestination => ignore(),
                    Machinable     => ignore(), Ounces         => 8,
                    Pounds         => 1,        Size           => ignore(),
                    Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(10,10),  ##A number around 10...
                    }
                },
                {
                    ID             => 2,
                    ZipOrigination => ignore(), ZipDestination => 53703,
                    Machinable     => ignore(), Ounces         => 0,
                    Pounds         => 12,       Size           => ignore(),
                    Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(20,20),  ##A number around 20...
                    }
                },
            ],
        },
        '... returned data from USPS in correct format for 3 items in cart.  If this test fails, the driver may need to be updated'
    );

}

$cart->empty;
$properties = $driver->get();
$properties->{shipType} = 'PRIORITY';
$driver->update($properties);

$rockHammer->addToCart($rockHammer->getCollateral('variantsJSON', 'variantId', $smallHammer));
@shippableUnits = $driver->_getShippableUnits($cart);
$xml = $driver->buildXML($cart, @shippableUnits);
my $xmlData = XMLin($xml,
    KeepRoot   => 1,
    ForceArray => ['Package'],
);
cmp_deeply(
    $xmlData,
    {
        RateV3Request => {
            USERID => $userId,
            Package => [
                {
                    ID => 0,
                    ZipDestination => '53715',    ZipOrigination => '97123',
                    Pounds         => '1',        Ounces         => '8',
                    Size           => 'REGULAR',  Service        => 'PRIORITY',
                    Machinable     => 'true',     Container      => 'FLAT RATE BOX',
                },
            ],
        }
    },
    'buildXML: PRIORITY service, 1 item in cart'
);
like($xml, qr/RateV3Request USERID.+?Package ID=.+?Service.+?ZipOrigination.+?ZipDestination.+?Pounds.+?Ounces.+?Container.+?Size.+?Machinable/, '... and tag order');

SKIP: {

    skip 'No userId for testing', 2 unless $hasRealUserId;

    my $response = $driver->_doXmlRequest($xml);
    ok($response->is_success, '_doXmlRequest to USPS successful');
    my $xmlData = XMLin($response->content, ForceArray => [qw/Package/],);
    cmp_deeply(
        $xmlData,
        {
            Package => [
                {
                    ID             => 0,
                    ZipOrigination => ignore(), ZipDestination => ignore(),
                    Container      => ignore(), Ounces         => ignore(), ##Machinable missing, added Container
                    Pounds         => ignore(), Size           => ignore(),
                    Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(10,10),  ##A number around 10...
                    }
                },
            ],
        },
        '... returned data from USPS in correct format.  If this test fails, the driver may need to be updated'
    );

}

$properties = $driver->get();
$properties->{shipType} = 'EXPRESS';
$driver->update($properties);

$xml = $driver->buildXML($cart, @shippableUnits);
my $xmlData = XMLin($xml,
    KeepRoot   => 1,
    ForceArray => ['Package'],
);
cmp_deeply(
    $xmlData,
    {
        RateV3Request => {
            USERID => $userId,
            Package => [
                {
                    ID => 0,
                    ZipDestination => '53715',    ZipOrigination => '97123',
                    Pounds         => '1',        Ounces         => '8',
                    Size           => 'REGULAR',  Service        => 'EXPRESS',
                    Machinable     => 'true',
                },
            ],
        }
    },
    'buildXML: EXPRESS service, 1 item in cart'
);
like($xml, qr/RateV3Request USERID.+?Package ID=.+?Service.+?ZipOrigination.+?ZipDestination.+?Pounds.+?Ounces.+?Size.+?Machinable/, '... and tag order');

SKIP: {

    skip 'No userId for testing', 2 unless $hasRealUserId;

    my $response = $driver->_doXmlRequest($xml);
    ok($response->is_success, '... _doXmlRequest to USPS successful');
    my $xmlData = XMLin($response->content, ForceArray => [qw/Package/],);
    cmp_deeply(
        $xmlData,
        {
            Package => [
                {
                    ID             => 0,
                    ZipOrigination => ignore(), ZipDestination => ignore(),
                    Ounces         => ignore(), Pounds         => ignore(),
                    Size           => ignore(), Zone           => ignore(),
                    Postage        => {
                        CLASSID     => ignore(),
                        MailService => ignore(),
                        Rate        => num(30,30),  ##A number around 10...
                    }
                },
            ],
        },
        '... returned data from USPS in correct format.  If this test fails, the driver may need to be updated'
    );

}


}

#----------------------------------------------------------------------------
# Cleanup
END {
    if (defined $driver && $driver->isa('WebGUI::Shop::ShipDriver')) {
        $driver->delete;
    }
    if (defined $cart && $cart->isa('WebGUI::Shop::Cart')) {
        my $addressBook = $cart->getAddressBook();
        $addressBook->delete if $addressBook;
        $cart->delete;
    }
    if (defined $versionTag) {
        $versionTag->rollback;
    }
}
