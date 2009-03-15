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
use lib "$FindBin::Bin/../lib";
use Test::More;
use Scalar::Util qw/refaddr/;
use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;
use WebGUI::Asset;
use WebGUI::Shop::Cart;
use WebGUI::TestException;


#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;
my $i18n = WebGUI::International->new($session, "Shop");

#----------------------------------------------------------------------------
# Tests

plan tests => 23;        # Increment this number for each test you create

#----------------------------------------------------------------------------
# put your tests here

throws_deeply ( sub { my $cart = WebGUI::Shop::Cart->newBySession(); }, 
    'WebGUI::Error::InvalidObject', 
    {
        error       => 'Need a session.',
        got         => '',
        expected    => 'WebGUI::Session',
    },
    'newBySession takes an exception to not giving it a session variable'
);

my $cart = WebGUI::Shop::Cart->newBySession($session);

isa_ok($cart, "WebGUI::Shop::Cart");
isa_ok($cart->session, "WebGUI::Session");

my $message = $i18n->get('empty cart') . "\n";
like($cart->www_view, qr/There are no items currently in your cart./, 'Display empty cart message');

my $root = WebGUI::Asset->getRoot($session);
my $product = $root->addChild({
    className=>"WebGUI::Asset::Sku::Donation",
    title=>"Test Product",
    });
$product->applyOptions({price=>50.25});
my $item = $cart->addItem($product);
isa_ok($item, "WebGUI::Shop::CartItem");
isa_ok($item->cart, "WebGUI::Shop::Cart", "Does the item have a cart?");
is(ref($item->get), "HASH", "Do we have a hash of properties?");

is($item->get("quantity"), 1, "Should have 1 of these in the cart.");
is($item->adjustQuantity(2), 3, "adjustQuantity() should tell us how many items of this type are in the cart");
is($item->get("quantity"), 3, "Should have 3 of these in the cart.");
is(scalar(@{$cart->getItems}), 1, "Should have 1 item type in cart regardless of quanity.");

$item->update({shippingAddressId => "XXXX"});
is($item->get("shippingAddressId"), "XXXX", "Can set values to the cart item properties.");

like($cart->getId, qr/[A-Za-z0-9\_\-]{22}/, "Id looks like a guid.");

is(ref($cart->get), "HASH", "Cart properties are a hash reference.");
is($cart->get("sessionId"), $session->getId, "Can retrieve a value from the cart properties.");

is($cart->formatCurrency(11.1), "11.10", "can format currency");

is($cart->calculateSubtotal, 150.75, "can determine the price of the items in the cart");

$cart->update({shippingAddressId => "XXXX"});
is($cart->get("shippingAddressId"), "XXXX", "Can set values to the cart properties.");

isa_ok($cart->getAddressBook, "WebGUI::Shop::AddressBook", "can get an address book");

$cart->empty;
is($session->db->quickScalar("select count(*) from cartItem where cartId=?",[$cart->getId]), 0, "Items are removed from cart.");

my $session2 = WebGUI::Session->open(WebGUI::Test->root, WebGUI::Test->file);
$session2->user({userId => 3});
my $cart2 = WebGUI::Shop::Cart->newBySession($session2);
isnt(
    refaddr $cart->getAddressBook,
    refaddr $cart2->getAddressBook,
    'Different carts with different sessions have different AddressBooks'
);
$cart2->delete;

my $cart3 = WebGUI::Shop::Cart->newBySession($session);
isnt(
    refaddr $cart->getAddressBook,
    refaddr $cart3->getAddressBook,
    'Different carts with same sessions will each have different AddressBooks since no book has been assigned yet.'
);
$cart3->delete;

$cart->delete;
is($cart->delete, undef, "Can destroy cart.");


$product->purge;

#----------------------------------------------------------------------------
# Cleanup
END {
    $session2->close;
}
