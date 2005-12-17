package WebGUI::Macro::Env;

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
use WebGUI::Session;

=head1 NAME

Package WebGUI::Macro::Env

=head1 DESCRIPTION

Macro for displaying fields from the Session env hash.

=head2 process ( key )

=head3 key

The key from the Session env hash to display.  If the key doesn't exist,
then undef will be returned.

=cut

#-------------------------------------------------------------------
sub process {
	return $session{env}{shift};
}

1;


