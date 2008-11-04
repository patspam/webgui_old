package WebGUI::SQL;

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

use DBI;
use strict;
use Tie::IxHash;
use WebGUI::SQL::ResultSet;
use WebGUI::Utility;
use Text::CSV_XS;

=head1 NAME

Package WebGUI::SQL

=head1 DESCRIPTION

Package for interfacing with SQL databases. This package implements Perl DBI functionality in a less code-intensive manner and adds some extra functionality.

=head1 SYNOPSIS

 use WebGUI::SQL;

 $db = WebGUI::SQL->connect($session,$dsn, $user, $pass);
 $db->disconnect;
 
 $sth = $db->prepare($sql);
 $sth = $db->read($sql);
 $sth = $db->unconditionalRead($sql);

 $db->write($sql);

 $db->beginTransaction;
 $db->commit;
 $db->rollback;

 @arr      = $db->buildArray($sql);
 $arrayRef = $db->buildArrayRef($sql);
 %hash     = $db->buildHash($sql);
 $hashRef  = $db->buildHashRef($sql);
 @arr      = $db->quickArray($sql);
 $scalar   = $db->quickScalar($sql);
 $text     = $db->quickCSV($sql);
 %hash     = $db->quickHash($sql);
 $hashRef  = $db->quickHashRef($sql);
 $text     = $db->quickTab($sql);

 $id     = $db->getNextId("someId");
 $string = $db->quote($string);
 $string = $db->quoteAndJoin(\@array);

=head1 METHODS

These methods are available from this package:

=cut


#-------------------------------------------------------------------

=head2 beginTransaction ( )

Starts a transaction sequence. To be used with commit and rollback. Any writes after this point will not be applied to the database until commit is called.

=cut

sub beginTransaction {
	my $self = shift;
	$self->dbh->begin_work;
}


#-------------------------------------------------------------------

=head2 buildArray ( sql, params )

Builds an array of data from a series of rows.

=head3 sql

An SQL query. The query must select only one column of data.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub buildArray {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, $data, @array, $i);
	$sth = $self->prepare($sql);
	$sth->execute($params);
	$i=0;
	while (($data) = $sth->array) {
		$array[$i] = $data;
		$i++;
	}
	$sth->finish;
	return @array;
}


#-------------------------------------------------------------------

=head2 buildArrayRef ( sql, params )

Builds an array reference of data from a series of rows.

=head3 sql

An SQL query. The query must select only one column of data.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub buildArrayRef {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my @array = $self->buildArray($sql,$params);
	return \@array;
}


#-------------------------------------------------------------------

=head2 buildHash ( sql, params )

Builds a hash of data from a series of rows.

=head3 sql

An SQL query. The query should select at least two columns of data, the first being the key for the hash, the second being the value. If the query selects more than two columns, then the last column will be the value and the remaining columns will be joined together by a colon ":" to form a complex key. If the query selects only one column, then the key and value will be the same.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub buildHash {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, %hash, @data);
	tie %hash, "Tie::IxHash";
	$sth = $self->prepare($sql);
	$sth->execute($params);
	while (@data = $sth->array) {
		my $value = pop @data;
		my $key = join(":",@data); # if more than two columns is selected, join them together with :
		$key = $value unless ($key); # if only one column is selected, then it is both the key and the value
		$hash{$key} = $value;
	}
	$sth->finish;
	return %hash;
}


#-------------------------------------------------------------------

=head2 buildHashRef ( sql )

Builds a hash reference of data from a series of rows.

=head3 sql

An SQL query. The query should select at least two columns of data, the first being the key for the hash, the second being the value. If the query selects more than two columns, then the last column will be the value and the remaining columns will be joined together by a colon ":" to form a complex key. If the query selects only one column, then the key and the value will be the same.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub buildHashRef {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, %hash);
	tie %hash, "Tie::IxHash";
	%hash = $self->buildHash($sql, $params);
	return \%hash;
}


#-------------------------------------------------------------------

