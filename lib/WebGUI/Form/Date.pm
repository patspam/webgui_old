package WebGUI::Form::Date;

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
use WebGUI::Form::Hidden;
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::Date

=head1 DESCRIPTION

Accepts and returns and epoch date and creates a date picker control.

If the current or default value is a MySQL date string, accepts and returns
a MySQL date string. 

NOTE: Does not do time-zone conversion.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Text.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the superclass for additional details.

=head3 additionalTerms

The following additional parameters have been added via this sub class.

=head4 maxlength

Defaults to 10. Determines the maximum number of characters allowed in this field.

=head4 size

Defaults to 10. The displayed size of the box for the date to be typed in.

=head4 noDate

A default date is placed in the value field. Set this to "1" to leave it empty.

=head4 defaultValue

If no value is specified, this will be used. Defaults to today and now.

If the defaultValue is a MySQL date string, this form control will return MySQL
date strings instead of epoch times.

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift || [];
	push(@{$definition}, {
		defaultValue=>{
			defaultValue=>$session->datetime->time()
			},
		maxlength=>{
			defaultValue=> 10
			},
		size=>{
			defaultValue=> 10
			},
		noDate=>{
			defaultValue=>0
			},
		});
        return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2  getDatabaseFieldType ( )

Returns "BIGINT".

=cut 

sub getDatabaseFieldType {
    return "BIGINT";
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'WebGUI')->get('352');
}

#-------------------------------------------------------------------

=head2 getValue ( [ value ] )

Returns a validated form post result. If the result does not pass validation, 
it returns undef instead.

=head3 value

An optional value to process, instead of POST input. This should be in the 'YY(YY)?-MM-DD' form.

=cut

sub getValue {
	my $self = shift;
    # This should probably be rewritten as a cascading ternary
    my $value = $self->SUPER::getValue(@_);
	if (!$self->getDefaultValue || $self->getDefaultValue =~ m/^\d+$/) {
		return $self->session->datetime->setToEpoch($value);
	} 
    else {
		# MySQL format
		# YY(YY)?-MM-DD
		
		# NOTE: Cannot fix time zone since we don't have a complete date/time
		
		return $1
			if ($value =~ m/((?:\d{2}|\d{4})\D\d{2}\D\d{2})/);
	}
}

#-------------------------------------------------------------------

=head2 getValueAsHtml ( )

Return the date in a human readable format.

=cut

sub getValueAsHtml {
	my ($self) = @_;
    # This should probably be rewritten as a cascading ternary
	if (!$self->get("defaultValue") 
        || $self->get("defaultValue") =~ m/^\d+$/
        || !$self->get("value")     
        || $self->get("value") =~ m/^\d+$/) {
		return $self->session->datetime->epochToHuman($self->getValue,"%z");
	} 
    else {
		# MySQL format
		my $value = $self->getValue;
        return $value;
	}
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

Renders a date picker control.

=cut

sub toHtml {
        my $self = shift;
	my $value;
	# This should probably be rewritten as a cascading ternary
    if ($self->get("_defaulted") && $self->get("noDate") ) {
		# No default date
		$value = $self->set("value",'');
	}
    elsif (!$self->get("defaultValue") 
        || $self->get("defaultValue") =~ m/^\d+$/
        || !$self->get("value")     
        || $self->get("value") =~ m/^\d+$/) {
		# Epoch format
		$value = $self->set("value",$self->session->datetime->epochToSet($self->getDefaultValue));
	} 
    else {
		# MySQL format
		$value = $self->getDefaultValue;
		# NOTE: Cannot fix time zone since we don't have a complete date/time
	}

        $self->session->style->setLink($self->session->url->extras('yui/build/calendar/assets/skins/sam/calendar.css'), { rel=>"stylesheet", type=>"text/css", media=>"all" });
        $self->session->style->setScript($self->session->url->extras('yui/build/yahoo/yahoo-min.js'),{ type=>'text/javascript' });
        $self->session->style->setScript($self->session->url->extras('yui/build/dom/dom-min.js'),{ type=>'text/javascript' });
        $self->session->style->setScript($self->session->url->extras('yui/build/event/event-min.js'),{ type=>'text/javascript' });
        $self->session->style->setScript($self->session->url->extras('yui/build/calendar/calendar-min.js'),{ type=>'text/javascript' });
        my $firstDow = $self->session->user->profileField("firstDayOfWeek");
        $self->session->style->setRawHeadTags("<script type=\"text/javascript\">var webguiFirstDayOfWeek = $firstDow</script>");
        $self->session->style->setScript($self->session->url->extras('yui-webgui/build/datepicker/datepicker.js'),{ type=>'text/javascript' });

        return WebGUI::Form::Text->new($self->session,
                name=>$self->get("name"),
                value=>$value,
                size=>$self->get("size"),
                extras=>$self->get("extras") . ' onfocus="YAHOO.WebGUI.Form.DatePicker.display(this);"',
                id=>$self->get('id'),
                maxlength=>$self->get("maxlength")
                )->toHtml;
}

#-------------------------------------------------------------------

=head2 toHtmlAsHidden ( )

Renders the form field to HTML as a hidden field rather than whatever field type it was supposed to be.

=cut

sub toHtmlAsHidden {
    my $self = shift;
	my $value;
	
    # This should probably be rewritten as a cascading ternary
	if (!$self->get("defaultValue") 
        || $self->get("defaultValue") =~ m/^\d+$/
        || !$self->get("value")     
        || $self->get("value") =~ m/^\d+$/) {
		$value = $self->session->datetime->epochToSet($self->getDefaultValue,"%z");
	} else {
		# MySQL format
		$value = $self->getDefaultValue;
		# NOTE: Cannot fix time zone since we don't have a complete date/time
	}
	
        return WebGUI::Form::Hidden->new($self->session,
                name	=> $self->get("name"),
                value	=> $value,
                )->toHtmlAsHidden;
}

1;

