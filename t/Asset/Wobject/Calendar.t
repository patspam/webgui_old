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
use lib "$FindBin::Bin/../../lib";

##The goal of this test is to test the creation of Calendar Wobjects.

my @icalWrapTests = (
    {
        in      => 'Text is passed through with no problems',
        out     => 'Text is passed through with no problems',
        comment => 'Text passed through with no problems',
    },
    {
        in      => ',Escape more than one, multiple, commas,',
        out     => '\,Escape more than one\, multiple\, commas\,',
        comment => 'escape commas',
    },
    {
        in      => ';Escape more than one; multiple; semicolons;',
        out     => '\;Escape more than one\; multiple\; semicolons\;',
        comment => 'escape semicolons',
    },
    {
        in      => '\\Escape more than one\\ multiple\\ backslashes\\',
        out     => '\\\\Escape more than one\\\\ multiple\\\\ backslashes\\\\',
        comment => 'escape backslashes',
    },
    {
        in      => "lots\nand\nlots\nof\nnewlines\n",
        out     => 'lots\\nand\\nlots\\nof\\nnewlines\\n',
        comment => 'escape newlines',
    },
    {
                   #         1         2         3         4         5         6         7   V
                   #12345678901234567890123456789012345678901234567890123456789012345678901234567890
        in      => "There's not a day goes by I don't feel regret. Not because I'm in here, or because you think I should. I look back on the way I was then: a young, stupid kid who committed that terrible crime. I want to talk to him.",
        out     => "There's not a day goes by I don't feel regret. Not because I'm in here\\,\r\n or because you think I should. I look back on the way I was then: a\r\n young\\, stupid kid who committed that terrible crime. I want to talk to\r\n him.",
        comment => 'basic wrapping',
    },
);

use WebGUI::Test;
use WebGUI::Session;
use Test::More;
use Test::Deep;
use Data::Dumper;
use WebGUI::Asset::Wobject::Calendar;
use WebGUI::Asset::Event;

plan tests => 10 + scalar @icalWrapTests;

my $session = WebGUI::Test->session;

# Do our work in the import node
my $node = WebGUI::Asset->getImportNode($session);

my $versionTag = WebGUI::VersionTag->getWorking($session);
$versionTag->set({name=>"Calendar Test"});
WebGUI::Test->tagsToRollback($versionTag);

my $cal = $node->addChild({className=>'WebGUI::Asset::Wobject::Calendar'});
$versionTag->commit();

# Test for a sane object type
isa_ok($cal, 'WebGUI::Asset::Wobject::Calendar');

# Test addChild to make sure we can only add Event assets as children to the calendar
my $event = $cal->addChild({className=>'WebGUI::Asset::Event'});
isa_ok($event, 'WebGUI::Asset::Event','Can add Events as a child to the calendar.');

my $article = $cal->addChild({className=>"WebGUI::Asset::Wobject::Article"});
isnt(ref $article, 'WebGUI::Asset::Wobject::Article', "Can't add an article as a child to the calendar.");
ok(! defined $article, '... addChild returned undef');

my $dt = WebGUI::DateTime->new($session, mysql => '2001-08-16 8:00:00', time_zone => 'America/Chicago');

my $vars = {};
$cal->appendTemplateVarsDateTime($vars, $dt, "start");
cmp_deeply(
    $vars,
    {
        startMinute     => '00',
        startDayOfMonth => 16,
        startMonthName  => 'August',
        startMonthAbbr  => 'Aug',
        startEpoch      => 997966800,
        startHms        => '08:00:00',
        startM          => 'AM',
        startMeridiem   => 'AM',
        startDayName    => 'Thursday',
        startMdy        => '08-16-2001',
        startYmd        => '2001-08-16',
        startDmy        => '16-08-2001',
        startDayAbbr    => 'Thu',
        startDayOfWeek  => 4,
        startHour       => 8,
        startHour24     => 8,
        startMonth      => 8,
        startSecond     => '00',
        startYear       => 2001,
    },
    'Variables returned by appendTemplateVarsDateTime'
);

######################################################################
#
# getEventsIn
#
######################################################################

my $windowCal = $node->addChild({
    className => 'WebGUI::Asset::Wobject::Calendar',
    title     => 'Calendar for doing event window testing',
});

my $tz   = $session->datetime->getTimeZone();
my $bday = WebGUI::DateTime->new($session, WebGUI::Test->webguiBirthday);
my $dt   = $bday->clone->truncate(to => 'day');

my $startDt = $dt->cloneToUserTimeZone->subtract(days => 1);
my $endDt   = $dt->cloneToUserTimeZone->add(days => 1);