=head2 buildArrayRefOfHashRefs ( sql )

Builds an array reference of hash references of data 
from a series of rows.  Useful for returning many rows at once.

=head3 sql

An SQL query. The query must select at least two columns of data, the first being the key for the hash, the second being the value. If the query selects more than two columns, then the last column will be the value and the remaining columns will be joined together by a colon ":" to form a complex key. If the query selects only one column, then the key and the value will be the same.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub buildArrayRefOfHashRefs {
	my @array;
	my $class = shift;
	my $sql = shift;
	my $params = shift;
	my $sth = $class->read($sql,$params);
	while (my $data = $sth->hashRef) {
		push(@array,$data);
	}
	$sth->finish;
	return \@array;
}


#-------------------------------------------------------------------

=head2 buildDataTableStructure ( sql, params )

Builds a data structure that can be converted to JSON and sent
to a YUI Data Table.  This is basically a hash of information about
the results, with one of the keys being an array ref of hashrefs.  It also
calculates the total records that could have been matched without a limit
statement, as well as how many were actually matched.  It returns a hash.

=head3 sql

An SQL query. The query may select as many columns of data as you wish.  The query
should contain a SQL_CALC_ROWS_FOUND entry so that the total number of available
rows can be sent to the Data Table.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub buildDataTableStructure {
    my $self = shift;
    my $sql = shift;
    my $params = shift;
    my %hash;
    my @array;
    ##Note, I need a valid statement handle for doing the rows method on.
	my $sth = $self->read($sql,$params);
	while (my $data = $sth->hashRef) {
		push(@array,$data);
	}
    $hash{records}         = \@array;
    $hash{totalRecords}    = $self->quickScalar('select found_rows()') + 0; ##Convert to numeric
    $hash{recordsReturned} = $sth->rows()+0;
	$sth->finish;
	return %hash;
}

#-------------------------------------------------------------------

=head2 buildHashRefOfHashRefs ( sql, params, key )

Builds a hash reference of hash references of data 
from a series of rows.  Useful for returning many rows at once.
Assigns the data to a hash

=head3 sql

An SQL query. The query must select at least one column of data, including the one you choose as the key for the hashRef to be returned.  Each row is returned as its own hashRef as the value of its corresponding key, keyed by the key column, below.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=head3 key

Which column of the result set to use as the key when creating the hashref.

=cut

sub buildHashRefOfHashRefs {
	my %hash;
	my $class = shift;
	my $sql = shift;
	my $params = shift;
	my $key = shift;
	my $sth = $class->read($sql,$params);
	my $data;
	tie %hash, "Tie::IxHash";
	while ($data = $sth->hashRef) {
		$hash{$data->{$key}} = $data;
	}
	$sth->finish;
	return \%hash;
}

                                                                              
#-------------------------------------------------------------------

=head2 buildSearchQuery ( $sql, $placeholders, $keywords, $columns )

Append information to an existing SQL statement for implementing
basic search functions.  The ammended SQL and an array of placeholder
variables will be returned.

=head3 $sql

A scalar reference to an SQL query.  The clauses to add search-like capabilities will be
appended to the end of the query.

=head3 $placeholders

An array reference of placeholders already added to the query.

=head3 $keywords

This is the data that will be searched for in columns.  An SQL wildcard '%' will
be added to the beginning and end of $keywords.

=head3 $columns

An arrayref of column names that should be searched for $keywords.

=cut

sub buildSearchQuery {
    my ($self, $sql, $placeHolders, $keywords, $columns) = @_;
    if ($$sql =~ m/where/) {
        $$sql .= ' and (';
    }
    else { 
        $$sql .= ' where (';
    }
    $keywords = lc('%'.$keywords.'%');
    my $counter = 0;
    foreach my $field (@{ $columns }) {
        $$sql .= ' or' if ($counter > 0);
        $$sql .= qq{ LOWER( $field ) like ?};
        push(@{$placeHolders}, $keywords);
        $counter++;
    }
    $$sql .= ')';
}

