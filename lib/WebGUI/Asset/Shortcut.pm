package WebGUI::Asset::Shortcut;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use Carp;
use Tie::IxHash;
use WebGUI::Asset;
use WebGUI::International;
use WebGUI::Operation::Profile;
use WebGUI::ProfileField;
use WebGUI::ProfileCategory;
use WebGUI::Macro;
use HTML::Entities qw(encode_entities);

our @ISA = qw(WebGUI::Asset);

#-------------------------------------------------------------------
sub _drawQueryBuilder {
	my $self = shift;
	# Initialize operators
	my @textFields = qw|text yesNo selectBox radioList|;
	my $i18n = WebGUI::International->new($self->session,"Asset_Shortcut");
	my %operator;
	foreach (@textFields) {
		$operator{$_} = {
			"=" => $i18n->get("is"),
			"!=" => $i18n->get("isnt")
		};
	}
	$operator{integer} = {
		"=" => $i18n->get("equal to"),
		"!=" => $i18n->get("not equal to"),
		"<" => $i18n->get("less than"),
		">" => $i18n->get("greater than")
	};

	# Get the fields and count them
	my $fields = $self->getMetaDataFields();
	my $fieldCount = scalar(keys %$fields);

	unless ($fieldCount) {	# No fields found....
		return sprintf $i18n->get('no metadata yet'), $self->session->url->page('func=manageMetaData');
	}

	# Static form fields
	my $shortcutCriteriaField = WebGUI::Form::textarea($self->session, {
		name=>"shortcutCriteria",
		value=>$self->getValue("shortcutCriteria"),
		extras=>'style="width: 100%" '.$self->{_disabled}
	});
	my $conjunctionField = WebGUI::Form::selectBox($self->session, {
		name=>"conjunction",
		options=>{
			"AND" => $i18n->get("AND"),
			"OR" => $i18n->get("OR")},
			value=>["OR"],
			extras=>'class="qbselect"',
		}
	);

	# html
	$self->session->style->setScript($self->session->url->extras('wobject/Shortcut/querybuilder.js'), {type=>"text/javascript"});
	$self->session->style->setLink($self->session->url->extras('wobject/Shortcut/querybuilder.css'), {type=>"text/css", rel=>"stylesheet"});
	my $output;
	$output .= qq|<table cellspacing="0" cellpadding="0" border="0"><tr><td colspan="5" align="right">$shortcutCriteriaField</td></tr><tr><td></td><td></td><td></td><td></td><td class="qbtdright"></td></tr><tr><td></td><td></td><td></td><td></td><td class="qbtdright">$conjunctionField</td></tr>|;

	# Here starts the field loop
	my $i = 1;
	foreach my $field (keys %$fields) {
		my $fieldLabel = $fields->{$field}{fieldName};
		my $fieldType = $fields->{$field}{fieldType} || "text";

		# The operator select field
		my $opFieldName = "op_field".$i;
		my $opField = WebGUI::Form::selectBox($self->session, {
			name=>$opFieldName,
			uiLevel=>5,
			options=>$operator{$fieldType},
			extras=>'class="qbselect"'
		});
		# The value select field
		my $valFieldName = "val_field".$i;
		my $valueField = WebGUI::Form::dynamicField($self->session,
			fieldType=>$fieldType,
			name=>$valFieldName,
			uiLevel=>5,
			extras=>qq/title="$fields->{$field}{description}" class="qbselect"/,
			options=>$fields->{$field}{possibleValues},
		);
		# An empty row
		$output .= qq|<tr><td></td><td></td><td></td><td></td><td class="qbtdright"></td></tr>|;

		# Table row with field info
		$output .= qq|
		<tr>
		<td class="qbtdleft"><p class="qbfieldLabel">$fieldLabel</p></td>
		<td class="qbtd">
		$opField
		</td>
		<td class="qbtd">
		<span class="qbText">$valueField</span>
		</td>
		<td class="qbtd"></td>
		<td class="qbtdright">
		<input class="qbButton" type=button value=Add onclick="addCriteria('$fieldLabel', this.form.$opFieldName, this.form.$valFieldName)"></td>
		</tr>
		|;
		$i++;
	}
	# Close the table
	$output .= "</table>";

	return $output;
}

#-------------------------------------------------------------------
sub _submenu {
	my $self = shift;
	my $workarea = shift;
	my $title = shift;
	my $help = shift;
	my $ac = WebGUI::AdminConsole->new($self->session,"shortcutmanager");
	$ac->setIcon($self->getIcon);
	my $i18n = WebGUI::International->new($self->session,"Asset_Shortcut");
	$ac->addSubmenuItem($self->getUrl('func=edit'), $i18n->get("Back to Edit Shortcut"));
	$ac->addSubmenuItem($self->getUrl("func=manageOverrides"),$i18n->get("Manage Shortcut Overrides"));
	return $ac->render($workarea, $title);
}

