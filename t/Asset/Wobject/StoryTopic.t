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
use Data::Dumper;

use WebGUI::Test; # Must use this before any other WebGUI modules
use WebGUI::Session;
use WebGUI::Text;

#----------------------------------------------------------------------------
# Init
my $session         = WebGUI::Test->session;

#----------------------------------------------------------------------------
# Tests

my $tests = 18;
plan tests => 1 + $tests;

#----------------------------------------------------------------------------
# put your tests here

my $class  = 'WebGUI::Asset::Wobject::StoryTopic';
my $loaded = use_ok($class);

my $versionTag = WebGUI::VersionTag->getWorking($session);

my $archive    = WebGUI::Asset->getDefault($session)->addChild({className => 'WebGUI::Asset::Wobject::StoryArchive', title => 'My Stories', url => '/home/mystories'});

my $now = time();
my $nowFolder = $archive->getFolder($now);

my $yesterday = $now-24*3600;
my $newFolder = $archive->getFolder($yesterday);

my $creationDateSth = $session->db->prepare('update asset set creationDate=? where assetId=?');

my $pastStory = $newFolder->addChild({ className => 'WebGUI::Asset::Story', title => "Yesterday is history", keywords => 'andy,norton'});
$creationDateSth->execute([$yesterday, $pastStory->getId]);

my @staff       = qw/norton hadley mert trout/;
my @inmates     = qw/bogs red brooks andy heywood tommy jake skeet/;
my @characters  = (@staff, @inmates, );

my @stories = ();
my $storyHandler = {};

STORY: foreach my $name (@characters) {
    my $namedStory = $nowFolder->addChild({ className => 'WebGUI::Asset::Story', title => $name, keywords => $name, } );
    $storyHandler->{$name} = $namedStory;
    $creationDateSth->execute([$now, $namedStory->getId]);
}

$storyHandler->{bogs}->update({subtitle => 'drinking his food through a straw'});

my $topic;

SKIP: {

    skip "Unable to load module $class", $tests unless $loaded;

$topic = WebGUI::Asset->getDefault($session)->addChild({ className => 'WebGUI::Asset::Wobject::StoryTopic', title => 'Popular inmates in Shawshank Prison', keywords => join(',', @inmates)});

isa_ok($topic, 'WebGUI::Asset::Wobject::StoryTopic', 'made a Story Topic');
$topic->update({
    storiesPer   => 6,
    storiesShort => 3,
});

$versionTag->commit;

################################################################
#
#  viewTemplateVariables
#
################################################################

my $templateVars;
$templateVars = $topic->viewTemplateVariables();

cmp_deeply(
    $templateVars,
    superhashof({
        rssUrl  => $topic->getRssFeedUrl,
        atomUrl => $topic->getAtomFeedUrl,
    }),
    'viewTemplateVars: RSS and Atom feed template variables'
);
cmp_deeply(
    $templateVars->{story_loop},
    [
        {
            title        => 'bogs',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'bogs'}->getId),
            creationDate => $now,
        },
        {
            title        => 'red',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'red'}->getId),
            creationDate => $now,
        },
        {
            title        => 'brooks',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'brooks'}->getId),
            creationDate => $now,
        },
    ],
    'viewTemplateVars has right number and contents in the story_loop'
);

ok(
    ! exists $templateVars->{topStoryTitle}
 && ! exists $templateVars->{topStoryUrl}
 && ! exists $templateVars->{topStoryCreationDate}
 && ! exists $templateVars->{topStorySubtitle},
    'topStory variables not present unless in standalone mode'
);
ok(! $templateVars->{standAlone}, 'viewTemplateVars: not in standalone mode');

$topic->{_standAlone} = 1;
$templateVars = $topic->viewTemplateVariables();
cmp_deeply(
    $templateVars->{story_loop},
    [
        {
            title        => 'red',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'red'}->getId),
            creationDate => $now,
        },
        {
            title        => 'brooks',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'brooks'}->getId),
            creationDate => $now,
        },
        {
            title        => 'andy',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'andy'}->getId),
            creationDate => $now,
        },
        {
            title        => 'heywood',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'heywood'}->getId),
            creationDate => $now,
        },
        {
            title        => 'tommy',
            url          => $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'tommy'}->getId),
            creationDate => $now,
        },
    ],
    'viewTemplateVars has right number and contents in the story_loop in standalone mode.  Top story not present in story_loop'
);

