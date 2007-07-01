package WebGUI::Form::DynamicField;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2007 Plain Black Corporation.
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
use WebGUI::Utility;

=head1 NAME

Package WebGUI::Form::DynamicField

=head1 DESCRIPTION

Creates the appropriate form field type given the inputs.

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

=head4 fieldType

Defaults to "Text". Should be any valid field type.

=cut

sub definition {
        my $class = shift;
	my $session = shift;
        my $definition = shift || [];
	my $i18n = WebGUI::International->new($session);
        push(@{$definition}, {
                formName=>{
                        defaultValue=>$i18n->get("475"),
                        },
                fieldType=>{
                        defaultValue=> "Text"
                        },
                });
        return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2 new ( params)

Creates the object for the appropriate field type.

=head3 params

The normal params you'd pass in to the field. Included in this list
must be one element called "fieldType" which specifies what type of
field to dynamically render.  List-type forms, however, can take
two additional parameters:

=head4 possibleValues

This is a newline delimited set of values.  A hash will be set by splitting the string
on newlines and making the key and value of each hash entry equal.

=head4 value

For List-type forms which support multiple select, this is normally an arrayref holding all pre-selected
values.  However, if it is a scalar string, the string will be split on newlines and the resulting
array will be used.

=cut

sub new {
	my $class = shift;
	my $session = shift;
	my %raw = @_;
	my $param = \%raw;
        my $fieldType = ucfirst($param->{fieldType});
	delete $param->{fieldType};
        # Return the appropriate field object.
	if ($fieldType eq "") {
		$session->errorHandler->warn("Something is trying to create a dynamic field called ".$param->{name}.", but didn't pass in a field type.");
		$fieldType = "Text";
	}
	##No infinite loops, please
	elsif ($fieldType eq 'DynamicField') {
		$session->errorHandler->warn("Something is trying to create a DynamicField via DynamicField.");
		$fieldType = "Text";
	}
        no strict 'refs';
	my $cmd = "WebGUI::Form::".$fieldType;
	my $load = "use ".$cmd;
	eval ($load);
	if ($@) {
                $session->errorHandler->error("Couldn't compile form control: ".$fieldType.". Root cause: ".$@);
                return undef;
        }
	my $formObj = $cmd->new($session, $param);
	if ($formObj->isa('WebGUI::Form::List')) {
		$formObj->correctValues($param->{value});
		$formObj->correctOptions($param->{possibleValues});
	}
    if ($param->{size}) {
		$formObj->set('size',$param->{size});
	}
        return $formObj;
}


1;

