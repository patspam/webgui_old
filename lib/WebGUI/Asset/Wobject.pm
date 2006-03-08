package WebGUI::Asset::Wobject;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2006 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

#use CGI::Util qw(rearrange);
use DBI;
use strict qw(subs vars);
use Tie::IxHash;
use WebGUI::Asset;
use WebGUI::International;
use WebGUI::Macro;
use WebGUI::SQL;
use WebGUI::Utility;

our @ISA = qw(WebGUI::Asset);

=head1 NAME

Package WebGUI::Asset::Wobject

=head1 DESCRIPTION

An abstract class for all other wobjects to extend.

=head1 SYNOPSIS

 use WebGUI::Wobject;
 our @ISA = qw(WebGUI::Wobject);

See the subclasses in lib/WebGUI/Wobjects for details.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 definition ( session, [definition] )

Returns an array reference of definitions. Adds tableName, className, properties to array definition.

=head3 definition

An array of hashes to prepend to the list

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session,'Asset_Wobject');
	my %properties;
	tie %properties, 'Tie::IxHash';
	%properties = (
	description=>{
		fieldType=>'HTMLArea',
		defaultValue=>undef,
		tab=>"properties",
		label=>$i18n->get(85),
		hoverHelp=>$i18n->get('85 description')
	},
	displayTitle=>{
		fieldType=>'yesNo',
		defaultValue=>1,
		tab=>"display",
		label=>$i18n->get(174),
		hoverHelp=>$i18n->get('174 description'),
		uiLevel=>5
	},
	cacheTimeout=>{
		fieldType=>'interval',
		defaultValue=>60,
		tab=>"display",
		label=>$i18n->get(895),
		hoverHelp=>$i18n->get('895 description'),
		uiLevel=>8
	},
	cacheTimeoutVisitor=>{
		fieldType=>'interval',
		defaultValue=>600,
		tab=>"display",
		label=>$i18n->get(896),
		hoverHelp=>$i18n->get('896 description'),
		uiLevel=>8
	},
	styleTemplateId=>{
		fieldType=>'template',
		defaultValue=>undef,
		tab=>"display",
		label=>$i18n->get(1073),
		hoverHelp=>$i18n->get('1073 description'),
		namespace=>'style'
	},
	printableStyleTemplateId=>{
		fieldType=>'template',
		defaultValue=>undef,
		tab=>"display",
		label=>$i18n->get(1079),
		hoverHelp=>$i18n->get('1079 description'),
		namespace=>'style'
	}
	);
	push(@{$definition}, {
		tableName=>'wobject',
		className=>'WebGUI::Asset::Wobject',
		autoGenerateForms=>1,
		properties => \%properties
	});
	return $class->SUPER::definition($session,$definition);
}


#-------------------------------------------------------------------

=head2 deletePageCache ( )

Deletes the rendered page cache for this wobject.

=cut

sub deletePageCache {
	my $self = shift;
        WebGUI::Cache->new($self->session,"wobject_".$self->getId."_".$self->session->user->userId)->delete;
}

#-------------------------------------------------------------------

=head2 deleteCollateral ( tableName, keyName, keyValue )

Deletes a row of collateral data where keyName=keyValue.

=head3 tableName

The name of the table you wish to delete the data from.

=head3 keyName

The name of a column in the table. Is not checked for invalid input. 

=head3 keyValue

Criteria (value) used to find the data to delete.

=cut

sub deleteCollateral {
	my $self = shift;
	my $table = shift;
	my $keyName = shift;
	my $keyValue = shift;
        $self->session->db->write("delete from $table where $keyName=".$self->session->db->quote($keyValue));
	$self->updateHistory("deleted collateral item ".$keyName." ".$keyValue);
}


#-------------------------------------------------------------------

=head2 confirm ( message,yesURL [,noURL,vitalComparison] )

Returns an HTML string that presents a link to confirm and a link to cancel an action, both Internationalized text. 

=head3 message

