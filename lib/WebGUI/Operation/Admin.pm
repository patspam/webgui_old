package WebGUI::Operation::Admin;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2005 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::AdminConsole;
use WebGUI::Grouping;
use WebGUI::Session;

=head1 NAME

Package WebGUI::Operation::Admin

=head1 DESCRIPTION

Operation handler for admin functions

=cut

#-------------------------------------------------------------------

=head2 www_adminConsole ( )

If the current user is in the Turn On Admin Group, then return an Admin Console.

=cut

sub www_adminConsole {
	my $session = shift;
	return "" unless (WebGUI::Grouping::isInGroup(12));
	my $ac = WebGUI::AdminConsole->new;
	return $ac->render;
}

#-------------------------------------------------------------------

=head2 www_switchOffAdmin ( )

If the current user is in the Turn On Admin Group, then allow them to turn off Admin mode
via WebGUI::Session::switchAdminOff()


=cut

sub www_switchOffAdmin {
	my $session = shift;
	return "" unless (WebGUI::Grouping::isInGroup(12));
	WebGUI::Session::switchAdminOff();
	return "";
}

#-------------------------------------------------------------------

=head2 www_adminConsole ( )

If the current user is in the Turn On Admin Group, then allow them to turn on Admin mode.
via WebGUI::Session::switchAdminOn()

=cut

sub www_switchOnAdmin {
	my $session = shift;
	return "" unless (WebGUI::Grouping::isInGroup(12));
	WebGUI::Session::switchAdminOn();
	return "";
}


1;
