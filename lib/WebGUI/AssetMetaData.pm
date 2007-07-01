package WebGUI::Asset;

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

=head1 NAME

Package WebGUI::Asset

=head1 DESCRIPTION

This is a mixin package for WebGUI::Asset that contains all metadata related functions.

=head1 SYNOPSIS

 use WebGUI::Asset;

=head1 METHODS

These methods are available from this class:

=cut


#-------------------------------------------------------------------

=head2 addMetaDataField ( )

Adds a field to the metadata system.

=head3 fieldId

The fieldId to be added.

=head3 fieldName

The name of the field

=head3 defaultValue

The default value of the metadata field, if none is chosen by the user.

=head3 description

A description for the field, in case you forget later why you ever bothered
wasting space in the db for this field.

=head3 fieldType

The form field type for metaData: selectBox, text, integer, or checkList, yesNo, radioList.

=head3 possibleValues

For fields that provide options, the list of options.  This is a string with
newline separated values.

=cut

sub addMetaDataField {
    my $self = shift;

    my $fieldId          = shift || 'new';
    my $fieldName        = shift || $self->session->id->generate();
    my $defaultValue     = shift;
    my $description      = shift || '';
    my $fieldType        = shift;
    my $possibleValues   = shift;

	if($fieldId eq 'new') {
		$fieldId = $self->session->id->generate();
		$self->session->db->write("insert into metaData_properties (fieldId, fieldName, defaultValue, description, fieldType, possibleValues) values (?,?,?,?,?,?)",
            [ $fieldId, $fieldName, $defaultValue, $description, $fieldType, $possibleValues, ]
        );
	}
    else {
        $self->session->db->write("update metaData_properties set fieldName = ?, defaultValue = ?, description = ?, fieldType = ?, possibleValues = ? where fieldId = ?",
            [ $fieldName, $defaultValue, $description, $fieldType, $possibleValues, $fieldId, ]
        );
	}
}


#-------------------------------------------------------------------

=head2 deleteMetaDataField ( )

Deletes a field from the metadata system.

=head3 fieldId

The fieldId to be deleted.

=cut

sub deleteMetaDataField {
    my $self = shift;
    my $fieldId = shift;
    $self->session->db->beginTransaction;
    $self->session->db->write("delete from metaData_properties where fieldId = ?",[$fieldId]);
    $self->session->db->write("delete from metaData_values where fieldId = ?",[$fieldId]);
    $self->session->db->commit;
}


#-------------------------------------------------------------------

=head2 getMetaDataFields ( [fieldId] )

Returns a hash reference containing all metadata field properties for this Asset.
You can limit the output to a certain field by specifying a fieldId.

=head3 fieldId

If specified, the hashRef will contain only this field.

=cut

sub getMetaDataFields {
	my $self = shift;
	my $fieldId = shift;
	my $sql = "select
		 	f.fieldId, 
			f.fieldName, 
			f.description, 
			f.defaultValue,
			f.fieldType,
			f.possibleValues,
			d.value
		from metaData_properties f
		left join metaData_values d on f.fieldId=d.fieldId and d.assetId=".$self->session->db->quote($self->getId);
	$sql .= " where f.fieldId = ".$self->session->db->quote($fieldId) if ($fieldId);
	$sql .= " order by f.fieldName";
	if ($fieldId) {
		return $self->session->db->quickHashRef($sql);	
	}
    else {
        tie my %hash, 'Tie::IxHash';
        my $sth = $self->session->db->read($sql);
        while( my $h = $sth->hashRef) {
			foreach(keys %$h) {
				$hash{$h->{fieldId}}{$_} = $h->{$_};
			}
		}
        $sth->finish;
        return \%hash;
	}
}


#-------------------------------------------------------------------

=head2 updateMetaData ( fieldId, value )

Updates the value of a metadata field for this asset.

=head3 fieldId

The unique Id of the field to update.

=head3 value

The value to set this field to. Leave blank to unset it.

=cut

sub updateMetaData {
	my $self = shift;
	my $fieldId = shift;
	my $value = shift;
	my $db = $self->session->db;
	my ($exists) = $db->quickArray("select count(*) from metaData_values where assetId = ? and fieldId = ?",[$self->getId, $fieldId]);
    if (!$exists && $value ne "") {
        $db->write("insert into metaData_values (fieldId, assetId) values (?,?)",[$fieldId, $self->getId]);
    }
    if ($value  eq "") { # Keep it clean
        $db->write("delete from metaData_values where assetId = ? and fieldId = ?",[$self->getId, $fieldId]);
    }
    else {
        $db->write("update metaData_values set value = ? where assetId = ? and fieldId=?", [$value, $self->getId, $fieldId]);
    }
}


#-------------------------------------------------------------------

=head2 www_deleteMetaDataField ( )

Deletes a MetaDataField and returns www_manageMetaData on self, if user isInGroup(4), if not, renders a "content profiling" AdminConsole as insufficient privilege. 

=cut

sub www_deleteMetaDataField {
	my $self = shift;
	return $self->session->privilege->insufficient() unless ($self->session->user->isInGroup(4));
	$self->deleteMetaDataField($self->session->form->process("fid"));
	return $self->www_manageMetaData;
}


