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
use JSON;
use Data::Dumper;

use Test::More; # increment this value for each test you create
use Test::Deep;

my $session = WebGUI::Test->session;

my $numTests = 4;

$numTests += 1; #For the use_ok

plan tests => $numTests;

my $macro = 'WebGUI::Macro::MiniCart';
my $loaded = use_ok($macro);

my $cart = WebGUI::Shop::Cart->newBySession($session);
my $donation = WebGUI::Asset->getRoot($session)->addChild({
    className => 'WebGUI::Asset::Sku::Donation',
    title     => 'Charitable donation',
    url       => 'Telethon',
    defaultPrice => 10.00,
});

my $template = setupJSONtemplate($session);

SKIP: {

skip "Unable to load $macro", $numTests-1 unless $loaded;

    my $json;
    my $templateVars;

    $json = WebGUI::Macro::MiniCart::process($session, $template->getId);
    $templateVars = JSON::from_json($json);
    cmp_deeply(
        $templateVars,
        {
            totalPrice => '0',
            totalItems => '0',
            items      => [],
        },
        'Empty cart works'
    );

    my $item1 = $cart->addItem($donation);
    $json = WebGUI::Macro::MiniCart::process($session, $template->getId);
    $templateVars = JSON::from_json($json);
    cmp_deeply(
        $templateVars,
        {
            totalPrice => '10',
            totalItems => '1',
            items      => [
                {
                    name     => $donation->getConfiguredTitle(),
                    quantity => 1,
                    price    => 10,
                    url      => $donation->getUrl('shop=cart;method=viewItem;itemId='.$item1->getId),
                },
            ],
        },
        'Cart with one item works'
    );

    my $item2 = $cart->addItem($donation);
    $json = WebGUI::Macro::MiniCart::process($session, $template->getId);
    $templateVars = JSON::from_json($json);
    cmp_deeply(
        $templateVars,
        {
            totalPrice => '20',
            totalItems => '2',
            items      => bag(
                {
                    name     => $donation->getConfiguredTitle(),
                    quantity => 1,
                    price    => 10,
                    url      => $donation->getUrl('shop=cart;method=viewItem;itemId='.$item1->getId),
                },
                {
                    name     => $donation->getConfiguredTitle(),
                    quantity => 1,
                    price    => 10,
                    url      => $donation->getUrl('shop=cart;method=viewItem;itemId='.$item2->getId),
                },
            ),
        },
        'Cart with two items works'
    );

    $item2->setQuantity(9);
    $json = WebGUI::Macro::MiniCart::process($session, $template->getId);
    $templateVars = JSON::from_json($json);
    cmp_deeply(
        $templateVars,
        {
            totalPrice => '100',
            totalItems => '10',
            items      => bag(
                {
                    name     => $donation->getConfiguredTitle(),
                    quantity => 1,
                    price    => 10,
                    url      => $donation->getUrl('shop=cart;method=viewItem;itemId='.$item1->getId),
                },
                {
                    name     => $donation->getConfiguredTitle(),
                    quantity => 9,
                    price    => 10,
                    url      => $donation->getUrl('shop=cart;method=viewItem;itemId='.$item2->getId),
                },
            ),
        },
        'Cart with two items and multiple quantities works'
    );

}

END {
    $cart->delete;
    $donation->purge;
    $template->purge;
}

sub setupJSONtemplate {
    my ($session) = @_;
    my $templateBody = <<EOTMPL;
    {
    "totalPrice":<tmpl_var totalPrice>,
    "totalItems":<tmpl_var totalItems>,
    "items":[
        <tmpl_loop items>
        {
            "name":"<tmpl_var name>",
            "quantity":"<tmpl_var quantity>",
            "price":"<tmpl_var price>",
            "url":"<tmpl_var url>"
        }<tmpl_unless __last__>,</tmpl_unless>
        </tmpl_loop>
    ]
    }
EOTMPL
    my $template = WebGUI::Asset->getImportNode($session)->addChild({className=>'WebGUI::Asset::Template', namespace => 'Shop/MiniCart', template=>$templateBody});
    return $template;
}
