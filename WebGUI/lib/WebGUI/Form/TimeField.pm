package WebGUI::Form::TimeField;

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
use base 'WebGUI::Form::Text';
use WebGUI::Form::Button;
use WebGUI::Form::Hidden;
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::TimeField

=head1 DESCRIPTION

Creates a time form field.

If the default value is a MySQL time, the value returned by this form element 
will be a MySQL time. Note: Will not be adjusted for the user's time zone.

Otherwise, the value returned by this form element will be a number of seconds,
adjusted for the user's time zone..

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

=head4 defaultValue

Either a number of seconds or a MySQL time.

=head4 maxlength

Defaults to 8. Determines the maximum number of characters allowed in this field.

=head4 size

Default to 8. Determines how many characters wide the field wlll be.

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift || [];
	push(@{$definition}, {
		maxlength=>{
			defaultValue=>8
			},
		size=>{
			defaultValue=>8
			},
		format => {
            defaultValue => undef,
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
    return WebGUI::International->new($session, 'WebGUI')->get('971');
}

#-------------------------------------------------------------------

=head2 getValue ( [ value ] )

If the defaultValue is a MySQL time, or the format property = 'mysql',
the value returned by this form element will be a MySQL time.
Note: Will not be adjusted for the user's time zone.

Otherwise, the value returned by this form element will be a number of seconds.

=head3 value

An optional value to process, instead of POST input. This should be
in the form of an integer of seconds, 'HH:MM', or 'HH:MM:SS'.

=cut

my $mysqlFormattedDate = qr/^\d{2}\D\d{2}(?:\D\d{2})?$/;

sub getValue {
	my $self = shift;
    my $value = $self->SUPER::getValue(@_);
    my $mysqlMode =  $self->get('format') eq 'mysql'
                  || $self->getDefaultValue =~ $mysqlFormattedDate;
    my $mysqlDate = ($value =~ $mysqlFormattedDate);
    my $digits = ($value =~ /^\d+/);
    ##Format is fine
    if (  ( $mysqlMode &&  $mysqlDate)
        ||(!$mysqlMode && !$mysqlDate) && $digits) {
        return $value;
    }
    ##Convert to mysql format
    elsif ($mysqlMode && $digits) {
        return $self->session->datetime->secondsToTime($value);
    }
    ##Convert to seconds.
    elsif ($mysqlDate) {
        return $self->session->datetime->timeToSeconds($value);
    }
    else { ##Bad stuff, maynard
        return undef;
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

Renders a time field.

=cut

sub toHtml {
    my $self = shift;
	my $value = $self->getOriginalValue;
	my $i18n = WebGUI::International->new($self->session);
	$self->session->style->setScript($self->session->url->extras('inputCheck.js'),{ type=>'text/javascript' });
	$self->set("extras", $self->get('extras') . ' onkeyup="doInputCheck(document.getElementById(\''.$self->get("id").'\'),\'0123456789:\')"');
	return $self->SUPER::toHtml
		.WebGUI::Form::Button->new($self->session,
			id=>$self->get('id'),
			extras=>'style="font-size: 8pt;" onclick="window.timeField = this.form.'.$self->get("name").';clockSet = window.open(\''.$self->session->url->extras('timeChooser.html').'\',\'timeChooser\',\'WIDTH=230,HEIGHT=100\');return false"',
			value=>$i18n->get(970)
			)->toHtml;
}

#-------------------------------------------------------------------

=head2 toHtmlAsHidden ( )

Renders the field as a hidden field.

=cut

sub toHtmlAsHidden {
	my $self = shift;
	my $value = $self->getOriginalValue;
	return WebGUI::Form::Hidden->new($self->session,
		name=>$self->get("name"),
		value=>$value
		)->toHtmlAsHidden;
}

1;
