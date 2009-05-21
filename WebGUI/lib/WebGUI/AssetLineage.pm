package WebGUI::Asset;

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
use Carp qw( croak );

=head1 NAME

Package WebGUI::Asset (AssetLineage)

=head1 DESCRIPTION

This is a mixin package for WebGUI::Asset that contains all lineage related functions.

=head1 SYNOPSIS

 use WebGUI::Asset;

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 addChild ( properties [, id, revisionDate, options ] )

Adds a child asset to a parent. Creates a new AssetID for child. Makes the parent know that it has children. Adds a new asset to the asset table. Returns the newly created Asset.

=head3 properties

A hash reference containing a list of properties to associate with the child. The only required property value is "className"

=head3 id

A unique 22 character ID.  By default WebGUI will generate this and you should almost never specify it. This is mainly here for developers that want to include default templates in their plug-ins.

=head3 revisionDate

An epoch representing the time this asset was created.

=head3 options

A hash reference that allows passed in options to change how this method behaves.

=head4 skipAutoCommitWorkflows

If this is set to 1 assets that normally autocommit their workflows (like CS Posts) won't do that.

=cut

sub addChild {
	my $self        = shift;
	my $properties  = shift;
	my $id          = shift || $self->session->id->generate();
	my $now         = shift || $self->session->datetime->time();
	my $options     = shift;

	# Check if it is possible to add a child to this asset. If not add it as a sibling of this asset.
	if (length($self->get("lineage")) >= 252) {
		$self->session->errorHandler->warn('Tried to add child to asset "'.$self->getId.'" which is already on the deepest level. Adding it as a sibling instead.');
		return $self->getParent->addChild($properties, $id, $now, $options);
	}
	my $lineage = $self->get("lineage").$self->getNextChildRank;
	$self->{_hasChildren} = 1;
	$self->session->db->beginTransaction;
	$self->session->db->write("insert into asset (assetId, parentId, lineage, creationDate, createdBy, className, state) values (?,?,?,?,?,?,'published')",
		[$id,$self->getId,$lineage,$now,$self->session->user->userId,$properties->{className}]);
	$self->session->db->commit;
	$properties->{assetId} = $id;
	$properties->{parentId} = $self->getId;
	my $temp = WebGUI::Asset->newByPropertyHashRef($self->session,$properties) || croak "Couldn't create a new $properties->{className} asset!";
	$temp->{_parent} = $self;
	my $newAsset = $temp->addRevision($properties, $now, $options); 
	$self->updateHistory("added child ".$id);
	$self->session->http->setStatus(201,"Asset Creation Successful");
	return $newAsset;
}


#-------------------------------------------------------------------

=head2 cascadeLineage ( newLineage [,oldLineage] )

Updates lineage when asset is moved. Prepends newLineage to the lineage
"stack."  The change only occurs in the db, no in the objects.

=head3 newLineage

An asset descriptor that indicates the direct tree branch containing the asset.

=head3 oldLineage

If not present, asset's existing lineage is used.

=cut

sub cascadeLineage {
    my $self = shift;
    my $newLineage = shift;
    my $oldLineage = shift || $self->get("lineage");
    my $records = $self->session->db->write(
        "UPDATE asset SET lineage=CONCAT(?,SUBSTRING(lineage,?)) WHERE lineage LIKE ?",
        [$newLineage, length($oldLineage) + 1, $oldLineage . '%']
    );
    my $cache = WebGUI::Cache->new($self->session);
    if ($records > 20) {
        $cache->flush;
    }
    else {
        my $descendants = $self->session->db->read("SELECT assetId FROM asset WHERE lineage LIKE ?", [$newLineage . '%']);
        while (my ($assetId, $lineage) = $descendants->array) {
            $cache->deleteChunk(["asset",$assetId]);
        }
        $descendants->finish;
    }
}

#-------------------------------------------------------------------

=head2 demote ( )

Swaps lineage with sister below. Returns 1 if there is a sister to swap. Otherwise returns 0.

This will update the lineage of $self, but not the sister.

=cut