my $inside = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Inside window, no times, same day',
    startDate   => $bday->toDatabaseDate,
    endDate     => $bday->toDatabaseDate,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $inside2 = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Inside window, with times',
    startDate   => $bday->toDatabaseDate,
    endDate     => $bday->toDatabaseDate,
    startTime   => $bday->toDatabaseTime,
    endTime     => $bday->clone->add(hours => 1)->toDatabaseTime,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $outsideHigh = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Outside window, after time',
    startDate   => $endDt->clone->add(days => 2)->toDatabaseDate,
    endDate     => $endDt->clone->add(days => 3)->toDatabaseDate,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $outsideLow = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Outside window, before time',
    startDate   => $startDt->clone->subtract(days => 3)->toDatabaseDate,
    endDate     => $startDt->clone->subtract(days => 2)->toDatabaseDate,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $straddle = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Straddles the window, inclusive',
    startDate   => $startDt->clone->subtract(days => 1)->toDatabaseDate,
    endDate     => $endDt->clone->add(days => 1)->toDatabaseDate,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $straddleLow = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Straddles the window, lower side',
    startDate   => $startDt->clone->subtract(hours => 12)->toDatabaseDate,
    endDate     => $startDt->clone->add(hours => 12)->toDatabaseDate,
    startTime   => $startDt->clone->subtract(hours => 12)->toDatabaseTime,
    endTime     => $startDt->clone->add(hours => 12)->toDatabaseTime,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $straddleHigh = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Straddles the window, higher side',
    startDate   => $endDt->clone->subtract(hours => 12)->toDatabaseDate,
    endDate     => $endDt->clone->add(hours => 12)->toDatabaseDate,
    startTime   => $endDt->clone->subtract(hours => 12)->toDatabaseTime,
    endTime     => $endDt->clone->add(hours => 12)->toDatabaseTime,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $justBefore = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Just before the window.  Ending time coincident with window start',
    startDate   => $startDt->clone->subtract(hours => 1)->toDatabaseDate,
    endDate     => $startDt->toDatabaseDate,
    startTime   => $startDt->clone->subtract(hours => 1)->toDatabaseTime,
    endTime     => $startDt->toDatabaseTime,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $justAfter = $windowCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'Just after the window.  Start time coincident with window end',
    startDate   => $endDt->toDatabaseDate,
    endDate     => $endDt->clone->add(hours => 1)->toDatabaseDate,
    startTime   => $endDt->toDatabaseTime,
    endTime     => $endDt->clone->add(hours => 1)->toDatabaseTime,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $tag2 = WebGUI::VersionTag->getWorking($session);
$tag2->commit;
WebGUI::Test->tagsToRollback($tag2);

is(scalar @{ $windowCal->getLineage(['children'])}, 9, 'added events to the window calendar');

my @window = $windowCal->getEventsIn($startDt->toDatabase, $endDt->toDatabase);

#diag $startDt->toDatabase;
#diag join "\n", map { join ' ', $_->get('title'), $_->get('startDate'), $_->get('startTime')} @window;
#diag $endDt->toDatabase;

is(scalar @window, 4, 'getEventsIn returned 4 events');
cmp_bag(
    [ map { $_->get('title') } @window ],
    [ map { $_->get('title') } ($inside, $inside2, $straddle, $straddleHigh)],
    '..returns correct 4 events'
);

######################################################################
#
# viewWeek
#
######################################################################

my $weekCal = $node->addChild({
    className => 'WebGUI::Asset::Wobject::Calendar',
    title     => 'Calendar for doing event span testing, week',
});

my $allDayDt = $bday->cloneToUserTimeZone;

my $allDay = $weekCal->addChild({
    className   => 'WebGUI::Asset::Event',
    title       => 'An event with explicit times that lasts all day',
    startDate   => $allDayDt->toDatabaseDate,
    endDate     => $allDayDt->clone->add(days => 1)->toDatabaseDate,
    startTime   => $allDayDt->clone->truncate(to => 'day')->toDatabaseTime,
    endTime     => $allDayDt->clone->add(days => 1)->truncate(to => 'day')->toDatabaseTime,
    timeZone    => $tz,
}, undef, undef, {skipAutoCommitWorkflows => 1});

my $tag3 = WebGUI::VersionTag->getWorking($session);
$tag3->commit;
WebGUI::Test->tagsToRollback($tag3);

my $allVars = $weekCal->viewWeek({ start => $bday });
my @eventBins = ();
foreach my $day (@{ $allVars->{days} }) {
    if (exists $day->{events} and scalar @{ $day->{events} } > 0) {
        push @eventBins, $day->{dayOfWeek};
    }
}

cmp_deeply(
    \@eventBins,
    [ 4 ],
    'viewWeek: all day event is only in 1 day when time zones line up correctly'
);

################################################################
#
# wrapIcal
#
################################################################

#Any old calendar will do for these tests.

foreach my $test (@icalWrapTests) {
    my ($in, $out, $comment) = @{ $test }{ qw/in out comment/ };
    my $wrapOut = $cal->wrapIcal($in);
    is ($wrapOut, $out, $comment);
}

TODO: {
        local $TODO = "Tests to make later";
        ok(0, 'Lots more to test');
}
