#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use FindBin;
use strict;
use lib "$FindBin::Bin/lib";
use WebGUI::Test;
use WebGUI::Session;
use WebGUI::AdSpace::Ad;

use Test::More;
use Test::Deep;

my $newAdSpaceSettings = {
    name               => "newAdSpaceName",
    title              => "Ad Space",
    description        => 'This is a space reserved for ads',
    costPerImpression  => '1.00',
    costPerClick       => '1.00',
    minimumImpressions => 100,
    minimumClicks      => 200,
    groupToPurchase    => "7",
    width              => "400",
    height             => "300",
};

my $numTests = 26; # increment this value for each test you create
$numTests += 2 * scalar keys %{ $newAdSpaceSettings };
++$numTests; ##For conditional testing on module load

plan tests => $numTests;

my $loaded = use_ok('WebGUI::AdSpace');

my $session = WebGUI::Test->session;
my ($adSpace, $alfred, $alfred2, $bruce, $catWoman, $twoFaceClone, $defaultAdSpace );
my ($jokerAd, $penguinAd, $twoFaceAd);

SKIP: {

	skip "Unable to load WebGUI::AdSpace", $numTests-1 unless $loaded;

	$adSpace = WebGUI::AdSpace->create($session, {name=>"Alfred"});

	isa_ok($adSpace, 'WebGUI::AdSpace');

	my $data = $session->db->quickHashRef("select adSpaceId, name from adSpace where adSpaceId=?",[$adSpace->getId]);

	ok(exists $data->{adSpaceId}, "create()");
	is($data->{name}, $adSpace->get("name"), "get()");
	is($data->{adSpaceId}, $adSpace->getId, "getId()");

    $alfred = WebGUI::AdSpace->newByName($session, 'Alfred');

    cmp_deeply($adSpace, $alfred, 'newByName returns identical object if name exists');

    $bruce = WebGUI::AdSpace->newByName($session, 'Bruce');
    is($bruce, undef, 'newByName returns undef if the name does not exist');

    $bruce = WebGUI::AdSpace->new($session, $session->getId);
    is($bruce, undef, 'new returns undef if the id does not exist');

    $alfred2 = WebGUI::AdSpace->create($session);
    is($alfred2, undef, 'create returns undef unless you pass it a name');

    $alfred2 = WebGUI::AdSpace->create($session, {name => 'Alfred'});
    is($alfred2, undef, 'create returns undef if the name already exists');

	isa_ok($alfred->session, 'WebGUI::Session');

    undef $alfred2;

    $alfred->set({title => "Alfred's Ad"});
    is($alfred->get('title'), "Alfred's Ad", "get, set work on title");

    $bruce = WebGUI::AdSpace->create($session, {name => 'Bruce'});
    $bruce->set({title => "Bruce's Ad"});

    $catWoman = WebGUI::AdSpace->create($session, {name => 'CatWoman'});
    $catWoman->set({title => "CatWoman's Ad"});

    my $adSpaces = WebGUI::AdSpace->getAdSpaces($session);

    cmp_deeply($adSpaces, [$alfred, $bruce, $catWoman], 'getAdSpaces returns all AdSpaces in alphabetical order by title');

    $catWoman->set($newAdSpaceSettings);

    foreach my $setting (keys %{ $newAdSpaceSettings } ) {
        is($newAdSpaceSettings->{$setting}, $catWoman->get($setting),
            sprintf "set and get for %s", $setting);
    }

    ##Bare call to set doesn't change anything
    $catWoman->set();

    foreach my $setting (keys %{ $newAdSpaceSettings } ) {
        is($newAdSpaceSettings->{$setting}, $catWoman->get($setting),
            sprintf "empty call to set does not change %s", $setting);
    }

    ##Create a set of ads for general purpose testing

    ##The Joker and Penguin Ads go in the bruce adSpace
    ##The Two Face ad goes in the catWoman adSpace

    $jokerAd   = WebGUI::AdSpace::Ad->create($session, $bruce->getId,
    	{
            title      => 'Joker',
            url        => '/ha_ha',
            type       => 'rich',
            richMedia  => 'Joker',
            priority   => 2,
            isActive   => 1,
        }
    );
    $penguinAd = WebGUI::AdSpace::Ad->create($session, $bruce->getId,
    	{
            title      => 'Penguin',
            url        => '/fishy',
            type       => 'rich',
            richMedia  => 'Penguin',
            priority   => 3,
            isActive   => 1,
        }
    );
    $twoFaceAd = WebGUI::AdSpace::Ad->create($session, $catWoman->getId,
    	{
            title      => 'Two Face',
            url        => '/dent',
            type       => 'rich',
            richMedia  => 'Two Face',
            priority   => 500,
            isActive   => 1,
            clicksBought      => 0,
            impressionsBought => 0,
        }
    );

    ##getAds
    my @bruceAdTitles = map { $_->get('title') } @{ $bruce->getAds };
    my @catWomanAdTitles = map { $_->get('title') } @{ $catWoman->getAds };

    cmp_bag(\@bruceAdTitles,    ['Joker', 'Penguin'], 'Got the set of Ads for bruce');
    cmp_bag(\@catWomanAdTitles, ['Two Face'],         'Got the set of Ads for catWoman');

    ##countClicks
    my $penguinUrl = WebGUI::AdSpace->countClick($session, $penguinAd->getId);
    is($penguinUrl, $penguinAd->get('url'), 'clicking on the penguin ad returns the penguin url');
    WebGUI::AdSpace->countClick($session, $penguinAd->getId);
    WebGUI::AdSpace->countClick($session, $penguinAd->getId);

    my $jokerUrl = WebGUI::AdSpace->countClick($session, $jokerAd->getId);
    is($jokerUrl, $jokerAd->get('url'), 'clicking on the joker ad returns the joker url');

    my $twoFaceUrl = WebGUI::AdSpace->countClick($session, $twoFaceAd->getId);
    is($twoFaceUrl, $twoFaceAd->get('url'), 'clicking on the twoFace ad returns the twoFace url');

    my ($penguinClicks) = $session->db->quickArray('select clicks from advertisement where adId=?',[$penguinAd->getId]); 
    is($penguinClicks, 3, 'counted penguin clicks correctly');

    my ($jokerClicks)   = $session->db->quickArray('select clicks from advertisement where adId=?',[$jokerAd->getId]); 
    is($jokerClicks, 1, 'counted joker clicks correctly');

    my ($twoFaceClicks) = $session->db->quickArray('select clicks from advertisement where adId=?',[$twoFaceAd->getId]); 
    is($twoFaceClicks, 1, 'counted twoFace clicks correctly');

    ##displayImpression
    my ($twoFaceImpressions, $twoFacePriority) =
        $session->db->quickArray('select impressions,nextInPriority from advertisement where adId=?',[$twoFaceAd->getId]); 
    is($catWoman->displayImpression(1), $twoFaceAd->get('renderedAd'), 'displayImpression returns the ad');
    cmp_bag(
        [$twoFaceImpressions, $twoFacePriority],
        [$session->db->quickArray('select impressions,nextInPriority from advertisement where adId=?',[$twoFaceAd->getId])],
        'displayImpressions: impresssions and nextInPriority are not updated when dontCount=1',
    );

    $catWoman->displayImpression();
    my $twoFaceTime = time();
    is(
        $session->db->quickArray('select impressions from advertisement where adId=?',[$twoFaceAd->getId]),
        1, 'displayImpression added 1 impression'
    );
    my ($newTwoFacePriority) = $session->db->quickArray('select nextInPriority from advertisement where adId=?',[$twoFaceAd->getId]);
    isnt($newTwoFacePriority, $twoFacePriority, 'displayImpression changed the nextInPriority');
    cmp_ok(
        abs($twoFaceTime + $twoFaceAd->get('priority') - $newTwoFacePriority),
        '<=',
        '2',
        'displayImpression set the nextInPriority correctly'
    );

    $twoFaceClone = WebGUI::AdSpace::Ad->new($session, $twoFaceAd->getId);
    is($twoFaceClone->get('isActive'), 0, 'displayImpression deactivates an ad if enough impressions and clicks are bought');

}

END {
    foreach my $ad_space ($adSpace, $bruce, $alfred, $alfred2, $catWoman, $defaultAdSpace ) {
        if (defined $ad_space and ref $ad_space eq 'WebGUI::AdSpace') {
            $ad_space->delete;
        }
    }

    foreach my $advert ($jokerAd, $penguinAd, $twoFaceClone, $twoFaceAd) {
        if (defined $advert and ref $advert eq 'WebGUI::AdSpace::Ad') {
            $advert->delete;
        }
    }

}