sub demote {
	my $self = shift;
	my ($sisterLineage) = $self->session->db->quickArray("select min(lineage) from asset 
		where parentId=? and state='published' and lineage>?",[$self->get('parentId'), $self->get('lineage')]);
	if (defined $sisterLineage) {
		$self->swapRank($sisterLineage);
		$self->{_properties}{lineage} = $sisterLineage;
		return 1;
	}
	return 0;
}


#-------------------------------------------------------------------

=head2 formatRank ( value )

Returns a rank as six digits with leading zeros.

=head3 value

An integer up to 6 digits. Would normally be one section (rank) of a lineage.

=cut

sub formatRank {
	my $self = shift;
	my $value = shift;
	return sprintf("%06d",$value);
}


#-------------------------------------------------------------------

=head2 getChildCount ( opts )

Returns the number of children this asset has. This excludes assets in the trash or clipboard.

=head3 opts

A hashref of options.  Currently only one option is supported.

=head4 includeTrash

If this value of this hash key is true, then assets in any state will be counted.  Normally,
only those that are published or achived are counted.

=cut

sub getChildCount {
	my $self = shift;
    my $opts = shift || {};
	my $stateWhere = $opts->{includeTrash} ? '' : "asset.state='published' and";
	my ($count) = $self->session->db->quickArray("select count(distinct asset.assetId) from asset, assetData where asset.assetId=assetData.assetId and $stateWhere parentId=? and (assetData.status in ('approved', 'archived') or assetData.tagId=?)", [$self->getId, $self->session->scratch->get('versionTag')]);
	return $count;
}

#-------------------------------------------------------------------

=head2 getDescendantCount ( )

Returns the number of descendants this asset has. This includes only assets that are published, and not
in the clipboard or trash.

=cut

sub getDescendantCount {
	my $self = shift;
	my ($count) = $self->session->db->quickArray("select count(distinct asset.assetId) from asset, assetData where asset.assetId=assetData.assetId and asset.state = 'published' and assetData.status in ('approved','archived') and asset.lineage like ?", [$self->get("lineage")."%"]);
	$count--; # have to subtract self
	return $count;
}

#-------------------------------------------------------------------

=head2 getFirstChild ( )

Returns the highest rank, top of the highest rank Asset under current Asset.

=cut

sub getFirstChild {
	my $self = shift;
	unless (exists $self->{_firstChild}) {
		my $assetLineage = $self->session->stow->get("assetLineage");
		my $lineage = $assetLineage->{firstChild}{$self->getId};
		unless ($lineage) {
			($lineage) = $self->session->db->quickArray("select min(asset.lineage) from asset,assetData where asset.parentId=? and asset.assetId=assetData.assetId and asset.state='published'",[$self->getId]);
			unless ($self->session->config->get("disableCache")) {
				$assetLineage->{firstChild}{$self->getId} = $lineage;
				$self->session->stow->set("assetLineage", $assetLineage);
			}
		}
		$self->{_firstChild} = WebGUI::Asset->newByLineage($self->session,$lineage);
	}
	return $self->{_firstChild};
}


#-------------------------------------------------------------------

=head2 getLastChild ( )

Returns the lowest rank, bottom of the lowest rank Asset under current Asset.

=cut

sub getLastChild {
	my $self = shift;
	unless (exists $self->{_lastChild}) {
		my $assetLineage = $self->session->stow->get("assetLineage");
		my $lineage = $assetLineage->{lastChild}{$self->getId};
		unless ($lineage) {
			($lineage) = $self->session->db->quickArray("select max(asset.lineage) from asset,assetData where asset.parentId=? and asset.assetId=assetData.assetId and asset.state='published'",[$self->getId]);
			$assetLineage->{lastChild}{$self->getId} = $lineage;
			$self->session->stow->set("assetLineage", $assetLineage);
		}
		$self->{_lastChild} = WebGUI::Asset->newByLineage($self->session,$lineage);
	}
	return $self->{_lastChild};
}

#-------------------------------------------------------------------

=head2 getLineage ( relatives,rules )

Returns an array reference of relative asset ids based upon rules.

=head3 relatives

An array reference of relatives to retrieve. Valid parameters are "siblings", "children", "ancestors", "self", "descendants", "pedigree".  If you want to retrieve all assets in the tree, use getRoot($session)->getLineage(["self","descendants"],{returnObjects=>1});

=head3 rules

A hash reference comprising modifiers to relative listing. Rules include:

=head4 statesToInclude

An array reference containing a list of states that should be returned. Defaults to 'published'. Options include
'published', 'trash', 'clipboard', 'clipboard-limbo' and 'trash-limbo'.

=head4 statusToInclude

An array reference containing a list of status that should be returned. Defaults to 'approved'. Options include 'approved', 'pending', and 'archived'.

=head4 endingLineageLength

An integer limiting the length of the lineages of the assets to be returned. This can help limit levels of depth in the asset tree.

=head4 assetToPedigree

An asset object reference to draw a pedigree from. A pedigree includes ancestors, siblings, descendants and other information. It's specifically used in flexing navigations.

=head4 ancestorLimit

An integer describing how many levels of ancestry from the start point that should be retrieved.

=head4 excludeClasses

An array reference containing a list of asset classes to remove from the result set. The opposite of the includOnlyClasses rule.

=head4 returnObjects

A boolean indicating that we should return objects rather than asset ids.

=head4 returnSQL

A boolean indicating that we should return the sql statement rather than asset ids.

=head4 invertTree

A boolean indicating whether the resulting asset tree should be returned in reverse order.

=head4 includeOnlyClasses

An array reference containing a list of asset classes to include in the result. If this is specified then no other classes except these will be returned. The opposite of the excludeClasses rule.

=head4 isa

A classname where you can look for classes of a similar base class. For example, if you're looking for Donations, Subscriptions, Products and other subclasses of WebGUI::Asset::Sku, then set isa to 'WebGUI::Asset::Sku'.

=head4 includeArchived

A boolean indicating that we should include archived assets in the result set.

=head4 joinClass

A string containing as asset class to join in. There is no real reason to use a joinClass without a whereClause, but it's trivial to use a whereClause if you don't use a joinClass.  You will only be able to filter on the asset table, however.

=head4 whereClause

A string containing extra where clause information for the query.

=head4 orderByClause 

A string containing an order by clause (without the "order by"). If specified,
will override the "invertTree" option.

=head4 limit

The maximum amount of entries to return

=cut

sub getLineage {
	my $self = shift;
	my $relatives = shift;
	my $rules = shift;
	my $lineage = $self->get("lineage");
	
    my $sql = $self->getLineageSql($relatives,$rules);

    unless ($sql) {
        return [];
    }

	my @lineage;
	my %relativeCache;
	my $sth = $self->session->db->read($sql);
	while (my ($id, $class, $parentId, $version) = $sth->array) {
		# create whatever type of object was requested
		my $asset;
		if ($rules->{returnObjects}) {
			if ($self->getId eq $id) { # possibly save ourselves a hit to the database
				$asset =  $self;
			} else {
				$asset = WebGUI::Asset->new($self->session,$id, $class, $version);
				if (!defined $asset) { # won't catch everything, but it will help some if an asset blows up
					$self->session->errorHandler->error("AssetLineage::getLineage - failed to instanciate asset with assetId $id, className $class, and revision $version");
					next;
				}
			}
		} else {
			$asset = $id;
		}
		# since we have the relatives info now, why not cache it
		if ($rules->{returnObjects}) {
			my $parent = $relativeCache{$parentId};
			$relativeCache{$id} = $asset;
			$asset->{_parent} = $parent if exists $relativeCache{$parentId};
			$parent->{_firstChild} = $asset unless(exists $parent->{_firstChild});
			$parent->{_lastChild} = $asset;
		}
		push(@lineage,$asset);
	}
	$sth->finish;
	return \@lineage;
}

#-------------------------------------------------------------------

=head2 getLineageIterator ( relatives,rules )

Takes the same parameters as getLineage, but instead of returning a list
it returns an iterator.  Calling the iterator will return instantiated assets,
or undef when there are no more assets available.  The iterator is just a sub
ref, call like $asset = $iterator->()

=cut

sub getLineageIterator {
    my $self = shift;
    my $relatives = shift;
    my $rules = shift;

    my $sql = $self->getLineageSql($relatives, $rules);

    my $sth = $self->session->db->read($sql);
    my $sub = sub {
        my $assetInfo = $sth->hashRef;
        return
            if !$assetInfo;
        my $asset = WebGUI::Asset->new(
            $self->session, $assetInfo->{assetId}, $assetInfo->{className}, $assetInfo->{revisionDate}
        );
        if (!$asset) {
            WebGUI::Error::ObjectNotFound->throw(id => $assetInfo->{assetId});
        }
        return $asset;
    };
    return $sub;
}

#-------------------------------------------------------------------

=head2 getLineageLength ( )

Returns the number of Asset members in an Asset's lineage.

=cut


sub getLineageLength {
	my $self = shift;
	return length($self->get("lineage"))/6;
}

#-------------------------------------------------------------------

=head2 getLineageSql ( relatives,rules )

Returns the sql statment for lineage based on relatives and rules passed in

=head3 relatives

An array reference of relatives to retrieve. Valid parameters are "siblings", "children", "ancestors", "self", "descendants", "pedigree".  If you want to retrieve all assets in the tree, use getRoot($session)->getLineage(["self","descendants"],{returnObjects=>1});

=head3 rules

A hash reference comprising modifiers to relative listing. Rules include:

=head4 statesToInclude

An array reference containing a list of states that should be returned. Defaults to 'published'. Options include
'published', 'trash', 'clipboard', 'clipboard-limbo' and 'trash-limbo'.

=head4 statusToInclude

An array reference containing a list of status that should be returned. Defaults to 'approved'. Options include 'approved', 'pending', and 'archived'.

=head4 endingLineageLength

An integer limiting the length of the lineages of the assets to be returned. This can help limit levels of depth in the asset tree.

=head4 assetToPedigree

An asset object reference to draw a pedigree from. A pedigree includes ancestors, siblings, descendants and other information. It's specifically used in flexing navigations.

=head4 ancestorLimit

An integer describing how many levels of ancestry from the start point that should be retrieved.

=head4 excludeClasses

An array reference containing a list of asset classes to remove from the result set. The opposite of the includOnlyClasses rule.

=head4 invertTree

A boolean indicating whether the resulting asset tree should be returned in reverse order.

=head4 includeOnlyClasses

An array reference containing a list of asset classes to include in the result. If this is specified then no other classes except these will be returned. The opposite of the excludeClasses rule.

=head4 isa

A classname where you can look for classes of a similar base class. For example, if you're looking for Donations, Subscriptions, Products and other subclasses of WebGUI::Asset::Sku, then set isa to 'WebGUI::Asset::Sku'.

=head4 includeArchived

A boolean indicating that we should include archived assets in the result set.

=head4 joinClass

A string containing as asset class to join in. There is no real reason to use a joinClass without a whereClause, but it's trivial to use a whereClause if you don't use a joinClass.  You will only be able to filter on the asset table, however.

=head4 whereClause

A string containing extra where clause information for the query.

=head4 orderByClause 

A string containing an order by clause (without the "order by"). If specified,
will override the "invertTree" option.

=head4 limit

The maximum amount of entries to return

=cut

sub getLineageSql {
	my $self = shift;
	my $relatives = shift;
	my $rules = shift;
	my $lineage = $self->get("lineage");
	my @whereModifiers;
	# let's get those siblings
	if (isIn("siblings",@{$relatives})) {
		push(@whereModifiers, " (asset.parentId=".$self->session->db->quote($self->get("parentId"))." and asset.assetId<>".$self->session->db->quote($self->getId).")");
	}
	# ancestors too
	my @specificFamilyMembers = ();
	if (isIn("ancestors",@{$relatives})) {
		my $i = 1;
		my @familyTree = ($lineage =~ /(.{6})/g);
                while (pop(@familyTree)) {
                        push(@specificFamilyMembers,join("",@familyTree)) if (scalar(@familyTree));
			last if ($i >= $rules->{ancestorLimit} && exists $rules->{ancestorLimit});
			$i++;
                }
	}
	# let's add ourself to the list
	if (isIn("self",@{$relatives})) {
		push(@specificFamilyMembers,$self->get("lineage"));
	}
	if (scalar(@specificFamilyMembers) > 0) {
		push(@whereModifiers,"(asset.lineage in (".$self->session->db->quoteAndJoin(\@specificFamilyMembers)."))");
	}
	# we need to include descendants
	if (isIn("descendants",@{$relatives})) {
		my $mod = "(asset.lineage like ".$self->session->db->quote($lineage.'%')." and asset.lineage<>".$self->session->db->quote($lineage); 
		if (exists $rules->{endingLineageLength}) {
			$mod .= " and length(asset.lineage) <= ".($rules->{endingLineageLength}*6);
		}
		$mod .= ")";
		push(@whereModifiers,$mod);
	}
	# we need to include children
	if (isIn("children",@{$relatives})) {
		push(@whereModifiers,"(asset.parentId=".$self->session->db->quote($self->getId).")");
	}
	# now lets add in all of the siblings in every level between ourself and the asset we wish to pedigree
	if (isIn("pedigree",@{$relatives}) && exists $rules->{assetToPedigree}) {
        my $pedigreeLineage = $rules->{assetToPedigree}->get("lineage");
        if (substr($pedigreeLineage,0,length($lineage)) eq $lineage) {
            my @mods;
		    my $length = $rules->{assetToPedigree}->getLineageLength;
            for (my $i = $length; $i > 0; $i--) {
			    my $line = substr($pedigreeLineage,0,$i*6);
			    push(@mods,"( asset.lineage like ".$self->session->db->quote($line.'%')." and  length(asset.lineage)=".(($i+1)*6).")");
			    last if ($self->getLineageLength == $i);
		    }
		    push(@whereModifiers, "(".join(" or ",@mods).")") if (scalar(@mods));
	    }
    }
	# deal with custom joined tables if we must
	my $tables = "asset left join assetData on asset.assetId=assetData.assetId ";
	if (exists $rules->{joinClass}) {
		my $className = $rules->{joinClass};
        (my $module = $className . '.pm') =~ s{::|'}{/}g;
        if ( ! eval { require $module; 1 }) {
            $self->session->errorHandler->fatal("Couldn't compile asset package: ".$className.". Root cause: ".$@) if ($@);
        }
		foreach my $definition (@{$className->definition($self->session)}) {
            unless ($definition->{tableName} eq "asset" || $definition->{tableName} eq "assetData") {
				my $tableName = $definition->{tableName};
				$tables .= " left join $tableName on assetData.assetId=".$tableName.".assetId and assetData.revisionDate=".$tableName.".revisionDate";
			}
		}
	}
	# formulate a where clause
	my $where;
	## custom states
	if (exists $rules->{statesToInclude}) {
		$where = "asset.state in (".$self->session->db->quoteAndJoin($rules->{statesToInclude}).")";
	} else {
		$where = "asset.state='published'";
	}
	
    my $statusCodes = $rules->{statusToInclude} || [];
    if($rules->{includeArchived}) {
	        push(@{$statusCodes},'archived') if(!WebGUI::Utility::isIn('archived',@{$statusCodes}));
          	push(@{$statusCodes},'approved') if(!WebGUI::Utility::isIn('approved',@{$statusCodes}));
    }
    
    my $status = "assetData.status='approved'";
    if(scalar(@{$statusCodes})) {
       $status = "assetData.status in (".$self->session->db->quoteAndJoin($statusCodes).")";
    }
    
	$where .= " and ($status or assetData.tagId=".$self->session->db->quote($self->session->scratch->get("versionTag")).")";
	## class exclusions
	if (exists $rules->{excludeClasses}) {
		my @set;
		foreach my $className (@{$rules->{excludeClasses}}) {
			push(@set,"asset.className not like ".$self->session->db->quote($className.'%'));
		}
		$where .= ' and ('.join(" and ",@set).')';
	}
	## class inclusions
	if (exists $rules->{includeOnlyClasses}) {
		$where .= ' and (asset.className in ('.$self->session->db->quoteAndJoin($rules->{includeOnlyClasses}).'))';
	}
	## isa
	if (exists $rules->{isa}) {
		$where .= ' and (asset.className like '.$self->session->db->quote($rules->{isa}.'%').')';
	}
	## finish up our where clause
	if (!scalar(@whereModifiers)) {
        return "";
    }
	$where .= ' and ('.join(" or ",@whereModifiers).')';
	if (exists $rules->{whereClause} && $rules->{whereClause}) {
		$where .= ' and ('.$rules->{whereClause}.')';
	}
	# based upon all available criteria, let's get some assets
	my $columns = "asset.assetId, asset.className, asset.parentId, assetData.revisionDate";
	$where .= " and assetData.revisionDate=(SELECT max(revisionDate) from assetData where assetData.assetId=asset.assetId and ($status or assetData.tagId=".$self->session->db->quote($self->session->scratch->get("versionTag")).")) ";
	my $sortOrder = ($rules->{invertTree}) ? "asset.lineage desc" : "asset.lineage asc"; 
	if (exists $rules->{orderByClause}) {
		$sortOrder = $rules->{orderByClause};
	}
	my $sql = "select $columns from $tables where $where group by assetData.assetId order by $sortOrder";
	
	# Add limit if necessary
	if ($rules->{limit}) {
		$sql	.= " limit ".$rules->{limit};
	}

    return $sql;
	
}


#-------------------------------------------------------------------

=head2 getNextChildRank ( )

Returns a 6 digit number with leading zeros of the next rank a child will get.

=cut

sub getNextChildRank {
	my $self = shift;	
	my ($lineage) = $self->session->db->quickArray("select max(lineage) from asset where parentId=?",[$self->getId]);
	my $rank;
	if (defined $lineage) {
		$rank = $self->getRank($lineage);
		$self->session->errorHandler->fatal("Asset ".$self->getId." has too many children.") if ($rank >= 999998);
		$rank++;
	} else {
		$rank = 1;
	}
	return $self->formatRank($rank);
}


#-------------------------------------------------------------------

=head2 getParent ( )

Returns an asset hash of the parent of current Asset.

=cut

sub getParent {
    my $self        = shift;
    
    # Root asset is its own parent
    return $self if ($self->getId eq "PBasset000000000000001");

    unless ( $self->{_parent} ) {
        $self->{_parent} = WebGUI::Asset->newByDynamicClass($self->session,$self->get("parentId"));
    }

    return $self->{_parent};
}

#-------------------------------------------------------------------

=head2 getParentLineage ( [lineage] )

Returns the Lineage of parent of Asset.

=head3 lineage

Optional lineage of another Asset.

=cut

sub getParentLineage {
	my $self = shift;
	my $lineage = shift || $self->get("lineage");
    my $lineageLength = length($lineage) - 6;
    return $lineage unless $lineageLength;
	my $parentLineage = substr($lineage, 0, $lineageLength);
	return $parentLineage;
}

#-------------------------------------------------------------------

=head2 getRank ( [lineage] )

Returns the rank of current Asset by returning the last six digit-entry of a lineage without leading zeros (may return less than 6 digits).

=head3 lineage

Optional specified lineage. 

=cut

sub getRank {
	my $self = shift;
	my $lineage = shift || $self->get("lineage");
	$lineage =~ m/(.{6})$/;
	my $rank = $1 - 0; # gets rid of preceeding 0s.
	return $rank;
}


#-------------------------------------------------------------------

=head2 hasChildren ( )

Returns 1 or the count of Assets with the same parentId as current Asset's assetId (Which may be zero).

=cut

sub hasChildren {
	my $self = shift;
	unless (exists $self->{_hasChildren}) {
		if (exists $self->{_firstChild}) {
			$self->{_hasChildren} = 1;
		} elsif (exists $self->{_lastChild}) {
			$self->{_hasChildren} = 1;
		} else {
			$self->{_hasChildren} = $self->getChildCount;
		}
	}
	return $self->{_hasChildren};
}


#-------------------------------------------------------------------

=head2 newByLineage ( session, lineage )

Constructor. Returns an Asset object based upon given lineage.

=head3 session

A reference to the current session.

=head3 lineage

Lineage string.

=cut

sub newByLineage {
	my $class = shift;
	my $session = shift;
    my $lineage = shift;
	my $assetLineage = $session->stow->get("assetLineage");
	my $id = $assetLineage->{$lineage}{id};
	$class = $assetLineage->{$lineage}{class};
    unless ($id && $class) {
        ($id,$class) = $session->db->quickArray("select assetId, className from asset where lineage=?",[$lineage]);
        $assetLineage->{$lineage}{id} = $id;
        $assetLineage->{$lineage}{class} = $class;
        $session->stow->set("assetLineage",$assetLineage);
	}
	return WebGUI::Asset->new($session, $id, $class);
}


#-------------------------------------------------------------------

=head2 promote ( )

Keeps the same rank of lineage, swaps with sister above. Returns 1 if there is a sister to swap. Otherwise returns 0.

This will update the lineage of $self, but not the sister.

=cut

sub promote {
	my $self = shift;
	my ($sisterLineage) = $self->session->db->quickArray("select max(lineage) from asset 
		where parentId=? and state='published' and lineage<?",[$self->get("parentId"), $self->get("lineage")]);
	if (defined $sisterLineage) {
		$self->swapRank($sisterLineage);
		$self->{_properties}{lineage} = $sisterLineage;
		return 1;
	}
	return 0;
}


#-------------------------------------------------------------------

=head2 setParent ( newParent )

Moves an asset to a new Parent and returns 1 if successful, otherwise returns 0.

=head3 newParent

An asset object reference representing the new parent to paste the asset to.

=cut

sub setParent {
	my $self = shift;
	my $newParent = shift;
	return 0 unless (defined $newParent); # can't move it if a parent object doesn't exist
	return 0 if ($newParent->getId eq $self->get("parentId")); # don't move it to where it already is
	return 0 if ($newParent->getId eq $self->getId); # don't move it to itself
    my $oldLineage = $self->get("lineage");
    my $lineage = $newParent->get("lineage").$newParent->getNextChildRank; 
    return 0 if ($lineage =~ m/^$oldLineage/); # can't move it to its own child
    $self->session->db->beginTransaction;
    $self->session->db->write("update asset set parentId=? where assetId=?",
        [$newParent->getId, $self->getId]);
    $self->cascadeLineage($lineage);
    $self->session->db->commit;
    $self->updateHistory("moved to parent ".$newParent->getId);
    $self->{_properties}{lineage}  = $lineage;
    $self->{_properties}{parentId} = $newParent->getId;
    $self->purgeCache;
    $self->{_parent} = $newParent;
    return 1;
}

#-------------------------------------------------------------------

=head2 setRank ( newRank )

Returns 1. Changes rank of Asset.

=head3 newRank

Value of new Rank.

=cut

sub setRank {
	my $self = shift;
	my $newRank = shift;
	my $currentRank = $self->getRank;
	return 1 if ($newRank == $currentRank); # do nothing if we're moving to ourself
	my $parentLineage = $self->getParentLineage;

    my $reverse = ($newRank < $currentRank) ? 1 : 0;
	my $siblings = $self->getLineage(["siblings"],{returnObjects=>1, invertTree=>$reverse});

	my $temp = substr($self->session->id->generate(),0,6);
	my $previous = $self->get("lineage");
	$self->session->db->beginTransaction;
	$self->cascadeLineage($temp);
	foreach my $sibling (@{$siblings}) {
		if (isBetween($sibling->getRank, $newRank, $currentRank)) {
			$sibling->cascadeLineage($previous);
			$previous = $sibling->get("lineage");
		}
	}
	$self->cascadeLineage($previous,$temp);
	$self->{_properties}{lineage} = $previous;
	$self->session->db->commit;
	$self->purgeCache;
	$self->updateHistory("changed rank");
	return 1;
}

#-------------------------------------------------------------------

=head2 swapRank ( second [,first] )

Returns 1. Swaps current rank with second rank. 

=head3 first

If specified, swaps second rank with first rank.  The change only occurs in the db,
no in the objects.

=cut

sub swapRank {
	my $self = shift;
	my $second = shift;
	my $first = shift || $self->get("lineage");
	my $temp = substr($self->session->id->generate(),0,6); # need a temp in order to do the swap
	$self->session->db->beginTransaction;
	$self->cascadeLineage($temp,$first);
	$self->cascadeLineage($first,$second);
	$self->cascadeLineage($second,$temp);
	$self->session->db->commit;
	$self->updateHistory("swapped lineage between ".$first." and ".$second);
	return 1;
}


#-------------------------------------------------------------------

=head2 www_demote ( )

Demotes self and returns www_view method of getContainer of self if canEdit, otherwise renders an AdminConsole as insufficient privilege.

=cut

sub www_demote {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	$self->demote;
	return $self->session->asset($self->getContainer)->www_view; 
}


#-------------------------------------------------------------------

=head2 www_promote ( )

Returns www_view method of getContainer of self. Promotes self. If canEdit is False, returns an insufficient privileges page.

=cut

sub www_promote {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	$self->promote;
	return $self->session->asset($self->getContainer)->www_view;
}


#-------------------------------------------------------------------

=head2 www_setParent ( )

Returns a www_manageAssets() method. Sets a new parent via the results of a form. If canEdit is False, returns an insufficient privileges page.

=cut

sub www_setParent {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	my $newParent = WebGUI::Asset->newByDynamicClass($self->session->form->process("assetId"));
	if (defined $newParent) {
		my $success = $self->setParent($newParent);
		return $self->session->privilege->insufficient() unless $success;
	}
	return $self->www_manageAssets();

}

#-------------------------------------------------------------------

=head2 www_setRank ( )

Returns a www_manageAssets() method. Sets a new rank via the results of a form. If canEdit is False, returns an insufficient privileges page.

=cut

sub www_setRank {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	my $newRank = $self->session->form->process("rank");
	$self->setRank($newRank) if (defined $newRank);
	$self->session->asset($self->getParent);
	return $self->getParent->www_manageAssets();
}


1;

