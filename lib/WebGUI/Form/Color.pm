package WebGUI::Form::Color;

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
use base 'WebGUI::Form::Control';
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::Color

=head1 DESCRIPTION

Creates a color picker which returns hex colors like #000000.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Control.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2  getDatabaseFieldType ( )

Returns "VARCHAR(7)".

=cut 

sub getDatabaseFieldType {
    return "VARCHAR(7)";
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'WebGUI')->get('color');
}

#-------------------------------------------------------------------

=head2 getValue ( [ value ] )

Returns a hex color like "#000000". Returns undef if the return value is not a valid color.

=head2 value

An optional value to use instead of POST input.

=cut

sub getValue {
	my $self = shift;
    my $color = $self->SUPER::getValue(@_);
	return undef unless $color =~ /\#\w{6}/;
	return $color;
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

Renders a color picker control.

=cut

sub toHtml {
    my $self = shift;
    my $url = $self->session->url;
    my $style = $self->session->style;
    $style->setLink($url->extras('/yui/build/container/assets/skins/sam/container.css'),{ type=>'text/css', rel=>"stylesheet" });
    $style->setLink($url->extras('/yui/build/colorpicker/assets/skins/sam/colorpicker.css'),{ type=>'text/css', rel=>"stylesheet" });
    $style->setScript($url->extras('/yui/build/yahoo/yahoo-min.js'),{ type=>'text/javascript' });
    $style->setScript($url->extras('/yui/build/event/event-min.js'),{ type=>'text/javascript' });
    $style->setScript($url->extras('/yui/build/dom/dom-min.js'),{ type=>'text/javascript' });
    $style->setScript($url->extras('/yui/build/dragdrop/dragdrop-min.js'),{ type=>'text/javascript' });
    $style->setScript($url->extras('/yui/build/utilities/utilities.js'),{ type=>'text/javascript' });
    $style->setScript($url->extras('/yui/build/container/container-min.js'),{ type=>'text/javascript' });
    $style->setScript($url->extras('/yui/build/slider/slider-min.js'),{ type=>'text/javascript' });
    $style->setScript($url->extras('/yui/build/colorpicker/colorpicker-min.js'),{ type=>'text/javascript' });
    $style->setLink($url->extras('/colorpicker/colorpicker.css'),{ type=>'text/css', rel=>"stylesheet" });
    $style->setScript($url->extras('/colorpicker/colorpicker.js'),{ type=>'text/javascript' });
    my $id = $self->get("id");
    my $value = $self->getDefaultValue;
    my $name = $self->get("name");
    return qq{<a href="javascript:YAHOO.WebGUI.Form.ColorPicker.display('$id', '${id}_swatch');" id="${id}_swatch" class="colorPickerFormSwatch" style="background-color: $value"></a>
<input onchange="YAHOO.util.Dom.setStyle('${id}_swatch', 'background-color', this.value)" 
maxlength="7" name="$name" type="text" size="8" value="$value" id="$id" />};
}

1;