#-------------------------------------------------------------------
sub canEdit {
	my $self = shift;
return 1 if ($self->SUPER::canEdit || ($self->isDashlet && $self->getParent->canManage));
	return 0;
}

#-------------------------------------------------------------------
sub canManage {
	my $self = shift;
	return $self->canEdit;
}

#-------------------------------------------------------------------
sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session,"Asset_Shortcut");
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		icon=>'shortcut.gif',
		tableName=>'Shortcut',
		className=>'WebGUI::Asset::Shortcut',
		properties=>{
			shortcutToAssetId=>{
				noFormPost=>1,
				fieldType=>"hidden",
				defaultValue=>undef
			},
			shortcutByCriteria=>{
				fieldType=>"yesNo",
				defaultValue=>0,
			},
			disableContentLock=>{
				fieldType=>"yesNo",
				defaultValue=>0
			},
			resolveMultiples=>{
				fieldType=>"selectBox",
				defaultValue=>"mostRecent",
			},
			shortcutCriteria=>{
				fieldType=>"textarea",
				defaultValue=>"",
			},
			templateId=>{
				fieldType=>"template",
				defaultValue=>"PBtmpl0000000000000140"
			},
			prefFieldsToShow=>{
				fieldType=>"checkList",
				defaultValue=>undef
			},
			prefFieldsToImport=>{
				fieldType=>"checkList",
				defaultValue=>undef
			},
			showReloadIcon=>{
				fieldType=>"yesNo",
				defaultValue=>1
			}
		}
	});
	return $class->SUPER::definition($session,$definition);
}

#-------------------------------------------------------------------
sub discernUserId {
	my $self = shift;
	return ($self->canManage && $self->session->var->isAdminOn) ? '1' : $self->session->user->userId;
}

#-------------------------------------------------------------------
sub duplicate {
    my $self = shift;
    my $newAsset = $self->SUPER::duplicate(@_);
    $self->session->db->write(<<'END_SQL', [$newAsset->getId, $self->getId]);
INSERT INTO Shortcut_overrides (assetId, fieldName, newValue)
SELECT ?, fieldName, newValue
FROM Shortcut_overrides 
WHERE assetId = ?
END_SQL
    return $newAsset;
}

#-------------------------------------------------------------------
sub getContentLastModified {
    my $self = shift;
    my $assetRev = $self->get('revisionDate');
    my $shortcuttedRev = $self->getShortcut->get('revisionDate');
    return $assetRev > $shortcuttedRev ? $assetRev : $shortcuttedRev;
}

#-------------------------------------------------------------------
sub getEditForm {
	my $self = shift;
	my $tabform = $self->SUPER::getEditForm();
	my $originalTemplate;
	my $i18n = WebGUI::International->new($self->session, "Asset_Shortcut");
	my $shortcut = $self->getShortcut;
	if (defined $shortcut) {
		$tabform->getTab("properties")->readOnly(
			-label=>$i18n->get(1),
			-hoverHelp=>$i18n->get('1 description'),
			-value=>'<a href="'.$shortcut->getUrl.'">'.$shortcut->get('title').'</a> ('.$shortcut->getId.')'
			);
	} else {
		$tabform->getTab("properties")->readOnly(
			value=>'<a href="'.$self->getUrl("func=delete").'"><span style="font-weight: bold; color: red;">'.$self->notLinked.'</span></a>'
			);
	}
	$tabform->getTab("display")->template(
		-value=>$self->getValue("templateId"),
		-label=>$i18n->get('shortcut template title'),
		-hoverHelp=>$i18n->get('shortcut template title description'),
		-namespace=>"Shortcut"
	);
	if($self->session->setting->get("metaDataEnabled")) {
		$tabform->getTab("properties")->yesNo(
			-name=>"shortcutByCriteria",
			-value=>$self->getValue("shortcutByCriteria"),
			-label=>$i18n->get("Shortcut by alternate criteria"),
			-hoverHelp=>$i18n->get("Shortcut by alternate criteria description"),
			-extras=>q|onchange="
				if (this.form.shortcutByCriteria[0].checked) { 
 					this.form.resolveMultiples.disabled=false;
					this.form.shortcutCriteria.disabled=false;
				} else {
 					this.form.resolveMultiples.disabled=true;
					this.form.shortcutCriteria.disabled=true;
				}"|
                );
		$tabform->getTab("properties")->yesNo(
			-name=>"disableContentLock",
			-value=>$self->getValue("disableContentLock"),
			-label=>$i18n->get("disable content lock"),
			-hoverHelp=>$i18n->get("disable content lock description")
			);
		if ($self->getValue("shortcutByCriteria") == 0) {
			$self->{_disabled} = 'disabled=true';
		}
		$tabform->getTab("properties")->selectBox(
			-name=>"resolveMultiples",
			-value=>[ $self->getValue("resolveMultiples") ],
			-label=>$i18n->get("Resolve Multiples"),
			-hoverHelp=>$i18n->get("Resolve Multiples description"),
			-options=>{
				mostRecent=>$i18n->get("Most Recent"),
				random=>$i18n->get("Random"),
			},
			-extras=>$self->{_disabled}
		);
		$tabform->getTab("properties")->readOnly(
			-value=>$self->_drawQueryBuilder(),
			-label=>$i18n->get("Criteria"),
			-hoverHelp=>$i18n->get("Criteria description")
		);
	}
	$tabform->addTab('overrides',$i18n->get('Overrides'));
	$tabform->getTab('overrides')->raw('<tr><td>' . $self->getOverridesList . '</td></tr>');
	if ($self->isDashlet) {
		$tabform->addTab('preferences',$i18n->get('Preferences'));
		$tabform->getTab('preferences')->raw($self->getFieldsList);
		$tabform->getTab("properties")->yesNo(
			-value=>$self->getValue("showReloadIcon"),
			-name=>"showReloadIcon",
			-label=>$i18n->get("show reload icon"),
			-hoverHelp=>$i18n->get("show reload icon description")
		);
	}
	return $tabform;
}


