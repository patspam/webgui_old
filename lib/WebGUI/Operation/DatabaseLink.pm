package WebGUI::Operation::DatabaseLink;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use Tie::CPHash;
use WebGUI::AdminConsole;
use WebGUI::DatabaseLink;
use WebGUI::International;

=head1 NAME

Package WebGUI::Operation::DatabaseLink

=head1 DESCRIPTION

Handles creating, managing and deleting Database Links via operations.  Many
of the subroutines here are wrappers around corresponding routines in WebGUI::Database.

=head2 _submenu ( $session, $workarea, $title, $help )

Utility routine for creating the AdminConsole for DatabaseLink functions.

=head3 $session

The current WebGUI session object.

=head3 $workarea

The content to display to the user.

=head3 $title

The title of the Admin Console.  This should be an entry in the i18n
table in the WebGUI namespace.

=head3 $help

An entry in the Help system in the WebGUI namespace.  This will be shown
as a link to the user.

=cut

#-------------------------------------------------------------------
sub _submenu {
	my $session = shift;
        my $workarea = shift;
        my $title = shift;
	my $i18n = WebGUI::International->new($session);
        $title = $i18n->get($title) if ($title);
        my $help = shift;
        my $ac = WebGUI::AdminConsole->new($session,"databases");
        if ($help) {
                $ac->setHelp($help);
        }
	$ac->addSubmenuItem($session->url->page('op=editDatabaseLink;dlid=new'), $i18n->get(982));
	my $dlid = $session->form->process("dlid");
	if (($session->form->process("op") eq "editDatabaseLink" && $dlid ne "new") || $session->form->process("op") eq "deleteDatabaseLink") {
                $ac->addSubmenuItem($session->url->page('op=editDatabaseLink;dlid='.$dlid), $i18n->get(983));
                $ac->addSubmenuItem($session->url->page('op=copyDatabaseLink;dlid='.$dlid), $i18n->get(984));
		$ac->addConfirmedSubmenuItem($session->url->page("op=deleteDatabaseLinkConfirm;dlid=".$dlid), $i18n->get(985), $i18n->get(988));
		$ac->addSubmenuItem($session->url->page('op=listDatabaseLinks'), $i18n->get(986));
	}
        return $ac->render($workarea, $title);
}

=head2 www_copyDatabaseLink ( $session )

Copies the requested database link in the form variable C<dlid> if the user
is in group Admin (3).  Returns the user to the List Database Links screen.

=cut

#-------------------------------------------------------------------
sub www_copyDatabaseLink {
	my $session = shift;
        return $session->privilege->insufficient unless ($session->user->isInGroup(3));
	WebGUI::DatabaseLink->new($session,$session->form->process("dlid"))->copy;
        return www_listDatabaseLinks($session);
}

=head2 www_deleteDatabaseLink ( $session )

Requests that the user confirm the deletion of the database link in
the form variable C<dlid>.  Returns Insufficient privilege if the
user is not in group Admin (3).

=cut

#-------------------------------------------------------------------
sub www_deleteDatabaseLink {
	my $session = shift;
        return $session->privilege->insufficient unless ($session->user->isInGroup(3));
	return $session->privilege->vitalComponent if ($session->form->process("dlid") eq '0');
	my $i18n = WebGUI::International->new($session);
        my ($output);
        $output .= $i18n->get(988).'<p>';
        $output .= '<p><div align="center"><a href="'.
		$session->url->page('op=deleteDatabaseLinkConfirm;dlid='.$session->form->process("dlid"))
		.'">'.$i18n->get(44).'</a>';
        $output .= '&nbsp;&nbsp;&nbsp;&nbsp;<a href="'.$session->url->page('op=listDatabaseLinks').
		'">'.$i18n->get(45).'</a></div>';
        return _submenu($session,$output,"987","database link delete");
}

=head2 www_deleteDatabaseLinkConfirm ( $session )

Deletes the requested database link in the form variable C<dlid> if the user
is in group Admin (3) and the default WebGUI database link (dlid 0) has not
been requested.

Returns the user to the List Database Links screen.

=cut

#-------------------------------------------------------------------
sub www_deleteDatabaseLinkConfirm {
	my $session = shift;
        return $session->privilege->insufficient unless ($session->user->isInGroup(3));
	return $session->privilege->vitalComponent if ($session->form->process("dlid") eq '0');

	WebGUI::DatabaseLink->new($session,$session->form->process("dlid"))->delete;
        return www_listDatabaseLinks($session);
}

=head2 www_editDatabaseLink ( $session )

Create a new database link or edit an existing database link.  The user must
be in group Admin (3).

Calls www_editDatabaseLinkSave on user submission.