is($templateVars->{topStoryTitle}, 'bogs', '... topStoryTitle');
is(
    $templateVars->{topStorySubtitle},
    'drinking his food through a straw',
    '... topStorySubtitle'
);
is(
    $templateVars->{topStoryUrl},
    $session->url->append($topic->getUrl, 'func=viewStory;assetId='.$storyHandler->{'bogs'}->getId),
    '... topStoryUrl'
);
is($templateVars->{topStoryCreationDate}, $now, '... topStoryCreationDate');
ok($templateVars->{standAlone}, '... standAlone mode=1');

my $storage = WebGUI::Storage->create($session);
WebGUI::Test->storagesToDelete($storage);
$storyHandler->{bogs}->setPhotoData([{
    caption   => "Octopus seen at the scene of Mrs. Dufresne's murder.",
    byLine    => 'Elmo Blatch',
    alt       => 'The suspect',
}]);

$templateVars = $topic->viewTemplateVariables();
ok(
    ! exists $templateVars->{topStoryImageUrl}
 && ! exists $templateVars->{topStoryImageByLine}
 && ! exists $templateVars->{topStoryImageAlt}
 && ! exists $templateVars->{topStoryImageCaption},
    '... no photo template variables, since there is no storage location'
);
my $bogsData = $storyHandler->{bogs}->getPhotoData();
$bogsData->[0]->{storageId} = $storage->getId;
$storyHandler->{bogs}->setPhotoData($bogsData);
$templateVars = $topic->viewTemplateVariables();
ok(
    ! exists $templateVars->{topStoryImageUrl}
 && ! exists $templateVars->{topStoryImageByLine}
 && ! exists $templateVars->{topStoryImageAlt}
 && ! exists $templateVars->{topStoryImageCaption},
    '... no photo template variables, since there is no file in the storage location'
);

$storage->addFileFromFilesystem(WebGUI::Test->getTestCollateralPath('gooey.jpg'));
$templateVars = $topic->viewTemplateVariables();
cmp_deeply(
    [ @{ $templateVars }{qw/topStoryImageUrl topStoryImageByline topStoryImageAlt topStoryImageCaption/} ],
    [
       $storage->getUrl('gooey.jpg'), 
       'Elmo Blatch',
       'The suspect',
       "Octopus seen at the scene of Mrs. Dufresne's murder.",
    ],
    '... photo template variables set'
);

$topic->update({
    storiesShort => 20,
});

$topic->{_standAlone} = 0;

$templateVars = $topic->viewTemplateVariables;
my @topicInmates = map { $_->{title} } @{ $templateVars->{story_loop} };
cmp_deeply(
    \@topicInmates,
    [@inmates, 'Yesterday is history'], #extra for pastStory
    'viewTemplateVariables: is only finding things with its keywords'
);

$session->scratch->set('isExporting', 1);
$topic->update({
    storiesShort => 3,
});
$templateVars = $topic->viewTemplateVariables;
cmp_deeply(
    $templateVars->{story_loop},
    [
        {
            title        => 'bogs',
            url          => $storyHandler->{'bogs'}->getUrl,
            creationDate => $now,
        },
        {
            title        => 'red',
            url          => $storyHandler->{'red'}->getUrl,
            creationDate => $now,
        },
        {
            title        => 'brooks',
            url          => $storyHandler->{'brooks'}->getUrl,
            creationDate => $now,
        },
    ],
    '... export mode, URLs are the regular story URLs'
);
cmp_deeply(
    $templateVars,
    superhashof({
        rssUrl  => $topic->getStaticRssFeedUrl,
        atomUrl => $topic->getStaticAtomFeedUrl,
    }),
    '... export mode, RSS and Atom feed template variables show the static url'
);
$session->scratch->delete('isExporting');

################################################################
#
#  getRssFeedItems
#
################################################################

$topic->update({
    storiesPer   => 3,
});
cmp_deeply(
    $topic->getRssFeedItems(),
    [
        {
            title => 'bogs',
            description => ignore(),
            'link'      => ignore(),
            date        => ignore(),
            author      => ignore(),
        },
        {
            title => 'red',
            description => ignore(),
            'link'      => ignore(),
            date        => ignore(),
            author      => ignore(),
        },
        {
            title => 'brooks',
            description => ignore(),
            'link'      => ignore(),
            date        => ignore(),
            author      => ignore(),
        },
    ],
    'rssFeedItems'
);

}

#----------------------------------------------------------------------------
# Cleanup
END {
    $archive->purge if $archive;
    $topic->purge   if $topic;
    if ($versionTag) {
        $versionTag->rollback;
    }
}