#-------------------------------------------------------------------

=head2 getExtraHeadTags (  )

Returns the extraHeadTags stored in the asset.  Called in $self->session->style->generateAdditionalHeadTags if this asset is the $self->session->asset.  Also called in WebGUI::Asset::Wobject::Layout for its child assets.  Overriden to also add tags from shortcutted asset.

=cut

sub getExtraHeadTags {
	my $self = shift;
	my $output = $self->get("extraHeadTags")."\n";
	my $shortcut = $self->getShortcut;
	$output .= $self->getShortcut->get("extraHeadTags") if defined $shortcut;
	return $output;
}

#-------------------------------------------------------------------
sub getFieldsList {
	my $self = shift;
	my $i18n = WebGUI::International->new($self->session, "Asset_Shortcut");
	my $output = '<a href="'.$self->getUrl('op=editProfileSettings').'" class="formLink">'.$i18n->get('Manage Profile Fields').'</a><br /><br />';
	my %fieldNames;
	tie %fieldNames, 'Tie::IxHash';
	foreach my $field (@{WebGUI::ProfileField->getFields($self->session)}) {
		my $fieldId = $field->getId;
		next if $fieldId =~ /contentPositions/;
		$fieldNames{$fieldId} = $field->getLabel.' ['.$fieldId.']';
	}
	$output .= '<table cellspacing="0" cellpadding="3" border="1"><tr><td><table cellspacing="0" cellpadding="3" border="0">';
	my @prefFieldsToShow = split("\n",$self->getValue("prefFieldsToShow"));
	$output .= WebGUI::Form::CheckList->new($self->session,
		-name=>"prefFieldsToShow",
		-value=>\@prefFieldsToShow,
		-options=>\%fieldNames,
		-label=>$i18n->get('pref fields to show'),
		-hoverHelp=>$i18n->get('pref fields to show description'),
		-vertical=>1,
		-uiLevel=>9
	)->toHtmlWithWrapper;
	$output .= '</table></td><td><table cellspacing="0" cellpadding="3" border="0">';
	my @prefFieldsToImport = split("\n",$self->getValue("prefFieldsToImport"));
	$output .= WebGUI::Form::CheckList->new($self->session,
		-name=>"prefFieldsToImport",
		-value=>\@prefFieldsToImport,
		-options=>\%fieldNames,
		-label=>$i18n->get('pref fields to import'),
		-hoverHelp=>$i18n->get('pref fields to import description'),
		-vertical=>1,
		-uiLevel=>9
	)->toHtmlWithWrapper;
	$output .= '</table></td></tr></table>';
	return $output;
}

