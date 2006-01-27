package WebGUI::Search;

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

use strict;
use WebGUI::Asset;
use WebGUI::SQL;

=head1 NAME

Package WebGUI::Search

=head1 DESCRIPTION

A package for creating queries with the WebGUI Search Engine.

=head1 SYNOPSIS

 use WebGUI::Search;

=head1 METHODS

These methods are available from this package:

=cut


#-------------------------------------------------------------------

=head2 getAssetIds ( )

Returns an array reference containing all the asset ids of the assets that matched.

=cut

sub getAssetIds {
	my $self = shift;
	my $query = "select assetId ";
	$query .= " , ".$self->{_score} if ($self->{_score});
	$query .= " from assetIndex where ";
	$query .= "isPublic=1 and " if ($self->{_isPublic});
	$query .= "(".$self->{_where}.")";
	$query .= " order by score " if ($self->{_score});
	my $rs = $self->session->db->prepare($query);
	$rs->execute($self->{_params});
	my @ids = ();
	while (my ($id) = $rs->array) {
		push(@ids, $id);		
	}
	return \@ids;
}


#-------------------------------------------------------------------

=head2 getAsses ( )

Returns an array reference containing asset objects for those that matched.

=cut

sub getAssets {
	my $self = shift;
	my $query = "select assetId,className,revisionDate ";
	$query .= " , ".$self->{_score} if ($self->{_score});
	$query .= " from assetIndex where ";
	$query .= "isPublic=1 and " if ($self->{_isPublic});
	$query .= "(".$self->{_where}.")";
	$query .= " order by score " if ($self->{_score});
	my $rs = $self->session->db->prepare($query);
	$rs->execute($self->{_params});
	my @assets = ();
	while (my ($id, $class, $version) = $rs->array) {
		my $asset = WebGUI::Asset->new($self->session, $id, $class, $version);
		push(@assets, $asset);		
	}
	return \@assets;
}


#-------------------------------------------------------------------

=head2 getPaginatorResultSet ( )

Returns a paginator object containing the search result set data.

=head3 currentURL

The URL of the current page including attributes. The page number will be appended to this in all links generated by the paginator.

=head3 paginateAfter

The number of rows to display per page. If left blank it defaults to 50.

=head3 pageNumber 

By default the page number will be determined by looking at $self->session->form->process("pn"). If that is empty the page number will be defaulted to "1". If you'd like to override the page number specify it here.

=head3 formVar

Specify the form variable the paginator should use in it's links.  Defaults to "pn".

=cut

sub getPaginatorResultSet {
	my $self = shift;
	my $url = shift;
	my $paginate = shift;
	my $pageNumber = shift;
	my $formVar = shift;
	my $query = "select assetId, title, url, synopsis, ownerUserId, groupIdView, groupIdEdit, creationDate, revisionDate,  className ";
	$query .= " , ".$self->{_score} if ($self->{_score});
	$query .= " from assetIndex where ";
	$query .= "isPublic=1 and " if ($self->{_isPublic});
	$query .= "(".$self->{_where}.")";
	$query .= " order by score " if ($self->{_score});
	my $paginator = WebGUI::Paginator->new($self->session, $url, $paginate, $pageNumber, $formVar);
	$paginator->setDataByQuery($query, undef, undef, $self->{_params});
	return $paginator;
}

#-------------------------------------------------------------------

=head2 getResultSet ( ) 

Returns a WebGUI::SQL::ResultSet object containing the search results with columns labeled "assetId", "title", "url", "synopsis", "ownerUserId", "groupIdView", "groupIdEdit", "creationDate", "revisionDate", and "className".

=cut

sub getResultSet {
	my $self = shift;
	my $query = "select assetId, title, url, synopsis, ownerUserId, groupIdView, groupIdEdit, creationDate, revisionDate,  className ";
	$query .= " , ".$self->{_score} if ($self->{_score});
	$query .= " from assetIndex where ";
	$query .= "isPublic=1 and " if ($self->{_isPublic});
	$query .= "(".$self->{_where}.")";
	$query .= " order by score " if ($self->{_score});
	my $rs = $self->session->db->prepare($query);
	$rs->execute($self->{_params});
	return $rs;
}



#-------------------------------------------------------------------

=head2 new ( session  [ , isPublic ] )

Constructor.

=head3 session

A reference to the current session.

=head3 isPublic

