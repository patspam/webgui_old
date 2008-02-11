package WebGUI::Macro::SpectreCheck;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Operation::Spectre;
use WebGUI::International;

=head1 NAME

Package WebGUI::Macro::SessionId

=head1 DESCRIPTION

A macro to return the ID of the user's current session.

=head2 process( )

Really just a wrapper around $session->getId;

=cut


#-------------------------------------------------------------------
sub process {
	my $session = shift;
    my $remote = WebGUI::Operation::Spectre::getASpectre($session);
    my $i18n = WebGUI::International->new($session, "Macro_SpectreCheck");
    if (defined $remote) {
        return $i18n->get('spectre ok');
    }
    else {
        return $i18n->get('spectre is down');
    }
}

1;