A string containing the message to prompt the user for this action.

=head3 yesURL

A URL to the web method to execute if the user confirms the action.

=head3 noURL

A URL to the web method to execute if the user denies the action.  Defaults back to the current page.

=head3 vitalComparison

A comparison expression to be used when checking whether the action should be allowed to continue. Typically this is used when the action is a delete of some sort.

=cut

sub confirm {
	my $self = shift;
        return $self->session->privilege->vitalComponent() if ($_[4]);
	my $noURL = $_[3] || $_[0]->getUrl;
	my $i18n = WebGUI::International->new($self->session,'Asset_Wobject');
        my $output = '<h1>'.$i18n->get(42).'</h1>';
        $output .= $_[1].'<p>';
        $output .= '<div align="center"><a href="'.$_[2].'">'.$i18n->get(44).'</a>';
        $output .= ' &nbsp; <a href="'.$noURL.'">'.$i18n->get(45).'</a></div>';
        return $output;
}



#-------------------------------------------------------------------

=head2 getCollateral ( tableName, keyName, keyValue ) 

Returns a hash reference containing a row of collateral data.

=head3 tableName

The name of the table you wish to retrieve the data from.

=head3 keyName

A name of a column in the table. Usually the primary key column.

=head3 keyValue

A string containing the key value. If key value is equal to "new" or null, then an empty hashRef containing only keyName=>"new" will be returned to avoid strict errors.

=cut

sub getCollateral {
	my $self = shift;
	my $table = shift;
	my $keyName = shift;
	my $keyValue = shift;
	if ($keyValue eq "new" || $keyValue eq "") {
		return {$keyName=>"new"};
	} else {
		return $self->session->db->quickHashRef("select * from $table where $keyName=".$self->session->db->quote($keyValue),$self->session->dbSlave);
	}
}


#-------------------------------------------------------------------

=head2 getEditForm ()

Returns the TabForm object that will be used in generating the edit page for this wobject.

=cut

sub getEditForm {
	my $self = shift;
	my $tabform = $self->SUPER::getEditForm();
	foreach my $definition (reverse @{$self->definition($self->session)}) {
		my $properties = $definition->{properties};
		next unless ($definition->{autoGenerateForms});
		foreach my $fieldname (keys %{$properties}) {
			my %params;
			foreach my $key (keys %{$properties->{$fieldname}}) {
				next if ($key eq "tab");
				$params{$key} = $properties->{$fieldname}{$key};
			}
			$params{value} = $self->getValue($fieldname);
			$params{name} = $fieldname;
			my $tab = $properties->{$fieldname}{tab} || "properties";
			$tabform->getTab($tab)->dynamicField(%params);
		}
	}
	return $tabform;
}




#-------------------------------------------------------------------
                                                                                                                             
=head2 logView ( )
              
Logs the view of the wobject to the passive profiling mechanism.                                                                                                               
=cut

sub logView {
	my $self = shift;
	if ($self->session->setting->get("passiveProfilingEnabled")) {
		WebGUI::PassiveProfiling::add($self->session,$self->get("assetId"));
		WebGUI::PassiveProfiling::addPage($self->session,$self->get("assetId"));	# add wobjects on asset to passive profile log
	}
	return;
}


#-------------------------------------------------------------------

=head2 moveCollateralDown ( tableName, keyName, keyValue [ , setName, setValue ] )

Moves a collateral data item down one position. This assumes that the collateral data table has a column called "assetId" that identifies the wobject, and a column called "sequenceNumber" that determines the position of the data item.

=head3 tableName

A string indicating the table that contains the collateral data.

=head3 keyName

A string indicating the name of the column that uniquely identifies this collateral data item.

=head3 keyValue

An iid that uniquely identifies this collateral data item.

=head3 setName

By default this method assumes that the collateral will have an assetId in the table. However, since there is not always a assetId to separate one data set from another, you may specify another field to do that.

=head3 setValue

The value of the column defined by "setName" to select a data set from.

=cut