#-------------------------------------------------------------------

=head2 commit ( )

Ends a transaction sequence. To be used with beginTransaction. Applies all of the writes since beginTransaction to the database.

=cut

sub commit {
	my $self = shift;
	$self->dbh->commit;
}


#-------------------------------------------------------------------

=head2 connect ( session, dsn, user, pass )

Constructor. Connects to the database using DBI.

=head2 session

A reference to the active WebGUI::Session object.

=head2 dsn

The Database Service Name of the database  you wish to connect to. It looks like 'DBI:mysql:dbname;host=localhost'.

=head2 user

The username to use to connect to the database defined by dsn.

=head2 pass

The password to use to connect to the database defined by dsn.

=cut

sub connect {
	my $class   = shift;
	my $session = shift;
	my $dsn     = shift;
	my $user    = shift;
	my $pass    = shift;
    my $params  = shift;

    my (undef, $driver) = DBI->parse_dsn($dsn);
    my $dbh = DBI->connect($dsn,$user,$pass,{RaiseError => 0, AutoCommit => 1,
        $driver eq 'mysql' ? (mysql_enable_utf8 => 1) : (),
    });

	unless (defined $dbh) {
		$session->errorHandler->error("Couldn't connect to database: $dsn : $DBI::errstr");
		return undef;
	}

    ##Set specific attributes for this database.
    my @params = split /\s*\n\s*/, $params;
    foreach my $param ( @params ) {
        my ($paramName, $paramValue) = split /\s*=\s*/, $param;
        $dbh->{$paramName} = $paramValue;
    }

	bless {_dbh=>$dbh, _session=>$session}, $class;
}

#-------------------------------------------------------------------

=head2 dbh ( )

Returns a reference to the working DBI database handler for this WebGUI::SQL object.

=cut

sub dbh {
	my $self = shift;
	return $self->{_dbh};
}


#-------------------------------------------------------------------

=head2 deleteRow ( table, key, keyValue )

Deletes a row of data from the specified table.

=head3 table

The name of the table to delete the row of data from.

=head3 key

The name of the column to use as the key. Should be a primary or unique key in the table.

=head3 keyValue

The value to search for in the key column.

=cut

sub deleteRow {
	my ($self, $table, $key, $keyValue) = @_;
	my $sth = $self->write("delete from $table where ".$key."=?", [$keyValue]);
}


#-------------------------------------------------------------------

=head2 DESTROY ( )

Deconstructor.

=cut

sub DESTROY {
	my $self = shift;
	$self->disconnect;
	undef $self;
}


#-------------------------------------------------------------------

=head2 disconnect ( )

Disconnects from the database. And destroys the object.

=cut

sub disconnect {
	my $self = shift;
	$self->dbh->disconnect;
	undef $self;
}


#-------------------------------------------------------------------

=head2 errorCode ( )

Returns an error code for the current handler.

=cut

sub errorCode {
	my $self = shift;
	return $self->dbh->err;
}


#-------------------------------------------------------------------

=head2 errorMessage ( )

Returns a text error message for the current handler.

=cut

sub errorMessage {
	my $self = shift;
	return $self->dbh->errstr;
}


#-------------------------------------------------------------------

=head2 getNextId ( idName )

Increments an incrementer of the specified type and returns the value. 

=head3 idName

Specify the name of one of the incrementers in the incrementer table.

=cut

sub getNextId {
	my $self = shift;
	my $name = shift;
	my ($id);
	$self->beginTransaction;
	($id) = $self->quickArray("select nextValue from incrementer where incrementerId=?", [$name]);
	$self->write("update incrementer set nextValue=nextValue+1 where incrementerId=?",[$name]);
	$self->commit;
	return $id;
}

#-------------------------------------------------------------------

=head2 getDriver ( )

Returns the DBI driver used by this database link

=cut

sub getDriver {
    my $self = shift;
    return  $self->{_dbh}->{Driver}->{Name};
}

