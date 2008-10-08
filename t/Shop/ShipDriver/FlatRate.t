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
use lib "$FindBin::Bin/../../lib";
use Test::More;
use Test::Deep;
use JSON;
use HTML::Form;

use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;

#----------------------------------------------------------------------------
# Tests

my $tests = 12;
plan tests => 1 + $tests;

#----------------------------------------------------------------------------
# put your tests here

my $loaded = use_ok('WebGUI::Shop::ShipDriver::FlatRate');

my $storage;
my ($driver, $cart, $car);

SKIP: {

skip 'Unable to load module WebGUI::Shop::ShipDriver::FlatRate', $tests unless $loaded;

#######################################################################
#
# definition
#
#######################################################################

my $definition;
my $e; ##Exception variable, used throughout the file

eval { $definition = WebGUI::Shop::ShipDriver::FlatRate->definition(); };
$e = Exception::Class->caught();
isa_ok($e, 'WebGUI::Error::InvalidParam', 'definition takes an exception to not giving it a session variable');
cmp_deeply(
    $e,
    methods(
        error => 'Must provide a session variable',
    ),
    'definition: requires a session variable',
);


$definition = WebGUI::Shop::ShipDriver::FlatRate->definition($session);

cmp_deeply(
    $definition,
    [ {
        name => 'Flat Rate',
        properties => {
            flatFee => {
                fieldType => 'float',
                label => ignore(),
                hoverHelp => ignore(),
                defaultValue => 0,
            },
            percentageOfPrice => {
                fieldType => 'float',
                label => ignore(),
                hoverHelp => ignore(),
                defaultValue => 0,
            },
            pricePerWeight => {
                fieldType => 'float',
                label => ignore(),
                hoverHelp => ignore(),
                defaultValue => 0,
            },
            pricePerItem => {
                fieldType => 'float',
                label => ignore(),
                hoverHelp => ignore(),
                defaultValue => 0,
            },
        }
    },
    {
        name => 'Shipper Driver',
        properties => {
            label => {
                fieldType => 'text',
                label => ignore(),
                hoverHelp => ignore(),
                defaultValue => undef,
            },
            enabled => {
                fieldType => 'yesNo',
                label => ignore(),
                hoverHelp => ignore(),
                defaultValue => 1,
            },
        }
    } ],
    'Definition returns an array of hashrefs',
);

#######################################################################
#
# create
#
#######################################################################

my $driver;

my $options = {
                label   => 'flat rate, ship weight, items in the cart',
                enabled => 1,
                flatFee => 1.00,
                percentageOfPrice => 5,
                pricePerWeight    => 0.5,
                pricePerItem      => 0.1,
              };

$driver = WebGUI::Shop::ShipDriver::FlatRate->create($session, $options);

isa_ok($driver, 'WebGUI::Shop::ShipDriver::FlatRate');

isa_ok($driver, 'WebGUI::Shop::ShipDriver');

#######################################################################
#
# getName
#
#######################################################################

is (WebGUI::Shop::ShipDriver::FlatRate->getName($session), 'Flat Rate', 'getName returns the human readable name of this driver');

#######################################################################
#
# getEditForm
#
#######################################################################

my $form = $driver->getEditForm;

isa_ok($form, 'WebGUI::HTMLForm', 'getEditForm returns an HTMLForm object');

my $html = $form->print;

##Any URL is fine, really
my @forms = HTML::Form->parse($html, 'http://www.webgui.org');
is (scalar @forms, 1, 'getEditForm generates just 1 form');

my @inputs = $forms[0]->inputs;
is (scalar @inputs, 11, 'getEditForm: the form has 11 controls');

my @interestingFeatures;
foreach my $input (@inputs) {
    my $name = $input->name;
    my $type = $input->type;
    push @interestingFeatures, { name => $name, type => $type };
}

cmp_deeply(
    \@interestingFeatures,
    [
        {
            name => undef,
            type => 'submit',
        },
        {
            name => 'driverId',
            type => 'hidden',
        },
        {
            name => 'shop',
            type => 'hidden',
        },
        {
            name => 'method',
            type => 'hidden',
        },
        {
            name => 'do',
            type => 'hidden',
        },
        {
            name => 'label',
            type => 'text',
        },
        {
            name => 'enabled',
            type => 'radio',
        },
        {
            name => 'flatFee',
            type => 'text',
        },
        {
            name => 'percentageOfPrice',
            type => 'text',
        },
        {
            name => 'pricePerWeight',
            type => 'text',
        },
        {
            name => 'pricePerItem',
            type => 'text',
        },
    ],
    'getEditForm made the correct form with all the elements'

);

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
# calculate
#
#######################################################################

$car = WebGUI::Asset->getImportNode($session)->addChild({
    className          => 'WebGUI::Asset::Sku::Product',
    title              => 'Automobiles',
    isShippingRequired => 1,
});

my $crappyCar = $car->setCollateral('variantsJSON', 'variantId', 'new',
    {
        shortdesc => '1987 Ford Escort',
        varSku    => 'crappy-car',
        price     => 600,
        weight    => 1500,
        quantity  => 5,
    }
);

my $goodCar = $car->setCollateral('variantsJSON', 'variantId', 'new',
    {
        shortdesc => '2004 Honda MPV minivan',
        varSku    => 'used van',
        price     => 15_000,
        weight    => 2000,
        quantity  => 15,
    }
);

my $reallyNiceCar = $car->setCollateral('variantsJSON', 'variantId', 'new',
    {
        shortdesc => 'Cadillac XLR-V',
        varSku    => 'nice-car',
        price     => 90_000,
        weight    => 3000,
        quantity  => 3,
    }
);

$options = {
                label   => 'flat rate, ship weight',
                enabled => 1,
                flatFee => 1.00,
                percentageOfPrice => 0,
                pricePerWeight    => 100,
                pricePerItem      => 0,
              };

$driver = WebGUI::Shop::ShipDriver::FlatRate->create($session, $options);

my $cart = WebGUI::Shop::Cart->newBySession($session);
$car->addToCart($car->getCollateral('variantsJSON', 'variantId', $crappyCar));

is($driver->calculate($cart), 1501, 'calculate by weight and flat fee work');

}

#----------------------------------------------------------------------------
# Cleanup
END {
    if (defined $driver and ref $driver eq 'WebGUI::Shop::ShipDriver::FlatRate') {
        $driver->delete;
    }
    if (defined $cart and ref $cart eq 'WebGUI::Shop::Cart') {
        $cart->delete;
    }
    if (defined $car and (ref($car) eq 'WebGUI::Asset::Sku::Product')) {
        $car->purge;
    }
}
