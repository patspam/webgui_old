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
use WebGUI::Asset::Template;
use Exception::Class;
use Test::More tests => 37; # increment this value for each test you create
use Test::Deep;

my $session = WebGUI::Test->session;

my $list = WebGUI::Asset::Template->getList($session);
cmp_deeply($list, {}, 'getList with no classname returns an empty hashref');

my $tmplText = " <tmpl_var variable> <tmpl_if conditional>true</tmpl_if> <tmpl_loop loop>XY</tmpl_loop> ";
my %var = (
	variable=>"AAAAA",
	conditional=>1,
	loop=>[{},{},{},{},{}]
	);
my $output = WebGUI::Asset::Template->processRaw($session,$tmplText,\%var);
ok($output =~ m/\bAAAAA\b/, "processRaw() - variables");
ok($output =~ m/true/, "processRaw() - conditionals");
ok($output =~ m/\s(?:XY){5}\s/, "processRaw() - loops");

my $importNode = WebGUI::Asset::Template->getImportNode($session);
my $template = $importNode->addChild({className=>"WebGUI::Asset::Template", title=>"test", url=>"testingtemplates", template=>$tmplText, namespace=>'WebGUI Test Template'});
isa_ok($template, 'WebGUI::Asset::Template', "creating a template");

is($template->get('parser'), 'WebGUI::Asset::Template::HTMLTemplate', 'default parser is HTMLTemplate');

$var{variable} = "BBBBB";
$output = $template->process(\%var);
ok($output =~ m/\bBBBBB\b/, "process() - variables");
ok($output =~ m/true/, "process() - conditionals");
ok($output =~ m/\b(?:XY){5}\b/, "process() - loops");

my $newList = WebGUI::Asset::Template->getList($session, 'WebGUI Test Template');
ok(exists $newList->{$template->getId}, 'Uncommitted template exists returned from getList');

my $newList2 = WebGUI::Asset::Template->getList($session, 'WebGUI Test Template', "assetData.status='approved'");
ok(!exists $newList2->{$template->getId}, 'extra clause to getList prevents uncommitted template from being displayed');

$template->update({isDefault=>1});
is($template->get('isDefault'), 1, 'isDefault set to 1');
my $templateCopy = $template->duplicate();
is($templateCopy->get('isDefault'), 0, 'isDefault set to 0 on copy');

my $template3 = $importNode->addChild({
    className => "WebGUI::Asset::Template",
    title     => 'headBlock test',
    headBlock => "tag1 tag2 tag3",
    template  => "this is a template",
});

ok(!$template3->get('headBlock'),    'headBlock is empty');
is($template3->get('extraHeadTags'), 'tag1 tag2 tag3', 'extraHeadTags contains headBlock info');

my @atts = (
    {type => 'headScript', sequence => 1, url => 'bar'},
    {type => 'headScript', sequence => 0, url => 'foo'},
    {type => 'stylesheet', sequence => 0, url => 'style'},
    {type => 'bodyScript', sequence => 0, url => 'body'},
);

$template3->addAttachments(\@atts);
my $att3 = $template3->getAttachments('headScript');
is($att3->[0]->{url}, 'foo', 'has foo');
is($att3->[1]->{url}, 'bar', 'has bar');
is(@$att3, 2, 'proper size');

$template3->prepare;
ok(exists $session->style->{_link}->{style}, 'style in style');
ok(exists $session->style->{_javascript}->{$_}, "$_ in style") for qw(foo bar body);

# revision-ness of attachments

# sleep so the revisiondate isn't duplicated
sleep 1;

my $template3rev = $template3->addRevision();
my $att4 = $template3rev->getAttachments('headScript');
is($att4->[0]->{url}, 'foo', 'rev has foo');
is($att4->[1]->{url}, 'bar', 'rev has bar');
is(@$att4, 2, 'rev is proper size');

$template3rev->addAttachments([{type => 'headScript', sequence => 2, url => 'baz'}]);
$att4 = $template3rev->getAttachments('headScript');
$att3 = $template3->getAttachments('headScript');
is($att3->[0]->{url}, 'foo', 'original still has foo');
is($att3->[1]->{url}, 'bar', 'original still has bar');
is(@$att3, 2, 'original does not have new thing');

is($att4->[0]->{url}, 'foo', 'rev still has foo');
is($att4->[1]->{url}, 'bar', 'rev still has bar');
is($att4->[2]->{url}, 'baz', 'rev does have new thing');
is(@$att4, 3, 'rev is proper size');

$template3rev->purgeRevision();

my $brokenTemplate = $importNode->addChild({
    className => "WebGUI::Asset::Template",
    title     => 'Broken template',
    template  => q|<tmpl_if unclosedIf>If clause with no ending tag|,
});

# done checking revision stuff

WebGUI::Test->interceptLogging;
my $brokenOutput = $brokenTemplate->process({});
my $logError = $WebGUI::Test::logger_error;
my $brokenUrl = $brokenTemplate->getUrl;
my $brokenId  = $brokenTemplate->getId;
like($brokenOutput, qr/^There is a syntax error in this template/, 'process: returned error output contains boilerplate');
like($brokenOutput, qr/$brokenUrl/, '... and the template url');
like($brokenOutput, qr/$brokenId/, '... and the template id');
like($logError, qr/$brokenUrl/, 'process: logged error has the url');
like($logError, qr/$brokenId/, '... and the template id');

WebGUI::Test->tagsToRollback(WebGUI::VersionTag->getWorking($session));