=cut

#-------------------------------------------------------------------
sub www_editDatabaseLink {
	my $session = shift;
        return $session->privilege->insufficient unless ($session->user->isInGroup(3));
        my ($output, %db, $f);
	tie %db, 'Tie::CPHash';
	if ($session->form->process("dlid") eq "new") {
		# Default values are SELECT, DESCRIBE and SHOW
		$db{allowedKeywords} = "select\ndescribe\nshow";		
	} elsif ($session->form->process("dlid") eq "0") {
		
	} else {
               	%db = %{WebGUI::DatabaseLink->new($session,$session->form->process("dlid"))->get}; 
	}
	my $i18n = WebGUI::International->new($session);
	$f = WebGUI::HTMLForm->new($session,
		-extras=>'autocomplete="off"'
		);
	$f->submit;
        $f->hidden(
		-name => "op",
		-value => "editDatabaseLinkSave",
        );
        $f->hidden(
		-name => "dlid",
		-value => $session->form->process("dlid"),
        );
	$f->readOnly(
		-value => $session->form->process("dlid"),
		-label => $i18n->get(991),
		-hoverHelp => $i18n->get('991 description'),
	);
        $f->text(
		-name => "title",
		-label => $i18n->get(992),
		-hoverHelp => $i18n->get('992 description'),
		-value => $db{title},
        );
        $f->text(
		-name => "DSN",
		-label => $i18n->get(993),
		-hoverHelp => $i18n->get('993 description'),
		-value => $db{DSN},
        );
        $f->text(
		-name => "dbusername",
		-label => $i18n->get(994),
		-hoverHelp => $i18n->get('994 description'),
		-value => $db{username},
        );
        $f->password(
		-name => "dbidentifier",
		-label => $i18n->get(995),
		-hoverHelp => $i18n->get('995 description'),
		-value => $db{identifier},
        );
	$f->textarea(
		-name => "allowedKeywords",
		-label => $i18n->get('allowed keywords'),
		-hoverHelp => $i18n->get('allowed keywords description'),
		-value => $db{allowedKeywords},
	);
        $f->submit;
	$output .= $f->print;
        return _submenu($session,$output,"990","database link add/edit");
}

=head2 www_editDatabaseLinkSave ( $session )

Form postprocessor for www_editDatabaseLink.  Only users in group Admin (3)
are allowed to use this subroutine.

Returns the user the Link Database Links screen.

=cut

#-------------------------------------------------------------------
sub www_editDatabaseLinkSave {
	my ($allowedKeywords);
	my $session = shift;
        return $session->privilege->insufficient unless ($session->user->isInGroup(3));
	
	# Convert enters to a single \n.
	($allowedKeywords = $session->form->process("allowedKeywords")) =~ s/\s+/\n/g;
	my $params = {
		title=>$session->form->process("title"),
		username=>$session->form->process("dbusername"),
		identifier=>$session->form->process("dbidentifier"),
		DSN=>$session->form->process("DSN"),
		allowedKeywords=>$allowedKeywords,
		};
	if ($session->form->process("dlid") eq "new") {
		WebGUI::DatabaseLink->create($session,$params);
	} else {
		WebGUI::DatabaseLink->new($session,$session->form->process("dlid"))->set($params);
	}
        return www_listDatabaseLinks($session);
}

=head2 www_listDatabaseLinks ( $session )

List all Database links and allow the user to edit, copy or delete them.
Only users in group Admin (3) are allowed to see this screen.

=cut

#-------------------------------------------------------------------
sub www_listDatabaseLinks {
	my $session = shift;
        return $session->privilege->adminOnly() unless($session->user->isInGroup(3));
	my $links = WebGUI::DatabaseLink->getList($session);
        my $output = '<table border="1" cellpadding="3" cellspacing="0" align="center">';
	my $i18n = WebGUI::International->new($session);
	foreach my $id (keys %{$links}) {
#		$output .= '<tr><td valign="top" class="tableData"></td><td valign="top" class="tableData">'.$i18n->get(1076).'</td></tr>';
                $output .= '<tr><td valign="top" class="tableData">';
		if ($id ne '0') {
			$output .= $session->icon->delete('op=deleteDatabaseLinkConfirm;dlid='.$id,'',$i18n->get(988))
				.$session->icon->edit('op=editDatabaseLink;dlid='.$id)
				.$session->icon->copy('op=copyDatabaseLink;dlid='.$id);
		}
		$output	.= '</td>';
                $output .= '<td valign="top" class="tableData">'.$links->{$id}.'</td></tr>';
        }
        $output .= '</table>';
        return _submenu($session,$output,"database links manage");
}


1;
