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
use lib "$FindBin::Bin/../lib";

use WebGUI::Test;
use WebGUI::Session;

use Test::More;
use Test::MockObject;
use HTML::TokeParser;

my $numTests = 2;

my @iconTests = fetchTestSet();

$numTests += scalar(@iconTests) * 4;

plan tests => $numTests;

my $session = WebGUI::Test->session;

####################################################
#
# Setup code
# Save the original user profile field toolbar
# Force $session->url->getRequestedUrl to return something useful
#
####################################################

my $origToolbar = $session->user->profileField('toolbar');
my $toolbars = $session->url->extras('toolbar/');

my $newRequest = Test::MockObject->new;
my $requestedUrl = '/home/depot';
$newRequest->set_bound('uri', \$requestedUrl);
$session->{_request} = $newRequest;

my $i18n = WebGUI::International->new($session, 'Icon');

####################################################
#
# getBaseURL
#
####################################################

$session->user->profileField('toolbar', 'useLanguageDefault');
is($session->icon->getBaseURL, $toolbars.'bullet/', 'getBaseUrl: default English toolbar is bullet');

$session->user->profileField('toolbar', 'mullet');
is($session->icon->getBaseURL, $toolbars.'mullet/', 'getBaseUrl: fetch user preference of mullet toolbar');

$session->user->profileField('toolbar', $origToolbar);

####################################################
#
# Most icon methods
#
####################################################

foreach my $test (@iconTests) {
	my $method = $test->{method};
	my $label = $i18n->get($test->{label});

	my $icon = $session->icon->$method($test->{urlParam});

	my ($url) = linkAndText($icon, 'a', 'href');
	is($url, $session->url->gateway($requestedUrl, $test->{urlParam}), "$method: url okay");

	my ($alt, $title) = linkAndText($icon, 'img', 'alt', 'title');
	is($alt, $label, "$method: alt okay");
	is($title, $label, "$method: title okay");

	$icon = $session->icon->copy($test->{urlParam2}, '/lowes');
	($url) = linkAndText($icon, 'a', 'href');
	is($url, $session->url->gateway('/lowes', $test->{urlParam2}), "$method: manual url okay");

}


sub linkAndText {
	my ($text, $tag, @params) = @_;
	my $p = HTML::TokeParser->new(\$text);

	my $token = $p->get_tag($tag);

	my @parsedParams = map { $token->[1]{$_} || '-' } @params;

	return @parsedParams;
}

####################################################
#
# Pick up tests
# drag
# disabled for moveUp and moveDown
# confirmText for delete
#
####################################################

my $icon = $session->icon->drag();

END: {
	$session->user->profileField('toolbar', $origToolbar);
}

sub fetchTestSet {
	return (
		{
			method    => 'copy',
			label     => 'Copy',
			urlParam  => 'func=copy',
			urlParam2 => 'op=copy',
		},
		{
			method    => 'cut',
			label     => 'Cut',
			urlParam  => 'func=cut',
			urlParam2 => 'op=cut',
		},
		{
			method    => 'delete',
			label     => 'Delete',
			urlParam  => 'func=delete',
			urlParam2 => 'op=delete',
		},
		{
			method    => 'edit',
			label     => 'Edit',
			urlParam  => 'func=edit',
			urlParam2 => 'op=edit',
		},
		{
			method    => 'export',
			label     => 'Export',
			urlParam  => 'func=export',
			urlParam2 => 'op=export',
		},
		{
			method    => 'locked',
			label     => 'locked',
			urlParam  => 'func=locked',
			urlParam2 => 'op=locked',
		},
		{
			method    => 'manage',
			label     => 'Manage',
			urlParam  => 'func=manage',
			urlParam2 => 'op=manage',
		},
		{
			method    => 'moveBottom',
			label     => 'Move To Bottom',
			urlParam  => 'func=moveBottom',
			urlParam2 => 'op=moveBottom',
		},
		{
			method    => 'moveLeft',
			label     => 'Move Left',
			urlParam  => 'func=moveLeft',
			urlParam2 => 'op=moveLeft',
		},
		{
			method    => 'moveRight',
			label     => 'Move Right',
			urlParam  => 'func=moveRight',
			urlParam2 => 'op=moveRight',
		},
		{
			method    => 'moveTop',
			label     => 'Move To Top',
			urlParam  => 'func=moveTop',
			urlParam2 => 'op=moveTop',
		},
		{
			method    => 'moveUp',
			label     => 'Move Up',
			urlParam  => 'func=moveUp',
			urlParam2 => 'op=moveUp',
		},
		{
			method    => 'shortcut',
			label     => 'Create Shortcut',
			urlParam  => 'func=shortcut',
			urlParam2 => 'op=shortcut',
		},
		{
			method    => 'view',
			label     => 'View',
			urlParam  => 'func=view',
			urlParam2 => 'op=view',
		},
	);
}
