package WebGUI::LDAPLink;

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
use Tie::CPHash;
use WebGUI::International;
use Net::LDAP;

=head1 NAME

Package WebGUI::LDAPLink

=head1 DESCRIPTION

This package contains utility methods for WebGUI's ldap link system.

=head1 SYNOPSIS

 use WebGUI::LDAPLink;
 $hashRef = WebGUI::LDAPLink->getList($self->session,);
 %ldapLink = WebGUI::LDAPLink->new($self->session,$ldapLinkId)->get;
 
 $ldapLink = WebGUI::LDAPLink->new($self->session,$ldapLinkId);
 $connection = $ldapLink->authenticate();
 $ldapLink->disconnect;

=head1 METHODS

These subroutines are available from this package:

=cut


#-------------------------------------------------------------------

=head2 bind ( )

Authenticates against the ldap server with the parameters stored in the class, returning a valid ldap connection, or 0 if a connection
cannot be established

=cut

sub bind {
	my $self = shift;
	my ($uri, $auth, $result, $error);
	
	if (defined $self->{_connection}) {
		return $self->{_connection};
	}
	
	my $ldapUrl    = $self->{_ldapLink}->{ldapUrl};
	my $connectDn  = $self->{_ldapLink}->{connectDn};
	my $identifier = $self->{_ldapLink}->{identifier};
		
	if ($ldapUrl eq "") {
		$self->{_error} = 100;
		return 0;
	} 
	
	my $ldap = $self->connectToLDAP($ldapUrl);

	return 0 unless ($ldap);
	
	$auth = $ldap->bind(dn=>$connectDn, password=>$identifier);
	if ($auth->code == 48 || $auth->code == 49) {
		$self->{_error} = 104;
    } elsif($auth->code > 0) {
		$self->{_error} = $auth->code;
    }
    
    return $ldap;
}

#-------------------------------------------------------------------

=head2 connectToLDAP ( )

Attempts to bind to an LDAP server returning the Net::LDAP object if successful

=cut

sub connectToLDAP {
	my $self    = shift;
    my $ldapUrl = shift || $self->getValue("ldapUrl");
    my $uri     = URI->new($ldapUrl);
    
    unless ($uri) {
        $self->{_error} = 105;
        return undef;
    }
    
    $self->{_uri} = $uri;
    my $ldap = Net::LDAP->new($uri->host,
        port   => $uri->port,   #Port will default to 389 or 636
        scheme => $uri->scheme
    );
    
    unless($ldap) {
        $self->{_error} = 103;
        return undef;
    }

    $self->{_connection} = $ldap;
    
    return $ldap;
}

#-------------------------------------------------------------------
sub DESTROY {
	my $self = shift;
	$self->unbind;
	undef $self;
}

#-------------------------------------------------------------------

=head2 get ( )

Returns the list of LDAP connection properties.

=cut

sub get {
	my $self = shift;
	return $self->{_ldapLink};
}

#-------------------------------------------------------------------

=head2 getErrorMessage ( [ldapErrorCode] )

Returns the error string representing the error code generated by Net::LDAP.  If no code is passed in, the most recent error stored by the class is returned

=head3 ldapErrorCode

A valid ldap error code.

=cut

sub getErrorMessage {
   my $self = shift;
   my $errorCode = shift || $self->{_error};
   return "" unless $errorCode;
   my $i18nCode = "LDAPLink_".$errorCode;
   my $i18n = WebGUI::International->new($self->session,"AuthLDAP");
   return $i18n->get($i18nCode);
}

#-------------------------------------------------------------------

=head2 getList ( session )

Returns a hash reference  containing all ldap links.  The format is: ldapLinkId => ldapLinkName. This is a class method.

=head3 session

A reference to the current session.

=cut

sub getList {
	my $class = shift;
	my $session = shift;
    my %list;
	tie %list, "Tie::IxHash";
	%list = $session->db->buildHash("select ldapLinkId, ldapLinkName from ldapLink order by ldapLinkName");
	return \%list;
}

#-------------------------------------------------------------------

=head2 getURI ( )

Returns the uri object for the ldap connection.