A boolean indicating whether this search should search all internal data (0), or just public data (1). Defaults to just public data (1).

=cut

sub new {
	my $class = shift;
	my $session = shift;
	my $isPublic = (shift eq "0") ? 0 : 1;
	bless {_session=>$session, _isPublic=>$isPublic}, $class;
}



#-------------------------------------------------------------------

=head2 rawClause ( sql [, placeholders ] ) 

Tells the search engine to use a custom sql where clause that you've designed for the assetIndex table instead of using the API to build it. It also returns a reference to the object so you can join a result method with it like this:

 my $assetIds = WebGUI::Search->new($session)->rawQuery($sql, $params)->getAssetIds;

=head3 sql

The where clause to execute. It should not actually contain the "where" term itself. 

=head3 placeholders

A list of placeholder parameters to go along with the query. See WebGUI::SQL::ResultSet::execute() for details.

=cut

sub rawClause {
	my $self = shift;
	$self->{_where} = shift;
	$self->{_params} = shift;
	return $self;
}

#-------------------------------------------------------------------

=head2 search ( rules ) 

A rules engine for WebGUI's search system. It also returns a reference to the search object so that you can join a result method with it like:

 my $assetIds = WebGUI::Search->new($session)->search(\%rules)->getAssetIds;

=head3 rules

A hash reference containing rules for a search. The rules will will be hash references containing the values of a rule. Here's an example rule set:

 { keywords => "something to search for", lineage => [ "000001000005", "000001000074000003" ] };

=head4 keywords

This rule limits the search results to assets that match keyword criteria.

 keywords => "foo bar"

=head4 lineage

This rule limits the search to a specific set of descendants in the asset tree. An array reference of asset lineages to match against.

 lineage => [ "000001000003", "000001000024000005" ]

=head4 classes

This rule limits the search to a specific set of asset classes. An array reference of class names.

 classes => [ "WebGUI::Asset::Wobject::Article", "WebGUI::Asset::Snippet" ]

=head4 creationDate

This rule limits the search to a creation date range. It has two parameters: "start" and "end". Start and end represent the start and end dates to search in, which are represented as epoch dates. If start is not specified, it is infinity into the past. If end date is not specified, it is infinity into the future.

 creationDate => {
       start=>1110011,
       end=>30300003
    }

=head4 revisionDate

This rule limits the search to a revision date range. It has two parameters: "start" and "end". Start and end represent the start and end dates to search in, which are represented as epoch dates. If start is not specified, it is infinity into the past. If end date is not specified, it is infinity into the future.

 revisionDate => {
       start=>1110011,
       end=>30300003
    }

=cut

sub search {
	my $self = shift;
	my $rules = shift;
	my @params = ();
	my $query = "";
	my @clauses = ();
	if ($rules->{keywords}) {
		push(@params,$rules->{keywords},$rules->{keywords});
		$self->{_score} = "match (keywords) against (? in boolean mode) as score";
		push(@clauses, "match (keywords) against (? in boolean mode)");
	}
	if ($rules->{lineage}) {
		my @phrases = ();
		foreach my $lineage (@{$rules->{lineage}}) {
			next unless defined $lineage;
			push(@params, $lineage."%");
			push(@phrases, "lineage like ?");
		}
		push(@clauses, join(" or ", @phrases)) if (scalar(@phrases));
	}
	if ($rules->{classes}) {
		my @phrases = ();
		foreach my $class (@{$rules->{classes}}) {
			next unless defined $class;
			push(@params, $class);
			push(@phrases, "className=?");
		}
		push(@clauses, join(" or ", @phrases)) if (scalar(@phrases));
	}
	if ($rules->{creationDate}) {
		my $start = $rules->{creationDate}{start} || 0;
		my $end = $rules->{creationDate}{end} || 9999999999999999999999;
		push(@clauses, "creationDate between ? and ?");
		push(@params, $start, $end);
	}
	if ($rules->{revisionDate}) {
		my $start = $rules->{revisionDate}{start} || 0;
		my $end = $rules->{revisionDate}{end} || 9999999999999999999999;
		push(@clauses, "revisionDate between ? and ?");
		push(@params, $start, $end);
	}
	$self->{_params} = \@params;
	$self->{_where} = "(".join(") and (", @clauses).")";
	return $self;
}


#-------------------------------------------------------------------

=head2 session ( ) 

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}



1;