#-------------------------------------------------------------------
sub getOverridesList {
	my $self = shift;
	my $output = '';
	my $i18n = WebGUI::International->new($self->session, "Asset_Shortcut");
	my %overrides = $self->getOverrides;
	$output .= '<table cellspacing="0" cellpadding="3" border="1">';
	$output .= '<tr class="tableHeader"><td>'.$i18n->get('fieldName').'</td><td>'.$i18n->get('edit delete fieldname').'</td><td>'.$i18n->get('Original Value').'</td><td>'.$i18n->get('New value').'</td><td>'.$i18n->get('Replacement value').'</td></tr>';
	my $shortcut = $self->getShortcutOriginal;
	return undef unless defined $shortcut;
	foreach my $definition (@{$shortcut->definition($self->session)}) {
		foreach my $prop (keys %{$definition->{properties}}) {
			next if $definition->{properties}{$prop}{fieldType} eq 'hidden';
            next if $definition->{properties}{$prop}{label} eq '';
			$output .= '<tr>';
            $output .= '<td class="tableData">'.$definition->{properties}{$prop}{label}.'</td>';
			$output .= '<td class="tableData">';
			$output .= $self->session->icon->edit('func=editOverride;fieldName='.$prop,$self->get("url"));
			$output .= $self->session->icon->delete('func=deleteOverride;fieldName='.$prop,$self->get("url")) if exists $overrides{overrides}{$prop};
			$output .= '</td><td>';
			$output .= $overrides{overrides}{$prop}{origValue};
			$output .= '</td><td>';
			$output .= encode_entities($overrides{overrides}{$prop}{newValue}, '<>&"^');
			$output .= '</td><td>';
			$output .= $overrides{overrides}{$prop}{parsedValue};
			$output .= '</td></tr>';
		}
	}
	$output .= '</table>';
	return $output;
}

#-------------------------------------------------------------------
sub _overridesCacheTag {
	my $self = shift;
	#cache by userId, assetId of this shortcut, and whether adminMode is on or not.
	return ["shortcutOverrides", $self->getId, $self->session->user->userId, $self->session->var->isAdminOn];
}

#-------------------------------------------------------------------
sub getOverrides {
	my $self = shift;
	my $i = 0;
	my $cache = WebGUI::Cache->new($self->session,$self->_overridesCacheTag);
	my $overridesRef = $cache->get;
	unless ($overridesRef->{cacheNotExpired}) {
		my %overrides;
		my $orig = $self->getShortcutOriginal;
		if (defined $orig) {
			unless ( exists $orig->{_propertyDefinitions}) {
			my %properties;
				foreach my $definition (@{$orig->definition($self->session)}) {
					%properties = (%properties, %{$definition->{properties}});
				}
				$orig->{_propertyDefinitions} = \%properties;
			}
			$overrides{cacheNotExpired} = 1;
			my $sth = $self->session->db->read("select fieldName, newValue from Shortcut_overrides where assetId=? order by fieldName",[$self->getId]);
			while (my ($fieldName, $newValue) = $sth->array) {
				$overrides{overrides}{$fieldName}{fieldType} = $orig->{_propertyDefinitions}{$fieldName}{fieldType};
				$overrides{overrides}{$fieldName}{origValue} = $orig->get($fieldName);
				$overrides{overrides}{$fieldName}{newValue} = $newValue;
				$overrides{overrides}{$fieldName}{parsedValue} = $newValue;
			}
			$sth->finish;
		} else {
			$self->session->errorHandler->warn("Original asset could not be instanciated by shortcut ".$self->getId);
		}
		if ($self->isDashlet) {
			my $u = WebGUI::User->new($self->session, $self->discernUserId);
			my @userPrefs = $self->getPrefFieldsToImport;
			foreach my $fieldId (@userPrefs) {
				my $field = WebGUI::ProfileField->new($self->session,$fieldId);
				next unless $field;
				my $fieldName = $field->getId;
				my $fieldValue = $u->profileField($field->getId);
				$overrides{userPrefs}{$fieldName}{value} = $fieldValue;
				$overrides{userPrefs}{$fieldName}{parsedValue} = $fieldValue;
				#  'myTemplateId is ##userPref:myTemplateId##', for example.
				foreach my $overr (keys %{$overrides{overrides}}) {
					$overrides{overrides}{$overr}{parsedValue} =~ s/\#\#userPref\:${fieldName}\#\#/$fieldValue/gm;
				}
			}
		}
		$cache->set(\%overrides, 60*60);
		$overridesRef = \%overrides;
	}
	return %$overridesRef;
}

#-------------------------------------------------------------------
sub getShortcut {
	my $self = shift;
	unless ($self->{_shortcut}) {
		$self->{_shortcut} = $self->getShortcutOriginal;
	}
	$self->{_shortcut}{_properties}{displayTitle} = undef if ($self->isDashlet);
	# Hide title by default.  If you want, you can create an override
	# to display it.  But it's being shown in the dragheader by default.
	my %overhash = $self->getOverrides;
	if (exists $overhash{overrides}) {
		my %overrides = %{$overhash{overrides}};
		foreach my $override (keys %overrides) {
			$self->{_shortcut}{_properties}{$override} = $overrides{$override}{parsedValue};
		}
		$self->{_shortcut}{_properties}{showReloadIcon} = $self->get("showReloadIcon");
	}
	return $self->{_shortcut};
}