=cut

sub getURI {
	my $self = shift;
	return $self->{_uri};
}

#-------------------------------------------------------------------

=head2 getValue ( property )

Returns the value of the property passed in.

=cut

sub getValue {
	my $self = shift;
    my $prop = shift;
	return $self->get->{$prop};
}

#-------------------------------------------------------------------

=head2 unbind ( )

Disconnect cleanly from the current databaseLink.

=cut

sub unbind {
	my ($self, $value);
	$self = shift;
	$value = shift;
	if (defined $self->{_connection}) {
		$self->{_connection}->unbind;
	}
}

#-------------------------------------------------------------------

=head2 new ( session, ldapLinkId )

Constructor.

=head3 session

A reference to the current session.

=head3 ldapLinkId

The ldapLinkId of the ldapLink you're creating an object reference for. 

=cut

sub new {
	my ($ldapLinkId, $ldapLink);
	my $class = shift;
	my $session = shift;
	$ldapLinkId = shift;
	return undef unless $ldapLinkId;
	$ldapLink = $session->db->quickHashRef("select * from ldapLink where ldapLinkId=?",[$ldapLinkId]);
	bless {_session=>$session, _ldapLinkId=>$ldapLinkId, _ldapLink=>$ldapLink }, $class;
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

=head2  getProperty(dn,property)

  Returns the results of a search on the property passed in

=head3 distinguished name of property

 distinguished name of group to check users for

=head3 property

 ldap property to retrieve from distinguished name

=cut

sub getProperty {
	my $self = shift;
	my $ldap = $self->bind;
	my $dn = shift;
	my $property = shift;
	return [] unless($ldap && $dn && $property);
	my $results = [];
	my $msg = $ldap->search( 
			base   => $dn,
			scope  => 'sub',
			filter => "&(objectClass=*)"
			);
	if (!$msg->code && $msg->count > 0) {
		my $entry = $msg->entry(($msg->count)-1);
		$results = $entry->get_value($property,asref => 1);
	}
	return $results;
}

#-------------------------------------------------------------------

=head2  recurseProperty(base,array,property,alternateKey)

  Returns the whether or not the user is in a particular group

=cut

sub recurseProperty {
	my $self = shift;
	my $ldap = $self->bind;
	my $base = $_[0];
	my $array = $_[1] || [];
	my $property = $_[2];
	my $recProperty = $_[3] || $property;
	my $count = $_[4] || 0;
	my $recurseFilter = $_[5] || $self->get->{ldapGlobalRecursiveFilter};
	my $rfAlreadyTransformed = $_[6];
	return undef unless($ldap && $base && $property);

	if (length $recurseFilter and not $rfAlreadyTransformed) {
		$recurseFilter =~ tr/\r//d;
		$recurseFilter =~ s/\A\n*//; $recurseFilter =~ s/\n*\z//;
		$recurseFilter = (join '|', map{quotemeta} grep{/\S/} split /\n/, $recurseFilter);
		$recurseFilter = length($recurseFilter)? qr/(?i:$recurseFilter)/ : undef;
	}

	#Prevent infinite recursion
	$count++;
	return undef if $count == 99;

	#search the base
	my $msg = $ldap->search( 
			base   => $base,
			scope  => 'sub',
			filter => "&(objectClass=*)"
			);
	#return undef if nothing found
	return undef if($msg->code || $msg->count == 0);
	#loop through the results
	for (my $i = 0; $i < $msg->count; $i++) {
		my $entry = $msg->entry($i);
		#push all the values stored in the property on to the array stack
		my $properties = $entry->get_value($property,asref => 1);
		$properties = [] unless ref $properties eq "ARRAY";
		push(@{$array},@{$properties});
		#Loop through the recursive keys
		if ($property ne $recProperty) {
			$properties = $entry->get_value($recProperty,asref => 1);
		}
		foreach my $prop (@{$properties}) {
			next if $recurseFilter and $prop =~ m/$recurseFilter/;
			$self->recurseProperty($prop,$array,$property,$recProperty,$count,$recurseFilter,1);
		}
	}
}

1;