#-------------------------------------------------------------------

=head2 www_editMetaDataField ( )

Returns a rendered page to edit MetaData.  Will return an insufficient Privilege if not InGroup(4).

=cut

sub www_editMetaDataField {
	my $self = shift;
	my $i18n = WebGUI::International->new($self->session,'Asset');
	my $ac = WebGUI::AdminConsole->new($self->session,"contentProfiling");
	return $self->session->privilege->insufficient() unless ($self->session->user->isInGroup(4));
        my $fieldInfo;
	if($self->session->form->process("fid") && $self->session->form->process("fid") ne "new") {
		$fieldInfo = $self->getMetaDataFields($self->session->form->process("fid"));
	}
	my $fid = $self->session->form->process("fid") || "new";
	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
	$f->hidden(
		-name => "func",
		-value => "editMetaDataFieldSave"
	);
	$f->hidden(
		-name => "fid",
		-value => $fid
	);
	$f->readOnly(
		-value=>$fid,
		-label=>$i18n->get('Field Id'),
	);
	$f->text(
		-name=>"fieldName",
		-label=>$i18n->get('Field name'),
		-hoverHelp=>$i18n->get('Field Name description'),
		-value=>$fieldInfo->{fieldName}
	);
	$f->textarea(
		-name=>"description",
		-label=>$i18n->get(85),
		-hoverHelp=>$i18n->get('Metadata Description description'),
		-value=>$fieldInfo->{description}
        );
	$f->fieldType(
		-name=>"fieldType",
		-label=>$i18n->get(486),
		-hoverHelp=>$i18n->get('Data Type description'),
		-value=>$fieldInfo->{fieldType} || "text",
		-types=> [ qw /text integer yesNo selectBox radioList checkList/ ]
	);
	$f->textarea(
		-name=>"possibleValues",
		-label=>$i18n->get(487),
		-hoverHelp=>$i18n->get('Possible Values description'),
		-value=>$fieldInfo->{possibleValues}
	);
	$f->textarea(
		-name=>"defaultValue",
		-label=>$i18n->get('default value'),
		-hoverHelp=>$i18n->get('default value description'),
		-value=>$fieldInfo->{defaultValue}
	);
	$f->submit();
	$ac->setHelp("metadata edit property","Asset");
	return $ac->render($f->print, $i18n->get('Edit Metadata'));
}

#-------------------------------------------------------------------

=head2 www_editMetaDataFieldSave ( )

Verifies that MetaData fields aren't duplicated or blank, assigns default values, and returns the www_manageMetaData() method. Will return an insufficient Privilege if not InGroup(4).

=cut

sub www_editMetaDataFieldSave {
	my $self = shift;
	my $ac = WebGUI::AdminConsole->new($self->session,"content profiling");
	return $self->session->privilege->insufficient() unless ($self->session->user->isInGroup(4));
	my $i18n = WebGUI::International->new($self->session,"Asset");
	$ac->setHelp("metadata edit property","Asset");
	# Check for duplicate field names
    my $fid       = $self->session->form->process("fid");
    my $fieldName = $self->session->form->process("fieldName");
	my $sql = "select count(*) from metaData_properties where fieldName = ".
                                $self->session->db->quote($fieldName);
	if ($fid ne "new") {
		$sql .= " and fieldId <> ".$self->session->db->quote($fid);
	}
	my ($isDuplicate) = $self->session->db->buildArray($sql);
	if($isDuplicate) {
		my $error = $i18n->get("duplicateField");
		$error =~ s/\%field\%/$fieldName/;
		return $ac->render($error,$i18n->get('Edit Metadata'));
	}
	if($fieldName eq "") {
		return $ac->render($i18n->get("errorEmptyField"),$i18n->get('Edit Metadata'));
	}
    $self->addMetaDataField(
        $fid,
        $fieldName,
        $self->session->form->process("defaultValue"),
        $self->session->form->process("description") || '',
        $self->session->form->process("fieldType"),
        $self->session->form->process("possibleValues"),
    );

	return $self->www_manageMetaData; 
}


#-------------------------------------------------------------------

=head2 www_manageMetaData ( )

Returns an AdminConsole to deal with MetaDataFields. If isInGroup(4) is False, renders an insufficient privilege page.

=cut

sub www_manageMetaData {
	my $self = shift;
	my $ac = WebGUI::AdminConsole->new($self->session,"contentProfiling");
	return $self->session->privilege->insufficient() unless ($self->session->user->isInGroup(4));
	my $i18n = WebGUI::International->new($self->session,"Asset");
	$ac->addSubmenuItem($self->getUrl('func=editMetaDataField'), $i18n->get("Add new field"));
	my $output;
	my $fields = $self->getMetaDataFields();
	foreach my $fieldId (keys %{$fields}) {
		$output .= $self->session->icon->delete("func=deleteMetaDataField;fid=".$fieldId,$self->get("url"),$i18n->get('deleteConfirm'));
		$output .= $self->session->icon->edit("func=editMetaDataField;fid=".$fieldId,$self->get("url"));
		$output .= " <b>".$fields->{$fieldId}{fieldName}."</b><br />";
	}	
        $ac->setHelp("metadata manage","Asset");
	return $ac->render($output);
}




1;