### NOTE: There is a redundant use of assetId in some of these statements on purpose to support
### two different types of collateral data.

sub moveCollateralDown {
	my $self = shift;
	my $table = shift;
	my $keyName = shift;
	my $keyValue = shift;
	my $setName = shift || "assetId";
        my $setValue = shift;
	unless (defined $setValue) {
		$setValue = $self->get($setName);
	}
	$self->session->db->beginTransaction;
        my ($seq) = $self->session->db->quickArray("select sequenceNumber from $table where $keyName=".$self->session->db->quote($keyValue)." and $setName=".$self->session->db->quote($setValue));
        my ($id) = $self->session->db->quickArray("select $keyName from $table where $setName=".$self->session->db->quote($setValue)." and sequenceNumber=$seq+1");
        if ($id ne "") {
                $self->session->db->write("update $table set sequenceNumber=sequenceNumber+1 where $keyName=".$self->session->db->quote($keyValue)." and $setName=" .$self->session->db->quote($setValue));
                $self->session->db->write("update $table set sequenceNumber=sequenceNumber-1 where $keyName=".$self->session->db->quote($id)." and $setName=" .$self->session->db->quote($setValue));
         }
	$self->session->db->commit;
}


#-------------------------------------------------------------------

=head2 moveCollateralUp ( tableName, keyName, keyValue [ , setName, setValue ] )

Moves a collateral data item up one position. This assumes that the collateral data table has a column called "assetId" that identifies the wobject, and a column called "sequenceNumber" that determines the position of the data item.

=head3 tableName

A string indicating the table that contains the collateral data.

=head3 keyName

A string indicating the name of the column that uniquely identifies this collateral data item.

=head3 keyValue

An id that uniquely identifies this collateral data item.

=head3 setName

By default this method assumes that the collateral will have a asset in the table. However, since there is not always a assetId to separate one data set from another, you may specify another field to do that.

=head3 setValue

The value of the column defined by "setName" to select a data set from.

=cut

### NOTE: There is a redundant use of assetId in some of these statements on purpose to support
### two different types of collateral data.

sub moveCollateralUp {
	my $self = shift;
	my $table = shift;
	my $keyName = shift;
	my $keyValue = shift;
        my $setName = shift || "assetId";
        my $setValue = shift;
	unless (defined $setValue) {
		$setValue = $self->get($setName);
	}
	$self->session->db->beginTransaction;
        my ($seq) = $self->session->db->quickArray("select sequenceNumber from $table where $keyName=".$self->session->db->quote($keyValue)." and $setName=".$self->session->db->quote($setValue));
        my ($id) = $self->session->db->quickArray("select $keyName from $table where $setName=".$self->session->db->quote($setValue)
		." and sequenceNumber=$seq-1");
        if ($id ne "") {
                $self->session->db->write("update $table set sequenceNumber=sequenceNumber-1 where $keyName=".$self->session->db->quote($keyValue)." and $setName="
			.$self->session->db->quote($setValue));
                $self->session->db->write("update $table set sequenceNumber=sequenceNumber+1 where $keyName=".$self->session->db->quote($id)." and $setName="
			.$self->session->db->quote($setValue));
        }
	$self->session->db->commit;
}

#-------------------------------------------------------------------
sub processPropertiesFromFormPost {
	my $self = shift;
	$self->SUPER::processPropertiesFromFormPost;
	$self->deletePageCache;
}


#-------------------------------------------------------------------

=head2 processStyle (output)

Returns output parsed under the current style.

=head3 output

An HTML blob to be parsed into the current style.

=cut

sub processStyle {
	my $self = shift;
	my $output = shift;
	return $self->session->style->process($output,$self->get("styleTemplateId"));
}


#-------------------------------------------------------------------

=head2 reorderCollateral ( tableName,keyName [,setName,setValue] )

Resequences collateral data. Typically useful after deleting a collateral item to remove the gap created by the deletion.

=head3 tableName

The name of the table to resequence.