#-------------------------------------------------------------------

=head2 getRow ( table, key, keyValue )

Returns a row of data as a hash reference from the specified table.

=head3 table

The name of the table to retrieve the row of data from.

=head3 key

The name of the column to use as the retrieve key. Should be a primary or unique key in the table.

=head3 keyValue

The value to search for in the key column.

=cut

sub getRow {
        my ($self, $table, $key, $keyValue) = @_;
        my $row = $self->quickHashRef("select * from $table where ".$key."=?",[$keyValue]);
        return $row;
}

#-------------------------------------------------------------------

=head2 prepare ( sql ) 

This is a wrapper for WebGUI::SQL::ResultSet->prepare()

=head3 sql

An SQL statement. 

=cut

sub prepare {
	my $self = shift;
	my $sql = shift;
	return WebGUI::SQL::ResultSet->prepare($sql, $self);
}


#-------------------------------------------------------------------

=head2 quickArray ( sql, params )

Executes a query and returns a single row of data as an array.

=head3 sql

An SQL query.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub quickArray {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, @data);
	$sth = $self->prepare($sql);
	$sth->execute($params);
	@data = $sth->array;
	$sth->finish;
	return @data;
}


#-------------------------------------------------------------------

=head2 quickCSV ( sql, params )

Executes a query and returns a comma delimited text blob with column headers. Returns undef on failure.

=head3 sql

An SQL query.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub quickCSV {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, $output, @data);

	my $csv = Text::CSV_XS->new({ eol => "\n" });

	$sth = $self->prepare($sql);
	$sth->execute($params);

	return undef unless $csv->combine($sth->getColumnNames);
	$output = $csv->string();

	while (@data = $sth->array) {
		return undef unless $csv->combine(@data);
		$output .= $csv->string();
	}

	$sth->finish;
	return $output;
}


#-------------------------------------------------------------------

=head2 quickHash ( sql, params )

Executes a query and returns a single row of data as a hash.

=head3 sql

An SQL query.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub quickHash {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, $data);
	$sth = $self->prepare($sql);
	$sth->execute($params);
	$data = $sth->hashRef;
	$sth->finish;
	if (defined $data) {
		return %{$data};
	} else {
		return ();
	}
}

#-------------------------------------------------------------------

=head2 quickHashRef ( sql, params )

Executes a query and returns a single row of data as a hash reference.

=head3 sql

An SQL query.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub quickHashRef {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my $sth = $self->prepare($sql);
	$sth->execute($params);
	my $data = $sth->hashRef;
	$sth->finish;
	if (defined $data) {
		return $data;
	} else {
		return {};
	}
}

#-------------------------------------------------------------------

=head2 quickScalar ( sql, params )

Executes a query and returns the first column from a single row of data as a scalar.

=head3 sql

An SQL query.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub quickScalar {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, @data);
	$sth = $self->prepare($sql);
	$sth->execute($params);
	@data = $sth->array;
	$sth->finish;
	return $data[0];
}


#-------------------------------------------------------------------

=head2 quickTab ( sql, params )

Executes a query and returns a tab delimited text blob with column headers.

=head3 sql

An SQL query.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub quickTab {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my ($sth, $output, @data);
	$sth = $self->prepare($sql);
	$sth->execute($params);
	$output = join("\t",$sth->getColumnNames)."\n";
	while (@data = $sth->array) {
		makeArrayTabSafe(\@data);
		$output .= join("\t",@data)."\n";
	}
	$sth->finish;
	return $output;
}

#-------------------------------------------------------------------

=head2 quote ( string ) 

Returns a string quoted and ready for insert into the database.  

B<NOTE:> You should use this sparingly. It is much faster and safer to use prepare/execute style queries and passing in place holder parameters. Even the convenience methods like quickArray() support the use of place holder parameters.

=head3 string

Any scalar variable that needs to be escaped to be inserted into the database.

=cut

sub quote {
	my $self = shift;
	my $value = shift;
	return $self->dbh->quote($value);
}

