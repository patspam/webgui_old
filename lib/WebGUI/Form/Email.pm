package WebGUI::Form::Email;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2008 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Form::Text';
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::Email

=head1 DESCRIPTION

Creates an email field.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Text.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut


#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'WebGUI')->get('480');
}

#-------------------------------------------------------------------

=head2 getValue ( [ value ] )

Returns a validated email address. If the result does not pass validation, it returns undef instead.

=head3 value

An optional value to process instead of POST input.

=cut

sub getValue {
	my $self = shift;
	my $value = @_ ? shift : $self->session->form->param($self->get("name"));
	if ($value =~ /^[0-9a-z._%+-]+@(?:[0-9a-z-]+\.)+[a-z]{2,9}$/i) {
		return $value;
	}
	return undef;
}

#-------------------------------------------------------------------

=head2 getValueAsHtml ( )

Formats as an email link.

=cut

sub getValueAsHtml {
    my $self = shift;
    my $email = $self->getValue;
    return '<a href="mailto:'.$email.'">'.$email.'</a>';
}


#-------------------------------------------------------------------

=head2 isDynamicCompatible ( )

A class method that returns a boolean indicating whether this control is compatible with the DynamicField control.

=cut

sub isDynamicCompatible {
    return 1;
}

#-------------------------------------------------------------------

=head2 toHtml ( )

Renders an email address field.

=cut

sub toHtml {
        my $self = shift;
	$self->session->style->setScript($self->session->url->extras('emailCheck.js'),{ type=>'text/javascript' });
	$self->{_params}{extras} .= ' onchange="emailCheck(this.value)" ';
	return $self->SUPER::toHtml;
}

1;

