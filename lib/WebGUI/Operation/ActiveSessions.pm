package WebGUI::Operation::ActiveSessions;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2007 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::AdminConsole;
use WebGUI::International;
use WebGUI::Paginator;
use WebGUI::SQL;

=head1 NAME

Package WebGUI::Operations::ActiveSessions

=head1 DESCRIPTION

Operation handler for displaying and killing active sessions.

=cut

#-------------------------------------------------------------------

=head2 www_killSession ( )

This method can be called directly, but is usually called
from www_viewActiveSessions. It ends the active session in
$session->form->process("sid").  Afterwards, it calls www_viewActiveSessions.

=cut

sub www_killSession {
	my $session = shift;
	return www_viewActiveSessions($session) if $session->form->process("sid") eq $session->var->get("sessionId");
	return $session->privilege->adminOnly() unless ($session->user->isInGroup(3));
	$session->db->write("delete from userSession where sessionId=?",[$session->form->process("sid")]);
	$session->db->write("delete from userSessionScratch where sessionId=?", [$session->form->process("sid")]);
	return www_viewActiveSessions($session);
}

#-------------------------------------------------------------------

=head2 www_viewActiveSessions ( )

Display a list of all active user sessions, along with an icon to
delete (kill) each one via www_killSession

=cut

sub www_viewActiveSessions {
	my $session = shift;
        return $session->privilege->adminOnly() unless ($session->user->isInGroup(3));
	my ($output, $p, @row, $i, $sth, %data);
	tie %data, 'Tie::CPHash';
	$sth = $session->db->read("select users.username,users.userId,userSession.sessionId,userSession.expires,
		userSession.lastPageView,userSession.lastIP from users,userSession where users.userId=userSession.userId
		and users.userId<>1 order by users.username,userSession.lastPageView desc");
	while (%data = $sth->hash) {
                $row[$i] = '<tr class="tableData"><td>'.$data{username}.' ('.$data{userId}.')</td>';
                $row[$i] .= '<td>'.$data{sessionId}.'</td>';
                $row[$i] .= '<td>'.$session->datetime->epochToHuman($data{expires}).'</td>';
                $row[$i] .= '<td>'.$session->datetime->epochToHuman($data{lastPageView}).'</td>';
                $row[$i] .= '<td>'.$data{lastIP}.'</td>';
		$row[$i] .= '<td align="center">'.$session->icon->delete("op=killSession;sid=$data{sessionId}").'</td></tr>';
                $i++;
	}
	$sth->finish;
	$p = WebGUI::Paginator->new($session,$session->url->page('op=viewActiveSessions'));
	$p->setDataByArrayRef(\@row);
	my $i18n = WebGUI::International->new($session);
        $output .= '<table border="1" cellpadding="5" cellspacing="0" align="center">';
        $output .= '<tr class="tableHeader"><td>'.$i18n->get(428).'</td>';
        $output .= '<td>'.$i18n->get(435).'</td>';
        $output .= '<td>'.$i18n->get(432).'</td>';
        $output .= '<td>'.$i18n->get(430).'</td>';
        $output .= '<td>'.$i18n->get(431).'</td>';
	$output .= '<td>'.$i18n->get(436).'</td></tr>';
        $output .= $p->getPage($session->form->process("pn"));
        $output .= '</table>';
        $output .= $p->getBarTraditional($session->form->process("pn"));
	return WebGUI::AdminConsole->new($session,"activeSessions")->render($output);
}

1;