=head3 keyName

The key column name used to determine which data needs sorting within the table.

=head3 setName

Defaults to "assetId". This is used to define which data set to reorder.

=head3 setValue

Used to define which data set to reorder. Defaults to the value of setName (default "assetId", see above) in the wobject properties.

=cut

sub reorderCollateral {
	my $self = shift;
	my $table = shift;
	my $keyName = shift;
	my $setName = shift || "assetId";
	my $setValue = shift || $self->get($setName);
	my $i = 1;
        my $sth = $self->session->db->read("select $keyName from $table where $setName=".$self->session->db->quote($setValue)." order by sequenceNumber");
        while (my ($id) = $sth->array) {
                $self->session->db->write("update $table set sequenceNumber=$i where $setName=".$self->session->db->quote($setValue)." and $keyName=".$self->session->db->quote($id));
                $i++;
        }
        $sth->finish;
}


#-----------------------------------------------------------------

=head2 setCollateral ( tableName,keyName,properties [,useSequenceNumber,useAssetId,setName,setValue] )

Performs and insert/update of collateral data for any wobject's collateral data. Returns the primary key value for that row of data.

=head3 tableName

The name of the table to insert the data.

=head3 keyName

The column name of the primary key in the table specified above. 

=head3 properties

A hash reference containing the name/value pairs to be inserted into the database where the name is the column name. Note that the primary key should be specified in this list, and if it's value is "new" or null a new row will be created.

=head3 useSequenceNumber

If set to "1", a new sequenceNumber will be generated and inserted into the row. Note that this means you must have a sequenceNumber column in the table. Also note that this requires the presence of the assetId column. Defaults to "1".

=head3 useAssetId

If set to "1", the current assetId will be inserted into the table upon creation of a new row. Note that this means the table better have a assetId column. Defaults to "1".  

=head3 setName

If this collateral data set is not grouped by assetId, but by another column then specify that column here. The useSequenceNumber parameter will then use this column name instead of assetId to generate the sequenceNumber.

=head3 setValue

If you've specified a setName you may also set a value for that set.  Defaults to the value for this id from the wobject properties.

=cut

sub setCollateral {
	my $self = shift;
	my $table = shift;
	my $keyName = shift;
	my $properties = shift;
	my $useSequence = shift;
	my $useAssetId = shift;
	my $setName = shift || "assetId";
	my $setValue = shift || $self->get($setName);
	my ($key, $seq, $dbkeys, $dbvalues);
	my $counter = 0;
	my $sql;
	if ($properties->{$keyName} eq "new" || $properties->{$keyName} eq "") {
		$properties->{$keyName} = $self->session->id->generate();
		$sql = "insert into $table (";
		my $dbkeys = "";
     		my $dbvalues = "";
		unless ($useSequence eq "0") {
			unless (exists $properties->{sequenceNumber}) {
				my ($seq) = $self->session->db->quickArray("select max(sequenceNumber) from $table where $setName=".$self->session->db->quote($setValue));
				$properties->{sequenceNumber} = $seq+1;
			}
		} 
		unless ($useAssetId eq "0") {
			$properties->{assetId} = $self->get("assetId");
		}
		foreach my $key (keys %{$properties}) {
			if ($counter++ > 0) {
				$dbkeys .= ',';
				$dbvalues .= ',';
			}
			$dbkeys .= $key;
			$dbvalues .= $self->session->db->quote($properties->{$key});
		}
		$sql .= $dbkeys.') values ('.$dbvalues.')';
		$self->updateHistory("added collateral item ".$table." ".$properties->{$keyName});
	} else {
		$sql = "update $table set ";
		foreach my $key (keys %{$properties}) {
			unless ($key eq "sequenceNumber") {
				$sql .= ',' if ($counter++ > 0);
				$sql .= $key."=".$self->session->db->quote($properties->{$key});
			}
		}
		$sql .= " where $keyName=".$self->session->db->quote($properties->{$keyName});
		$self->updateHistory("edited collateral item ".$table." ".$properties->{$keyName});
	}
  	$self->session->db->write($sql);
	$self->reorderCollateral($table,$keyName,$setName,$setValue) if ($properties->{sequenceNumber} < 0);
	return $properties->{$keyName};
}


