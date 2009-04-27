package WebGUI::Form::ThingFieldsList;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Form::SelectList';

=head1 NAME

Package WebGUI::Form::ThingyFieldsList

=head1 DESCRIPTION

Creates a content type selector which can be used in conjunction with the Thingy to pick a list
of fields in that thingy.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Selectlist.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#----------------------------------------------------------------------------

=head2 www_getThingFields ($session)

Returns a JSON encoded hash which contains a list of fieldIds and labels
from the Thingy_fields table for the Thing given by the form variable 'thingId'.

=head3 $session

=cut

sub www_getThingFields {
    my ( $session ) = @_;

    my $thingId = $session->form->get('thingId');
    my %fields
        = $session->db->buildHash(
            "SELECT fieldId, label FROM Thingy_fields WHERE thingId=?",
            [$thingId]
        );

    $session->http->setMimeType( 'application/json' );
    return JSON->new->encode( \%fields );
}

1;
