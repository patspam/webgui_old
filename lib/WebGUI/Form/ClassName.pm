package WebGUI::Form::ClassName;

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
use base 'WebGUI::Form::ReadOnly';
use WebGUI::International;

=head1 NAME

Package WebGUI::Form::ClassName

=head1 DESCRIPTION

Creates a field for typing in perl class names which is validated for taint safety.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::ReadOnly.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut


#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'WebGUI')->get('class name');
}

#-------------------------------------------------------------------

=head2 getValue ( )

Returns a class name which has been taint checked.

=cut

sub getValue {
	my $self = shift;
    my $value = $self->SUPER::getValue(@_);
	$value =~ s/[^\w:]//g;
	return $value;
}

1;

