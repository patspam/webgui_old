#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

# XXX I (chrisn) started this file to test the features I added to the
# Collaboration / Post system for 7.5, but didn't have the time available to me
# to do a full test suite for the Post Wobject. This means that this test suite
# is *largely incomplete* and should be finished. What is here *is* the
# following:
#
#
# 1. The basic framework for a test suite for the Post Asset.
# Includes setup, cleanup, boilerplate, etc. Basically the really boring,
# repetitive parts of the test that you don't want to write yourself.
# 2. The tests for the features I've implemented; namely, functionality and
# general access controls on who can edit a post.

use FindBin;
use strict;
use lib "$FindBin::Bin/../lib";
use WebGUI::Test;
use WebGUI::Session;
use Test::More tests => 9; # increment this value for each test you create
use WebGUI::Asset::Wobject::Collaboration;
use WebGUI::Asset::Post;
use WebGUI::Asset::Post::Thread;
use WebGUI::User;
use WebGUI::Group;

my $session = WebGUI::Test->session;

# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

# Grab a named version tag
my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Collab setup"});

# Need to create a Collaboration system in which the post lives.
my @addArgs = ( undef, undef, { skipAutoCommitWorkflows => 1, skipNotification => 1 } );

my $collab = $node->addChild({className => 'WebGUI::Asset::Wobject::Collaboration', editTimeout => '1'}, @addArgs);

# The Collaboration system must be committed before a post can be made.

# Need to do $post->canEdit tests, which test group membership. Therefore,
# create three users and a group for the process. One user will be doing the
# posting. This user will *not* be able to edit the post after the editTimeout
# has expired. The second user will be in the groupToEditPosts group, and *will*
# be able to edit the post. The third user will be in the groupIdEdit group,
# which is *also* allowed edit rights for the post after the timeout has
# expired.
my $postingUser         = WebGUI::User->new($session, 'new');
my $otherUser           = WebGUI::User->new($session, 'new');
my $groupIdEditUser     = WebGUI::User->new($session, 'new');
my $groupToEditPost     = WebGUI::Group->new($session, $collab->get('groupToEditPost'));
my $groupIdEditGroup    = WebGUI::Group->new($session, $collab->get('groupIdEdit'));
WebGUI::Test->usersToDelete($postingUser, $otherUser, $groupIdEditUser);
$postingUser->username('userForPosting');
$otherUser->username('otherUser');
WebGUI::Test->groupsToDelete($groupToEditPost, $groupIdEditGroup);

# Add the posting user to the group allowd to post.
$postingUser->addToGroups([$collab->get('postGroupId')]);

# Add $otherUser to $groupToEditPost so that they can edit the posts after the
# timeout has expired.
$otherUser->addToGroups([$groupToEditPost->getId]);

# Similarly, add $groupIdEditUser to $groupIdEditGroup so that they, too, can
# edit posts after the timeout has expired.
$groupIdEditUser->addToGroups([$groupIdEditGroup->getId]);

# We need to become $postingUser to ensure that the canEdit tests below use
# $postingUser's credentials rather than the default user assigned to the
# WebGUI::Test->session user.
$session->user({userId => $postingUser->userId});

# finally, add the post to the collaboration system
my $props = {
    className   => 'WebGUI::Asset::Post::Thread',
    content     => 'hello, world!',
};

my $post = $collab->addChild($props, @addArgs);

$versionTag->commit();
WebGUI::Test->tagsToRollback($versionTag);

# Test for a sane object type
isa_ok($post, 'WebGUI::Asset::Post::Thread');

# make the posting user own the post 

# the collab system's properties are correct, the post has been posted and
# belongs to the correct user. It's time to carry out the $post->canEdit tests.
# sleep one second to ensure that the editTimeout has expired for $postingUser.
# Then do the tests. ->canEdit() reads the user field from the session object,
# so for the test that's supposed to pass (for $otherUser, who's in
# $groupToEditPost), we need to change the session user a second time. The same
# applies for $groupIdEditUser, for a total of three user changes.
sleep 1;

ok(!$post->canEdit(), "Posting user can't edit after editTime has passed");

$session->user({userId => $otherUser->userId});
ok($post->canEdit(), "User in groupToEditPost group can edit post after the timeout");

$session->user({userId => $groupIdEditUser->userId});
ok($post->canEdit(), "User in groupIdEditUserGroup group can edit post after the timeout");

# getSynopsisAndContent

my ($synopsis, $content) = $post->getSynopsisAndContent('', q|Brandheiße Neuigkeiten rund um's Klettern für euch aus der Region |);
is($synopsis, q|Brandheiße Neuigkeiten rund um's Klettern für euch aus der Region |, 'getSynopsisAndContent: UTF8 characters okay');

$post->update({synopsis => $synopsis});

##There is a bug in DBD::mysql with not properly encoding 8-bit characters.  Also, HTML::Entities produces
##8-bit utf8 (not strict) characters.  So we write a quick test to make sure our patch in splitTag works correctly.
my $dbPost = WebGUI::Asset->newByDynamicClass($session, $post->getId);
like($dbPost->get('synopsis'), qr/Brandhei.e Neuigkeiten rund um's Klettern f.r euch aus der Region /, 'patch test for DBD::Mysql and HTML::Entities');

($synopsis, $content) = $post->getSynopsisAndContent('', q|less than &lt; greater than &gt;|);
is($synopsis, q|less than &lt; greater than &gt;|, '... HTML escaped characters okay');

($synopsis, $content) = $post->getSynopsisAndContent('', q|<p>less than &lt; greater than &gt;</p>|);
is($synopsis, q|less than < greater than >|, '... HTML entities decoded by HTML::splitTag');

TODO: {
    local $TODO = "Tests to make later";
	ok(0, 'Whole lot more work to do here');
}

# vim: syntax=perl filetype=perl
