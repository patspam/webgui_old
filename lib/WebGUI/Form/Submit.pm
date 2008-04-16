package WebGUI::Form::Submit;

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
use base 'WebGUI::Form::Button';
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::Submit

=head1 DESCRIPTION

Creates a submit form button.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Button.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'WebGUI')->get('submit');
}

#-------------------------------------------------------------------

=head2 toHtml ( )

Renders a button.

=cut

sub toHtml {
	my $self = shift;
	my $value = $self->fixQuotes($self->getDefaultValue);
    my $extras = $self->get("extras") || q|class="forwardButton"|;
	my $i18n = WebGUI::International->new($self->session);
	$self->{_params}{extras} ||= 'onclick="this.value=\''.$i18n->get(452).'\'"';
	my $html = '<input type="submit" ';
	$html .= 'name="'.$self->get("name").'" ' if ($self->get("name"));
	$html .= 'id="'.$self->get('id').'" ' unless ($self->get('id') eq "_formId");
	$html .= 'value="'.$value.'" '.$extras.' />';
	return $html;
}

1;