sub www_edit {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	my ($tag) = ($self->get("className") =~ /::(\w+)$/);
	my $tag2 = $tag;
	$tag =~ s/([a-z])([A-Z])/$1 $2/g;  #Separate studly caps
	$tag =~ s/([A-Z]+(?![a-z]))/$1 /g; #Separate acronyms
	$self->getAdminConsole->setHelp(lc($tag)." add/edit", "Asset_".$tag2);
	my $i18n = WebGUI::International->new($self->session,'Asset_Wobject');
	my $addEdit = ($self->session->form->process("func") eq 'add') ? $i18n->get('add') : $i18n->get('edit');
	return $self->getAdminConsole->render($self->getEditForm->print,$addEdit.' '.$self->getName);
}


#-------------------------------------------------------------------

=head2 www_view ( [ disableCache ] )

Renders self->view based upon current style, subject to timeouts. Returns Privilege::noAccess() if canView is False.

=cut

sub www_view {
	my $self = shift;
	unless ($self->canView) {
		if ($self->get("state") eq "published") { # no privileges, make em log in
			return $self->session->privilege->noAccess();
		} elsif ($self->session->var->get("adminOn") && $self->get("state") =~ /^trash/) { # show em trash
			$self->session->http->setRedirect($self->getUrl("func=manageTrash"));
			return "";
		} elsif ($self->session->var->get("adminOn") && $self->get("state") =~ /^clipboard/) { # show em clipboard
			$self->session->http->setRedirect($self->getUrl("func=manageClipboard"));
			return "";
		} else { # tell em it doesn't exist anymore
			$self->session->http->setStatus("410");
			return WebGUI::Asset->getNotFound($self->session)->www_view;
		}
	}
	if ($self->get("encryptPage") && $self->session->env->get("HTTPS") ne "on") {
                $self->session->http->setRedirect($self->getUrl);
                return "";
        }
	$self->logView();
	# must find a way to do this next line better
	$self->session->http->setCookie("wgSession",$self->session->var->{_var}{sessionId}) unless $self->session->var->{_var}{sessionId} eq $self->session->http->getCookies->{"wgSession"};
	$self->session->http->getHeader;	
	$self->prepareView;
	my $style = $self->processStyle("~~~");
	my ($head, $foot) = split("~~~",$style);
	$self->session->output->print($head);
	$self->session->output->print($self->view);
	$self->session->output->print($foot);
}

#-------------------------------------------------------------------

=head2 www_view ( [ disableCache ] )

Renders self->view based upon current style, subject to timeouts. Returns Privilege::noAccess() if canView is False.

=cut
sub www_viewOld {
	my $self = shift;
	my $disableCache = shift;
	my $cache;
	my $output;
        my $useCache = (
		$self->session->form->process("op") eq "" && $self->session->form->process("pn") eq "" 
		&& (
			( $self->get("cacheTimeout") > 10 && $self->session->user->userId ne '1') 
			|| ( $self->get("cacheTimeoutVisitor") > 10 && $self->session->user->userId eq '1')
		) 
		&& !( $self->session->var->get("adminOn") || $disableCache)
	);
	if ($useCache) {
               	$cache = WebGUI::Cache->new($self->session,"wobject_".$self->getId."_".$self->session->user->userId);
           	$output = $cache->get;
	}
	unless ($output) {
		$output = $self->processStyle($self->view);
		my $ttl;
		if ($self->session->user->userId eq '1') {
			$ttl = $self->get("cacheTimeoutVisitor");
		} else {
			$ttl = $self->get("cacheTimeout");
		}
		$cache->set($output, $ttl) if ($useCache && !$self->session->http->isRedirect());
	}
	return $output;
}

1;

