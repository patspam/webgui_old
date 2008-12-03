package WebGUI::Form::Captcha;

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
use WebGUI::Storage;

=head1 NAME

Package WebGUI::Form::Captcha

=head1 DESCRIPTION

Creates a captcha form element that helps verify a human is submitting the form rather than a bot.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::Text.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the super class for additional details.

=head3 additionalTerms

The following additional parameters have been added via this sub class.

=head3 label

Defaults to "Verify Your Humanity"

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift || [];
	my $i18n = WebGUI::International->new($session,"Form_Captcha");
	push(@{$definition}, {
		label => {
			defaultValue=>$i18n->get("verify your humanity")
			},
		});
        return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2  getDatabaseFieldType ( )

Returns "BOOLEAN".

=cut 

sub getDatabaseFieldType {
    return "BOOLEAN";
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'Form_Captcha')->get('topicName');
}

#-------------------------------------------------------------------

=head2 getValue ( )

Returns a boolean indicating whether the string typed matched the image.

=cut

sub getValue {
    my $self        = shift;
    my $value       = $self->SUPER::getValue(@_); 
    my $challenge   = $self->session->scratch->get("captcha_".$self->get("name"));
    $self->session->scratch->delete("captcha_".$self->get("name"));
    my $passed  = lc $value eq lc $challenge;
    $self->session->errorHandler->info( 
        "Checking CAPTCHA '" . $self->get("name") . "': " . ( $passed ? "PASSED!" : "FAILED!" )
        . " Got: '" . $value . "', Wanted: '" . $challenge . "'"
    );
    return $passed;
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

Renders a captcha field.

=cut

sub toHtml {
        my $self = shift;
 	my $storage = WebGUI::Storage->createTemp($self->session);
        my ($filename, $challenge) = $storage->addFileFromCaptcha;
        $self->set("size", 6);
	$self->set("maxlength", 6);
	$self->session->scratch->set("captcha_".$self->get("name"), $challenge);
	return $self->SUPER::toHtml.'<p style="display:inline;vertical-align:middle;"><img src="'.$storage->getUrl($filename).'" style="border-style:none;vertical-align:middle;" alt="captcha" /></p>';
}

1;