#-------------------------------------------------------------------

=head2 getShortcutByCriteria ( hashRef )

This function will search for a asset that match a metadata criteria set.
If no asset is found, undef will be returned.

=cut

sub getShortcutByCriteria {
	my $self = shift;
	my $assetProxy = shift;
	my $criteria = $self->get("shortcutCriteria");
	my $order = $self->get("resolveMultiples");
	my $assetId = $self->getId;

	# Parse macro's in criteria
	WebGUI::Macro::process($self->session,\$criteria);

	# Once a asset is found, we will stick to that asset, 
	# to prevent the proxying of multiple- depth assets like Surveys and USS.
	my $scratchId;
	if ($assetId) {
		$scratchId = "Shortcut_" . $assetId;
		if($self->session->scratch->get($scratchId) && !$self->getValue("disableContentLock")) {
			unless ($self->session->var->isAdminOn) {
				return WebGUI::Asset->newByDynamicClass($self->session, $self->session->scratch->get($scratchId));
			}
		}
	}

	# $criteria = "State = Wisconsin AND Country != Sauk";
	#
	# State          =             Wisconsin AND Country != Sauk
	# |              |             |
	# |- $field      |_ $operator  |- $value
	# |_ $attribute                |_ $attribute
	my $operator = qr/<>|!=|=|>=|<=|>|<|like/i;
	my $attribute = qr/['"][^()|=><!]+['"]|[^()|=><!\s]+/i; 
                                                                                                      
	my $constraint = $criteria;
	
	# Get each expression from $criteria
	my $db = $self->session->db;
	my $counter = "b";
	my @joins = ();
	foreach my $expression ($criteria =~ /($attribute\s*$operator\s*$attribute)/gi) {
		# $expression will match "State = Wisconsin"

        	my $replacement = $expression;	# We don't want to modify $expression.
						# We need it later.
		push(@joins," left join metaData_values ".$counter."_v on a.assetId=".$counter."_v.assetId ");
		# Get the field (State) and the value (Wisconsin) from the $expression.
	        $expression =~ /($attribute)\s*$operator\s*($attribute)/gi;
	        my $field = $1;
	        my $value = $2;

		# quote the field / value variables.
		my $quotedField = $field;
		my $quotedValue = $value;
		unless ($field =~ /^\s*['"].*['"]\s*/) {
			$quotedField = $db->quote($field);
		}
                unless ($value =~ /^\s*['"].*['"]\s*/) {
                        $quotedValue = $db->quote($value);
                }
		
		# transform replacement from "State = Wisconsin" to 
		# "(fieldname=State and value = Wisconsin)"
		my $clause = "(".$counter."_p.fieldName=".$quotedField." and ".$counter."_v.value ";
	        $replacement =~ s/\Q$field/$clause/;
	        $replacement =~ s/\Q$value/$quotedValue )/i;

		# replace $expression with the new $replacement in $constraint.
	        $constraint =~ s/\Q$expression/$replacement/;
		push (@joins, " left join metaData_properties ".$counter."_p on ".$counter."_p.fieldId=".$counter."_v.fieldId ");
		$counter++;
	}

	my $sql = "select a.assetId from asset a
			".join("\n", @joins)."
			where a.className = ".$db->quote($self->getShortcutDefault->get("className"));
	# Add constraint only if it has been modified.
	$sql .= " and ".$constraint if (($constraint ne $criteria) && $constraint ne "");
	$sql .= " order by a.creationDate desc";

	# Execute the query with an unconditional read
	my @ids;
        my $sth = $db->unconditionalRead($sql);
        while (my ($data) = $sth->array) {
		push (@ids, $data);
        }
        $sth->finish;

	# No matching assets found.
        if (scalar(@ids) == 0) {
                return $self->getShortcutDefault; # fall back to the originally mirrored asset.
	}
	my $id;
	# Grab a wid from the results
	if ($order eq 'random') {
		$id = $ids[ rand @ids ];
	} else { 
				 #default order is mostRecent
		$id = $ids[0]; # 1st element in list is most recent.
	}

	# Store the matching assetId in user scratch. 
	$self->session->scratch->set($scratchId,$id) if ($scratchId);

	return WebGUI::Asset->newByDynamicClass($self->session, $id);
}

#-------------------------------------------------------------------
sub getShortcutDefault {
	my $self = shift;
	return WebGUI::Asset->newByDynamicClass($self->session, $self->get("shortcutToAssetId"));
}

#-------------------------------------------------------------------
sub getShortcutOriginal {
	my $self = shift;
	if ($self->get("shortcutByCriteria")) {
		return $self->getShortcutByCriteria;
	} else {
		return $self->getShortcutDefault;
	}
}

#-------------------------------------------------------------------
sub getPrefFieldsToShow {
	my $self = shift;
	return split("\n",$self->getValue("prefFieldsToShow"));
}

#-------------------------------------------------------------------
sub getPrefFieldsToImport {
	my $self = shift;
	return split("\n",$self->getValue("prefFieldsToImport"));
}

#----------------------------------------------------------------------------

=head2 getTemplateVars

Gets the template vars for the asset we're a shortcut to, with any overrides
applied.

=cut

sub getTemplateVars {
    my $self            = shift;

    my $shortcut        = $self->getShortcut;
    if ( $shortcut->can('getTemplateVars') ) {
        return $shortcut->getTemplateVars;
    }
    else {
        return $shortcut->get;
    }
}

#-------------------------------------------------------------------
sub isDashlet {
	my $self = shift;
	return 1 if ref $self->getParent eq 'WebGUI::Asset::Wobject::Dashboard';
	return 0;
}

#-------------------------------------------------------------------

sub notLinked {
	my $self = shift;
	$self->session->errorHandler->warn("Shortcut ".$self->getId." is linked to an asset ".$self->get("shortcutToAssetId").", which no longer exists.");
	return "The asset this shortcut is linked to no longer exists. You need to delete this shortcut.";
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
	$template->prepare($self->getMetaDataAsTemplateVariables);
	$self->{_viewTemplate} = $template;
	my $shortcut = $self->getShortcut;
	$shortcut->prepareView if defined $shortcut;
}


#-------------------------------------------------------------------
sub processPropertiesFromFormPost {
	my $self = shift;
	$self->SUPER::processPropertiesFromFormPost;
	my $scratchId = "Shortcut_" . $self->getId;
	$self->session->scratch->delete($scratchId);
	$self->uncacheOverrides;
}

#----------------------------------------------------------------------------

=head2 setOverride ( overrides )

Set this shortcut's overrides. C<overrides> is a hash reference of overrides
to set.

=cut

sub setOverride {
    my $self        = shift;
    my $override    = shift;

    croak "Shortcut->setOverride - first argument must be hash reference" 
        unless $override && ref $override eq "HASH";
    
    for my $key ( %$override ) {
        $self->session->db->write(
            "DELETE FROM Shortcut_overrides WHERE assetId=? AND fieldName=?",
            [$self->getId, $key],
        );
        $self->session->db->write(
            "INSERT INTO Shortcut_overrides VALUES (?,?,?)",
            [$self->getId, $key, $override->{$key}],
        );
    }
}

#-------------------------------------------------------------------
sub purge {
    my $self = shift;
    $self->session->db->write(<<'END_SQL', [$self->getId]);
DELETE FROM Shortcut_overrides
WHERE assetId = ?
END_SQL
    return $self->SUPER::purge(@_);
}

#-------------------------------------------------------------------
sub uncacheOverrides {
	my $self = shift;
	WebGUI::Cache->new($self->session,$self->_overridesCacheTag)->delete;
}

#-------------------------------------------------------------------
sub view {
	my $self = shift;
	my $content;
	my $i18n = WebGUI::International->new($self->session,"Asset_Shortcut");
	my $shortcut = $self->getShortcut;

	unless (defined $shortcut) {
		if ($self->canEdit) {
			return $self->session->style->userStyle('<a href="'.$self->getUrl("func=delete").'">'.$self->notLinked.'</a>');
		} else {
			return $self->notLinked;
		}
	}
	
	if ($self->get("shortcutToAssetId") eq $self->get("parentId")) {
		$content = $i18n->get("Displaying this shortcut would cause a feedback loop");
	} else {
        # Make sure the www_view method won't be skipped b/c the asset is cached.
        $shortcut->purgeCache();

		$content = $shortcut->view;

        # Make sure the overrides are not cached by the original asset.
        $shortcut->purgeCache();
	}

	my %var = (
		isShortcut => 1,
		'shortcut.content' => $content,
		'shortcut.label' => $i18n->get('assetName'),
		originalURL => $shortcut->getUrl,
		'shortcut.url'=>$self->getUrl
		);
	foreach my $prop (keys %{$self->{_shortcut}{_properties}}) {
		next if ($prop eq 'content' || $prop eq 'label' || $prop eq 'url');
		$var{'shortcut.'.$prop} = $self->{_shortcut}{_properties}{$prop};
	}
	return $self->processTemplate(\%var,undef, $self->{_viewTemplate});
}

#-------------------------------------------------------------------
sub www_edit {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	return $self->session->privilege->locked() unless $self->canEditIfLocked;
	my $i18n = WebGUI::International->new($self->session,"Asset_Shortcut");
	$self->getAdminConsole->addSubmenuItem($self->getUrl("func=manageOverrides"),$i18n->get("Manage Shortcut Overrides"));
	return $self->getAdminConsole->render($self->getEditForm->print,$i18n->get(2));
}

#-------------------------------------------------------------------
sub www_getUserPrefsForm {
	#This is a form retrieved by "ajax".
	my $self = shift;
	return 'You are no longer logged in' if $self->session->user->isVisitor;
	return 'You are not allowed to personalize this Dashboard.' unless $self->getParent->canPersonalize;
	my $output;
	my @fielden = $self->getPrefFieldsToShow;
	my $f = WebGUI::HTMLForm->new($self->session,extras=>' onsubmit="submitForm(this,\''.$self->getId.'\',\''.$self->getUrl.'\');return false;"');
	$f->raw('<table cellspacing="0" cellpadding="3" border="0">');
	$f->hidden(  
		-name => 'func', 
		-value => 'saveUserPrefs'
	);
	foreach my $fieldId (@fielden) {
		my $field = WebGUI::ProfileField->new($self->session,$fieldId);
		next unless $field;
		my $params = {};
		if (lc($field->get("fieldType")) eq 'textarea') {
			$params->{rows} = 4;
			$params->{columns} = 20;
		}
		if (lc($field->get("fieldType")) eq 'text') {
			$params->{size} = 20;
		}
		$f->raw($field->formField($params,1));
	}
	$f->submit({extras=>'className="nothing"'});
	$f->raw('</table>');
	my $tags = $self->session->style->generateAdditionalHeadTags();
	$output .= $tags.$f->print;

	return $output;
}

#-------------------------------------------------------------------
sub www_manageOverrides {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	my $i18n = WebGUI::International->new($self->session,"Asset_Shortcut");
	return $self->_submenu($self->getOverridesList,$i18n->get("Manage Shortcut Overrides"));
}

#-------------------------------------------------------------------
sub www_purgeOverrideCache {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	$self->uncacheOverrides;
	return $self->www_manageOverrides;
}

#-------------------------------------------------------------------
sub www_deleteOverride {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	$self->session->db->write('delete from Shortcut_overrides where assetId='.$self->session->db->quote($self->getId).' and fieldName='.$self->session->db->quote($self->session->form->process("fieldName")));
	$self->uncacheOverrides;
	return $self->www_manageOverrides;
}

#-------------------------------------------------------------------
sub www_saveUserPrefs {
	my $self = shift;
	return '' unless $self->getParent->canPersonalize;
	my @fellowFields = $self->getPrefFieldsToShow;
	my %data = ();
	$self->uncacheOverrides;
	my $i18n = WebGUI::International->new($self->session);
	my $u = WebGUI::User->new($self->session, $self->discernUserId);
	foreach my $fieldId ($self->session->form->param) {
		my $field = WebGUI::ProfileField->new($self->session,$fieldId);
		next unless $field;
		$data{$field->getId} = $field->formProcess;
        if ($field->getId eq 'email' && $field->isDuplicate($data{$field->getId})) {
			return '<li>'.$i18n->get(1072).'</li>';
		}
		if ($field->isRequired && !$data{$field->getId}) {
			return '<li>'.$field->getLabel.' '.$i18n->get(451).'</li>';
		}
		$u->profileField($field->getId,$data{$field->getId});
	}
	return $self->getParent->www_view;
}

#-------------------------------------------------------------------
sub www_getNewTitle {
	my $self = shift;
	return '' unless $self->getParent->canPersonalize;
	my $foo = $self->getShortcut;
	return $foo->{_properties}{title};
}

#-------------------------------------------------------------------
sub www_editOverride {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	my $i18n = WebGUI::International->new($self->session, "Asset_Shortcut");
	my $fieldName = $self->session->form->process("fieldName");

	# Using getOverrides is not the most efficient way to get the properties of only
	# one override, since it'll return all overrides (that have been set)
	my %overrides = $self->getOverrides;

	# Cannot fetch the original value from the overrides hash b/c it will be empty if
	# the override has not been set before. Also getOverrides uses a cached version of
	# the origValue, which can be out of date.
	my $origValue = $self->getShortcutOriginal->getValue($fieldName); 

	my $output = '';
	$output .= '</table>';
	
	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
	$f->hidden(
		-name		=> "func",
		-value		=> "saveOverride"
	);
	$f->hidden(
		-name		=> "overrideFieldName",
		-value		=> $fieldName
	);
	$f->readOnly(
		-label		=> $i18n->get("fieldName"),
		-value		=> $fieldName
	);
	$f->readOnly(
		-label		=> $i18n->get("Original Value"),
		-value		=> $origValue
	);

	# Fetch the parameters for the dynamic field.
	my (%params, %props);
	foreach my $def (@{$self->getShortcutOriginal->definition($self->session)}) {
		%props = (%props,%{$def->{properties}});
	}
	foreach my $key (keys %{$props{$fieldName}}) {
		next if ($key eq "tab");
		$params{$key} = $props{$fieldName}{$key};
	}
	$params{value} = $origValue;
	$params{name} = $fieldName;
	$params{label} = $params{label} || $i18n->get("Edit Field Directly");
	$params{hoverHelp} = $params{hoverHelp} || $i18n->get("Use this field to edit the override using the native form handler for this field type");

	if ($params{fieldType} eq 'template') {$params{namespace} = $params{namespace} || WebGUI::Asset->newByDynamicClass($self->session, $origValue)->get("namespace");}

	$f->dynamicField(%params);
	$f->textarea(
		-name		=> "newOverrideValueText",
		-label		=> $i18n->get("New Override Value"),
		-value		=> $overrides{overrides}{$fieldName}{newValue},
		-hoverHelp	=> $i18n->get("Place something in this box if you dont want to use the automatically generated field")
	);
	$f->readOnly(
		-label		=> $i18n->get("Replacement Value"),
		-value		=> $overrides{overrides}{$fieldName}{parsedValue},
		-hoverHelp	=> $i18n->get("This is the example output of the field when parsed for user preference macros")
	) if $self->isDashlet;
	$f->submit;

	$output .= $f->print;
	
	return $self->_submenu($output,$i18n->get('Edit Override'));
}

#-------------------------------------------------------------------
sub www_saveOverride {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    my $fieldName = $self->session->form->process("overrideFieldName");
    my %overrides = $self->getOverrides;
    my $output = '';
    my %props;
    foreach my $def (@{$self->getShortcutOriginal->definition($self->session)}) {
        %props = (%props,%{$def->{properties}});
    }
    my $fieldType = $props{$fieldName}{fieldType};
    my $value = $self->session->form->process($fieldName,$fieldType);
    $value = $self->session->form->process("newOverrideValueText") || $value;
    $self->session->db->write("delete from Shortcut_overrides where assetId=".$self->session->db->quote($self->getId)." and fieldName=".$self->session->db->quote($fieldName));
    $self->session->db->write("insert into Shortcut_overrides values (".$self->session->db->quote($self->getId).",".$self->session->db->quote($fieldName).",".$self->session->db->quote($value).")");
    $self->uncacheOverrides;
    $self->getShortcutOriginal->purgeCache();
    return $self->www_manageOverrides;
}

#-------------------------------------------------------------------
sub www_view {
        my $self = shift;
        my $check = $self->checkView;
        return $check if defined $check;
        my $shortcut = $self->getShortcut;
        $self->prepareView;

        # Make sure the www_view method won't be skipped b/c the asset is cached.
        $shortcut->purgeCache();

        if ($shortcut->isa('WebGUI::Asset::Wobject')) {
                $self->session->http->setLastModified($self->getContentLastModified);
                $self->session->http->sendHeader;
                my $style = $shortcut->processStyle($self->getSeparator);
                my ($head, $foot) = split($self->getSeparator,$style);
                $self->session->output->print($head, 1);
                $self->session->output->print($self->view);
                $self->session->output->print($foot, 1);
                return "chunked";
        }
        my $output = $shortcut->www_view;
        
        # Make sure the overrides are not cached by the original asset.
        $shortcut->purgeCache();
        return $output;
}

#----------------------------------------------------------------------------

=head1 STATIC METHODS

These methods are called using CLASS->method

#----------------------------------------------------------------------------

=head2 getShortcutsForAssetId ( session, assetId [, properties] )

Get an arrayref of assetIds of all the shortcuts for the passed-in assetId.

"properties" is a hash reference of properties to give to getLineage. 
Probably the only useful key will be "returnObjects".

=cut

sub getShortcutsForAssetId {
    my $class       = shift;
    my $session     = shift;
    my $assetId     = shift;
    my $properties  = shift || {};
    
    croak "First argument to getShortcutsForAssetId must be WebGUI::Session"
        unless $session && $session->isa("WebGUI::Session");
    croak "Second argument to getShortcutsForAssetId must be assetId"
        unless $assetId;
    croak "Third argument to getShortcutsForAssetId must be hash reference"
        if $properties && !ref $properties eq "HASH";

    my $db      = $session->db;

    $properties->{ joinClass            } = 'WebGUI::Asset::Shortcut';
    $properties->{ whereClause          } = 'Shortcut.shortcutToAssetId = ' . $db->quote($assetId);

    return WebGUI::Asset->getRoot($session)->getLineage(['descendants'], $properties); 
}

1;