#-------------------------------------------------------------------

=head2 quoteAndJoin ( arrayRef ) 

Returns a comma seperated string quoted and ready for insert/select into/from the database.  This is typically used for a statement like "select * from someTable where field in (".$db->quoteAndJoin(\@strings).")".

=head3 arrayRef 

An array reference containing strings to be quoted.

=cut

sub quoteAndJoin {
	my $self = shift;
	my $arrayRef = shift;
	my @newArray;
	foreach my $value (@$arrayRef) {
 		push(@newArray,$self->quote($value));
	}
	return join(",",@newArray);
}


#-------------------------------------------------------------------

=head2 read ( sql [ , placeholders ] )

This is a convenience method for WebGUI::SQL::ResultSet->read().  It returns the statement
handler.

=head3 sql

An SQL query. Can use the "?" placeholder for maximum performance on multiple statements with the execute method.

=head3 placeholders

An array reference containing a list of values to be used in the placeholders defined in the SQL statement.

=cut

sub read {
	my $self = shift;
	my $sql = shift;
	my $placeholders = shift;
	return WebGUI::SQL::ResultSet->read($sql, $self, $placeholders);
}


#-------------------------------------------------------------------

=head2 rollback ( )

Ends a transaction sequence. To be used with beginTransaction. Cancels all of the writes since beginTransaction.

=head3 dbh

A database handler. Defaults to the WebGUI default database handler.

=cut

sub rollback {
	my $self = shift;
	$self->dbh->rollback;
}


#-------------------------------------------------------------------

=head2 session ( )

Returns a reference to the current session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}


#-------------------------------------------------------------------

=head2 setRow ( table, key, data [ ,id ] )

Inserts/updates a row of data into the database. Returns the value of the key.

=head3 table

The name of the table to use.

=head3 key

The name of the primary key of the table. 

=head3 data

A hash reference containing column names and values to be set. If the field matching the key parameter is set to "new" then a new row will be created.

=head3 id

Use this ID to create a new row. Same as setting the key value to "new" except that we'll use this passed in id instead.

=cut

sub setRow {
	my ($self, $table, $keyColumn, $data, $id) = @_;
	if ($data->{$keyColumn} eq "new" || $id) {
		$data->{$keyColumn} = $id || $self->session->id->generate();
		$self->write("replace into $table (" . $self->dbh->quote_identifier($keyColumn) . ") values (?)",[$data->{$keyColumn}]);
	}
	my @fields = ();
	my @data = ();
	foreach my $key (keys %{$data}) {
		unless ($key eq $keyColumn) {
			push(@fields, $self->dbh->quote_identifier($key).'=?');
			push(@data,$data->{$key});
		}
	}
	if ($fields[0] ne "") {
		push(@data,$data->{$keyColumn});
		$self->write("update $table set " . join(", ", @fields)
            . " where " . $self->dbh->quote_identifier($keyColumn) . "=?", \@data);
	}
	return $data->{$keyColumn};
}


#-------------------------------------------------------------------

=head2 unconditionalRead ( sql [, placeholders ] )

A convenience method that is an alias of WebGUI::SQL::ResultSet->unconditionalRead()

=head3 sql

An SQL query.

=head3 placeholders

An array reference containing a list of values to be used in the placeholders defined in the SQL statement.

=cut

sub unconditionalRead {
	my $self = shift;
	my $sql = shift;
	my $placeholders = shift;
	return WebGUI::SQL::ResultSet->unconditionalRead($sql, $self, $placeholders);
}


#-------------------------------------------------------------------

=head2 write ( sql, params )

A method specifically designed for writing to the database in an efficient manner. 

=head3 sql

An SQL insert or update.

=head3 params

An array reference containing values for any placeholder params used in the SQL query.

=cut

sub write {
	my $self = shift;
	my $sql = shift;
	my $params = shift;
	my $sth = $self->prepare($sql);
	$sth->execute($params);
}


1;

