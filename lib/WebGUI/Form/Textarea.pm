package WebGUI::Form::Textarea;

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

Package WebGUI::Form::Textarea

=head1 DESCRIPTION

Creates a text area form field.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Control.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the super class for additional details.

=head3 additionalTerms

The following additional parameters have been added via this sub class.

=head4 width

The width of this control in pixels. Defaults to 400 pixels.

=head4 height

The height of this control in pixels.  Defaults to 150 pixels.

=head4 style

Style attributes besides width and height which should be specified using the above parameters. Be sure to escape quotes if you use any.

=head4 resizable 

A boolean indicating whether the text area can be reized by users. Defaults to 1.

=head4 maxlength

The maximum number of characters to allow in this field. If not defined, will not do any limiting.

=cut

sub definition {
	my $class       = shift;
	my $session     = shift;
	my $definition  = shift || [];
	push @{$definition}, {
		height=>{
			defaultValue=> 150
        },
		width=>{
			defaultValue=> 400
        },
		style=>{
			defaultValue => undef,
        },
		resizable => {
			defaultValue => 1,
        },
        maxlength => {
            defaultValue    => ''
        },
    };
    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2  getDatabaseFieldType ( )

Returns "LONGTEXT".

=cut 

sub getDatabaseFieldType {
    return "LONGTEXT";
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'WebGUI')->get('476');
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

Renders an input tag of type text.

=cut

sub toHtml {
	my $self = shift;
 	my $value = $self->fixMacros($self->fixTags($self->fixSpecialCharacters($self->getOriginalValue)));
	my $width = $self->get('width') || 400;
	my $height = $self->get('height') || 150;
	my ($style, $url) = $self->session->quick(qw(style url));
	my $styleAttribute = "width: ".$width."px; height: ".$height."px; ".$self->get("style");
    $style->setRawHeadTags(qq|<style type="text/css">\ntextarea#|.$self->get('id').qq|{ $styleAttribute }\n</style>|);
	my $out = '<textarea id="'.$self->get('id').'" name="'.$self->get("name").'" '
            . ( $self->get("maxlength") ? 'maxlength="' . $self->get( "maxlength" ) . '" ' : '' )
            . $self->get("extras") . ' rows="#" cols="#" style="width: '.$width.'px; height: '.$height.'px;">'.$value.'</textarea>'
            ;

    # Add the maxlength script
    $style->setScript( 
        $url->extras( 'yui/build/yahoo-dom-event/yahoo-dom-event.js' ), 
        { text => 'text/javascript' },
    );
    $style->setScript( 
        $url->extras( 'yui-webgui/build/form/textarea.js' ), 
        { type => 'text/javascript' }, 
    );
    $style->setRawHeadTags( q|
        <script type="text/javascript">
            YAHOO.util.Event.onDOMReady( function () { WebGUI.Form.Textarea.setMaxLength() } );
        </script>
    | );

	if ($self->get("resizable")) {
        $style->setLink($url->extras("resize.css"), {type=>"text/css", rel=>"stylesheet"});
        $style->setLink($url->extras("resize-skin.css"), {type=>"text/css", rel=>"stylesheet"});
        $style->setScript($url->extras("yui/build/utilities/utilities.js"), {type=>"text/javascript"});
        $style->setScript($url->extras("yui/build/resize/resize.js"), {type=>"text/javascript"});
        $out = qq|
            <div id="resize_| . $self->get('id'). qq|" style="width: | . ($width + 6) . qq|px; height: | . ($height + 6) . qq|px; overflow: hidden">
            $out
            </div>

            <script type="text/javascript">
            YAHOO.util.Event.onContentReady('| . $self->get('id') . qq|', function() {
                var Dom = YAHOO.util.Dom;
                var resize = new YAHOO.util.Resize('resize_| . $self->get('id'). qq|');
                resize.on('resize', function(ev) {
                    Dom.setStyle('| . $self->get('id') . qq|', 'width', (ev.width - 6) + "px");
                    Dom.setStyle('| . $self->get('id') . qq|', 'height', (ev.height - 6) + "px");
                });
            });
            </script>
        |;
	}
	return $out;
}

sub getValueAsHtml {
    my $self = shift;
    my $value = $self->SUPER::getValueAsHtml(@_);
    $value = WebGUI::HTML::filter($value, 'text');
    return $value;
}


1;

