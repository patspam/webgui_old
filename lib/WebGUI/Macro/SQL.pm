package WebGUI::Macro::SQL;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2007 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;

=head1 NAME

Package WebGUI::Macro::SQL

=head1 DESCRIPTION

Macro for executing SQL select-type statements and returning formatted output.

=head2 process ( SQL, format )

=head3 SQL

The SQL statement to execute.  If the statement is not something that
returns data (select, show, describe), an error message is returned.  If
there is an error executing the SQL, an error message will be returned.

=head3 format

Describes how to format the results of the SQL statement.  For each
term in in a select-type statement, a numeric macro (^0, ^1, etc.)can
be used to position its output in the format.

=cut

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my ($output, @data, $rownum, $temp);
	my ($statement, $format) = @_;
	my $i18n = WebGUI::International->new($session,'Macro_SQL');
	$format = '^0;' if ($format eq "");
	if ($statement =~ /^\s*select/i || $statement =~ /^\s*show/i || $statement =~ /^\s*describe/i) {
		my $sth = $session->dbSlave->unconditionalRead($statement);
		unless ($sth->errorCode < 1) { 
			return sprintf $i18n->get('sql error'), $sth->errorMessage;
		} else {
			while (@data = $sth->array) {
                		$temp = $format; 
	                        $temp =~ s/\^(\d+)\;/$data[$1]/g; 
        	                $rownum++;
                	        $temp =~ s/\^rownum\;/$rownum/g;
				$output .= $temp;
	                }
			$sth->finish;
			return $output;
		}
	} else {
		return $i18n->get('illegal query');
	}
}


1;

