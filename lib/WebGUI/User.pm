package WebGUI::User;

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

use strict;
use WebGUI::Cache;
use WebGUI::Group;
use WebGUI::DatabaseLink;
use WebGUI::Utility;

=head1 NAME

Package WebGUI::User

=head1 DESCRIPTION

This package provides an object-oriented way of managing WebGUI users as well as getting/setting a users's profile data.

=head1 SYNOPSIS

 use WebGUI::User;
 $u = WebGUI::User->new($session,3);
 $u = WebGUI::User->new($session,"new");
 $u = WebGUI::User->newByEmail($session, $email);
 $u = WebGUI::User->newByUsername($session, $username);

 $authMethod =		$u->authMethod("WebGUI");
 $dateCreated = 	$u->dateCreated;
 $karma = 		    $u->karma;
 $lastUpdated = 	$u->lastUpdated;
 $languagePreference = 	$u->profileField("language",1);
 $referringAffiliate =	$u->referringAffiliate;
 $status =		$u->status("somestatus");
 $username =		$u->username("jonboy");
 $arrayRef =		$u->getGroups;
 $member =		$u->isInGroup($groupId);

 $u->addToGroups(\@arr);
 $u->deleteFromGroups(\@arr);
 $u->delete;

 WebGUI::User->validUserId($session, $userId);

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------
sub _create {
    my $session = shift;
    my $userId = shift || $session->id->generate();
    $session->db->write("insert into users (userId,dateCreated) values (?,?)",[$userId, time()]);
    $session->db->write("INSERT INTO userProfileData (userId) VALUES (?)",[$userId]);
    WebGUI::Group->new($session,2)->addUsers([$userId]);
    WebGUI::Group->new($session,7)->addUsers([$userId]);
    return $userId;
}

#-------------------------------------------------------------------

=head2 addToGroups ( groups [, expireOffset ] )

Adds this user to the specified groups.

=head3 groups

An array reference containing a list of groups.

=head3 expireOffset

An override for the default offset of the grouping. Specified in seconds.

=cut

sub addToGroups {
	my $self = shift;
	my $groups = shift;
	my $expireOffset = shift;
	$self->uncache;
	foreach my $groupId (@{$groups}) {
		WebGUI::Group->new($self->session,$groupId)->addUsers([$self->userId],$expireOffset);
	}
	$self->session->stow->delete("gotGroupsForUser");
}

#-------------------------------------------------------------------

=head2 acceptsPrivateMessages ( userId )

Returns a boolean of whether or not the user can receive private messages from the user passed in

=head3 userId

userId to determine if the user accepts private messages from

=cut

sub acceptsPrivateMessages {
    my $self      = shift;
    my $userId    = shift;

    my $pmSetting = $self->profileField('allowPrivateMessages');

    return 0 if ($pmSetting eq "none");
    return 1 if ($pmSetting eq "all");

    if($pmSetting eq "friends") {
        my $friendsGroup = $self->friends;
        my $sentBy       = WebGUI::User->new($self->session,$userId);
        #$self->session->errorHandler->warn($self->isInGroup($friendsGroup->getId));
        return $sentBy->isInGroup($friendsGroup->getId);
    }

    return 1;
}

#-------------------------------------------------------------------

=head2 authMethod ( [ value ] )

Returns the authentication method for this user.

=head3 value

If specified, the authMethod is set to this value. The only valid values are "WebGUI" and "LDAP". When a new account is created, authMethod is defaulted to "WebGUI".

=cut

sub authMethod {
        my ($self, $value);
        $self = shift;
        $value = shift;
        if (defined $value) {
		$self->uncache;
                $self->{_user}{"authMethod"} = $value;
                $self->{_user}{"lastUpdated"} =$self->session->datetime->time();
                $self->session->db->write("update users set authMethod=".$self->session->db->quote($value).",
			lastUpdated=".$self->session->datetime->time()." where userId=".$self->session->db->quote($self->{_userId}));
        }
        return $self->{_user}{"authMethod"};
}

#-------------------------------------------------------------------

=head2 canUseAdminMode ( )

Returns a boolean indicating whether the user has the basic privileges needed to turn on admin mode and use basic admin functions. Note this isn't checking for any special privileges like whether the user can create new users, etc.

=cut

sub canUseAdminMode {
        my $self = shift;
	my $pass = 1;
	my $subnets = $self->session->config->get("adminModeSubnets") || [];
	if (scalar(@$subnets)) {
		$pass = WebGUI::Utility::isInSubnet($self->session->env->getIp, $subnets);
	}

	return $pass && $self->isInGroup(12)
}

#-------------------------------------------------------------------

=head2 dateCreated ( )

Returns the epoch for when this user was created.

=cut

sub dateCreated {
        return $_[0]->{_user}{dateCreated};
}

#-------------------------------------------------------------------

=head2 delete ( )

Deletes this user, removes their user profile data, cleans up their
inbox, removes userSessionScratch data and authentication information,
removes them from any groups they belong to and deletes their
Friend's group.

=cut

sub delete {
    my $self = shift;
	$self->uncache;
    my $db = $self->session->db;
	foreach my $groupId (@{$self->getGroups($self->userId)}) {
		WebGUI::Group->new($self->session,$groupId)->deleteUsers([$self->userId]);
	}
    $self->friends->delete if ($self->{_user}{"friendsGroup"} ne "");
	$db->write("delete from inbox where userId=? and (groupId is null or groupId='')",[$self->{_userId}]);
	require WebGUI::Operation::Auth;
	my $authMethod = WebGUI::Operation::Auth::getInstance($self->session,$self->authMethod,$self->{_userId});
	$authMethod->deleteParams($self->{_userId});
	my $rs = $db->read("select sessionId from userSession where userId=?",[$self->{_userId}]);
	while (my ($id) = $rs->array) {
        	$db->write("delete from userSessionScratch where sessionId=?",[$id]);
	}
    $db->write("delete from userSession where userId=?",[$self->{_userId}]);
    $db->write("delete from userProfileData where userId=?",[$self->{_userId}]);
    $db->write("delete from users where userId=?",[$self->{_userId}]);
}

#-------------------------------------------------------------------

=head2 deleteFromGroups ( groups )

Deletes this user from the specified groups.

=head3 groups

An array reference containing a list of groups.

=cut

sub deleteFromGroups {
	my $self = shift;
	my $groups = shift;
	$self->uncache;
	foreach my $groupId (@{$groups}) {
		WebGUI::Group->new($self->session,$groupId)->deleteUsers([$self->userId]);
	}
	$self->session->stow->delete("gotGroupsForUser");
}

#-------------------------------------------------------------------

=head2 DESTROY ( )

Deconstructor.

=cut

sub DESTROY {
        my $self = shift;
        if (exists $self->{_friendsGroup}) {
            $self->{_friendsGroup}->DESTROY;
        }
        undef $self;
}


#-------------------------------------------------------------------

=head2 friends ( )

Returns the WebGUI::Group for this user's Friend's Group.  

=cut

sub friends {
    my $self = shift;
    if ($self->{_user}{"friendsGroup"} eq "") {
        my $myFriends = WebGUI::Group->new($self->session, "new");
        $myFriends->name($self->username." Friends");
        $myFriends->description("Friends of user ".$self->userId);
        $myFriends->expireOffset(60*60*24*365*60);
        $myFriends->showInForms(0);
        $myFriends->isEditable(0);
        $myFriends->deleteUsers(['3']);
        $self->uncache;
        $self->{_user}{"friendsGroup"} = $myFriends->getId;
        $self->{_user}{"lastUpdated"} = $self->session->datetime->time();
        $self->session->db->write("update users set friendsGroup=?, lastUpdated=? where userId=?",
            [$myFriends->getId, $self->session->datetime->time(), $self->userId]);
        $self->{_friendsGroup} = $myFriends;
    }
    elsif (! exists $self->{_friendsGroup}) {
        $self->{_friendsGroup} = WebGUI::Group->new($self->session, $self->{_user}{"friendsGroup"});
    }
    return $self->{_friendsGroup};
}

#-------------------------------------------------------------------

=head2 getFirstName ( )

Returns first name, or alias, or username depeneding upon what exists.

=cut

sub getFirstName {
    my $self = shift;
    return $self->profileField('firstName') || $self->profileField('alias') || $self->username;
}   

#-------------------------------------------------------------------

=head2 getGroups ( [ withoutExpired ] )

Returns an array reference containing a list of groups this user is in.

=head3 withoutExpired

If set to "1" then the listing will not include expired groupings. Defaults to "0".

=cut

sub getGroups {
	my $self = shift;
        my $withoutExpired = shift;
        my $clause = "";
	if ($withoutExpired) {
        	$clause = "and expireDate>".$self->session->datetime->time();
	}
	my $gotGroupsForUser = $self->session->stow->get("gotGroupsForUser");
        if (exists $gotGroupsForUser->{$self->userId}) {
                return $gotGroupsForUser->{$self->userId};
        } else {
                my @groups = $self->session->db->buildArray("select groupId from groupings where userId=? $clause", [$self->userId]);
		my $isInGroup = $self->session->stow->get("isInGroup");
                foreach my $gid (@groups) {	
                        $isInGroup->{$self->userId}{$gid} = 1;
                }
		$self->session->stow->set("isInGroup",$isInGroup);
                $gotGroupsForUser->{$self->userId} = \@groups;
		$self->session->stow->set("gotGroupsForUser",$gotGroupsForUser);
                return \@groups;
        }
}

#----------------------------------------------------------------------------

=head2 getGroupIdsRecursive ( )

Get the groups the user is in AND all the groups those groups are in, recursively.
Returns a flattened array reference of unique group IDs

=cut

sub getGroupIdsRecursive {
    my $self        = shift;
    my $groupingIds = $self->getGroups( "withoutExpired" );
    my %groupIds    = map { $_ => 1 } @{ $groupingIds };
    while ( my $groupingId = shift @{ $groupingIds } ) {
        my $group   = WebGUI::Group->new( $self->session, $groupingId );
        for my $groupGroupingId ( @{ $group->getGroupsFor } ) { 
            if ( !$groupIds{ $groupGroupingId } ) {
                push @{ $groupingIds }, $groupGroupingId;
            }
            $groupIds{ $groupGroupingId } = 1;
        }
    }
    
    return [ keys %groupIds ];
}

#-------------------------------------------------------------------

=head2 getWholeName ( )

Attempts to build the user's whole name from profile fields, and ultimately their alias and username if all else
fails.

=cut

sub getWholeName {
    my $self  = shift;
    if ($self->profileField('firstName') and $self->profileField('lastName')) {
        return join ' ', $self->profileField('firstName'), $self->profileField('lastName');
    }
    return $self->profileField("alias") || $self->username;
}

#-------------------------------------------------------------------
# This method is depricated and is provided only for reverse compatibility. See WebGUI::Auth instead.
sub identifier {
        my ($self, $value);
        $self = shift;
        $value = shift;
        if (defined $value) {
		$self->uncache;
                $self->{_user}{"identifier"} = $value;
                $self->session->db->write("update authentication set fieldData=".$self->session->db->quote($value)."
                        where userId=".$self->session->db->quote($self->{_userId})." and authMethod='WebGUI' and fieldName='identifier'");
        }
        return $self->{_user}{"identifier"};
}


#-------------------------------------------------------------------

=head2 isInGroup ( [ groupId ] )

Returns a boolean (0|1) value signifying that the user has the required privileges. Always returns true for Admins.

=head3 groupId

The group that you wish to verify against the user. Defaults to group with Id 3 (the Admin group).

=cut

sub isInGroup {
   my (@data, $groupId);
   my ($self, $gid, $secondRun) = @_;
   $gid = 3 unless (defined $gid);
   my $uid = $self->userId;
   ### The following several checks are to increase performance. If this section were removed, everything would continue to work as normal. 
   #my $eh = $self->session->errorHandler;
   #$eh->warn("Group Id is: $gid for ".$tgroup->name);
   return 1 if ($gid eq '7');		# everyone is in the everyone group
   return 1 if ($gid eq '1' && $uid eq '1'); 	# visitors are in the visitors group
   return 1 if ($gid eq '2' && $uid ne '1'); 	# if you're not a visitor, then you're a registered user
   ### Get data for auxillary checks.
   my $isInGroup = $self->session->stow->get("isInGroup");
   ### Look to see if we've already looked up this group. 
   return $isInGroup->{$uid}{$gid} if exists $isInGroup->{$uid}{$gid};
   ### Lookup the actual groupings.
   my $group = WebGUI::Group->new($self->session,$gid);
   # Cope with non-existant groups. Default to the admin group if the groupId is invalid.
   $group = WebGUI::Group->new($self->session, 3) unless $group;
   ### Check for groups of groups.
   my $users = $group->getAllUsers();
   foreach my $user (@{$users}) {
      $isInGroup->{$user}{$gid} = 1;
	  if ($uid eq $user) {
	     $self->session->stow->set("isInGroup",$isInGroup);
		 return 1;
	  }
   }
   $isInGroup->{$uid}{$gid} = 0;
   $self->session->stow->set("isInGroup",$isInGroup);
   return 0;
}


#-------------------------------------------------------------------

=head2 isOnline ()

Returns a boolean indicating whether this user is logged in and actively viewing pages in the site.

=cut

sub isOnline {
    my $self = shift;
    my ($flag) = $self->session->db->quickArray('select count(*) from userSession where userId=? and lastPageView>=?',
        [$self->userId, time() - 60*10]); 
    return $flag;
}


#-------------------------------------------------------------------

=head2 karma ( [ amount, source, description ] )

Returns the current level of karma this user has earned. 

=head3 amount

An integer to modify this user's karma by. Note that this number can be positive or negative.

=head3 source

A descriptive source for this karma. Typically it would be something like "MessageBoard (49)" or "Admin (3)". Source is used to track where a karma modification came from.

=head3 description

A description of why this user's karma was modified. For instance it could be "Message Board Post" or "He was a good boy!".

=cut

sub karma {
	my $self = shift;
	my $amount = shift;
	my $source = shift;
	my $description = shift;
	if (defined $amount && defined $source && defined $description) {
		$self->uncache;
		$self->{_user}{karma} += $amount;
		$self->session->db->write("update users set karma=karma+? where userId=?", [$amount, $self->userId]);
        	$self->session->db->write("insert into karmaLog values (?,?,?,?,?)",[$self->userId, $amount, $source, $description, $self->session->datetime->time()]);
	}
        return $self->{_user}{karma};
}

#-------------------------------------------------------------------

=head2 lastUpdated ( )

Returns the epoch for when this user was last modified.

=cut

sub lastUpdated {
        return $_[0]->{_user}{lastUpdated};
}

#-------------------------------------------------------------------

=head2 new ( session, userId [, overrideId ] )

Constructor.

=head3 session 

The session variable.

=head3 userId 

The userId of the user you're creating an object reference for. If left blank it will default to "1" (Visitor). If specified as "new" then a new user account will be created and assigned the next available userId. 

=head3 overrideId

A unique ID to use instead of the ID that WebGUI will generate for you. It must be absolutely unique and can be up to 22 alpha numeric characters long.

=cut

sub new {
    my $class       = shift;
    my $session     = shift;
    my $userId      = shift || 1;
    my $overrideId  = shift;
    $userId         = _create($session, $overrideId) if ($userId eq "new");
    my $cache       = WebGUI::Cache->new($session,["user",$userId]);
    my $userData    = $cache->get;
    unless ($userData->{_userId} && $userData->{_user}{username}) {
        my %user;
        tie %user, 'Tie::CPHash';
        %user = $session->db->quickHash("select * from users where userId=?",[$userId]);
        my %profile 
            = $session->db->quickHash(
                "select * from userProfileData where userId=?",
                [$user{userId}]
            );
        delete $profile{userId};

        my %default = $session->db->buildHash("select fieldName, dataDefault from userProfileField");
        foreach my $key (keys %default) {
            my $value;
            if ($profile{$key} eq "" && $default{$key}) {
                $value = eval($default{$key});
                if (ref $value eq "ARRAY") {
                    $profile{$key} = $value->[0];
                } else {
                    $profile{$key} = $value;
                }
            }
        }
        $profile{alias} = $user{username} if ($profile{alias} =~ /^\W+$/ || $profile{alias} eq "");
        $userData = {
            _userId => $userId,
            _user => \%user,
            _profile => \%profile
        };
        $cache->set($userData, 60*60*24);
    }
    $userData->{_session} = $session;
	bless $userData, $class;
}

#-------------------------------------------------------------------

=head2 newByEmail ( session, email )

Instanciates a user by email address. Returns undef if the email address could not be found.
Visitor may not be looked up with this method.

=head3 session

A reference to the current session.

=head3 email

The email address to search for.

=cut

sub newByEmail {
	my $class = shift;
	my $session = shift;
	my $email = shift;
	my ($id) = $session->dbSlave->quickArray("select userId from userProfileData where email=?",[$email]);
	my $user = $class->new($session, $id);
	return undef if ($user->userId eq "1"); # visitor is never valid for this method
	return undef unless $user->username;
	return $user;
}


#-------------------------------------------------------------------

=head2 newByUsername ( session, username )

Instanciates a user by username. Returns undef if the username could not be found.
Visitor may not be looked up with this method.

=head3 session

A reference to the current session.

=head3 username

The username to search for.

=cut

sub newByUsername {
	my $class = shift;
	my $session = shift;
	my $username = shift;
	my ($id) = $session->dbSlave->quickArray("select userId from users where username=?",[$username]);
	my $user = $class->new($session, $id);
	return undef if ($user->userId eq "1"); # visitor is never valid for this method
	return undef unless $user->username;
	return $user;
}


#-------------------------------------------------------------------

=head2 profileField ( fieldName [, value ] )

Returns a profile field's value. If "value" is specified, it also sets the field to that value. 

=head3 fieldName 

The profile field name such as "language" or "email" or "cellPhone".

=head3 value

The value to set the profile field name to.

=cut

sub profileField {
    my $self        = shift;
    my $fieldName   = shift;
    my $value       = shift;
    my $db          = $self->session->db;
    if (!exists $self->{_profile}{$fieldName} && !$self->session->db->quickScalar("SELECT COUNT(*) FROM userProfileField WHERE fieldName = ?", [$fieldName]) ) {
        $self->session->errorHandler->warn("No such profile field: $fieldName");
        return undef;
    }
    if (defined $value) {
        $self->uncache;
        $self->{_profile}{$fieldName} = $value;
        $db->write(
            "UPDATE userProfileData SET ".$db->dbh->quote_identifier($fieldName)."=? WHERE userId=?",
            [$value, $self->{_userId}]
        );
        my $time = $self->session->datetime->time;
        $self->{_user}{"lastUpdated"} = $time;
        $self->session->db->write("update users set lastUpdated=? where userId=?", [$time, $self->{_userId}]);
	}
	return $self->{_profile}{$fieldName};
}

#-------------------------------------------------------------------

=head2 referringAffiliate ( [ value ] )

Returns the unique identifier of the affiliate that referred this user to the site. 

=head3 value

An integer containing the unique identifier of the affiliate.

=cut

sub referringAffiliate {
        my $self = shift;
        my $value = shift;
        if (defined $value) {
		$self->uncache;
                $self->{_user}{"referringAffiliate"} = $value;
                $self->{_user}{"lastUpdated"} =$self->session->datetime->time();
                $self->session->db->write("update users set referringAffiliate=".$self->session->db->quote($value).",
                        lastUpdated=".$self->session->datetime->time()." where userId=".$self->session->db->quote($self->userId));
        }
        return $self->{_user}{"referringAffiliate"};
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

=head2 status ( [ value ] )

Returns the status of the user. 

=head3 value

If specified, the status is set to this value.  Possible values are 'Active', 'Selfdestructed' and 'Deactivated'.
'Selfdestructed' means that the user deactivated their own account.  'Deactivated' means that either
their status has been changed by an Admin, or that this is a new account that is pending email
confirmation before activation.

=cut

sub status {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->uncache;
		$self->{_user}{"status"} = $value;
		$self->{_user}{"lastUpdated"} =$self->session->datetime->time();
		$self->session->db->write("update users set status=".$self->session->db->quote($value).",
		lastUpdated=".$self->session->datetime->time()." where userId=".$self->session->db->quote($self->userId));
		if ($value eq 'Deactivated') {
			my $rs = $self->session->db->read("select sessionId from userSession where userId=?",[$self->{_userId}]);
			while (my ($id) = $rs->array) {
				$self->session->db->write("delete from userSessionScratch where sessionId=?",[$id]);
			}
			$self->session->db->write("delete from userSession where userId=?",[$self->{_userId}]);
		}
	}
	return $self->{_user}{"status"};
}

#-------------------------------------------------------------------

=head2 uncache ( )

Deletes this user object out of the cache.

=cut

sub uncache {
	my $self = shift;
	my $cache = WebGUI::Cache->new($self->session,["user",$self->userId]);
	$cache->delete;	
}

#-------------------------------------------------------------------

=head2 username ( [ value ] )

Returns the username. 

=head3 value

If specified, the username is set to this value. 

=cut

sub username {
        my $self = shift;
        my $value = shift;
        if (defined $value) {
		$self->uncache;
                $self->{_user}{"username"} = $value;
                $self->{_user}{"lastUpdated"} = $self->session->datetime->time();
                $self->session->db->write("update users set username=?, lastUpdated=? where userId=?",
                    [$value, $self->session->datetime->time(), $self->userId]);
        }
        return $self->{_user}{"username"};
}

#-------------------------------------------------------------------

=head2 userId ( )

Returns the userId for this user.

=cut

sub userId {
        return $_[0]->{_userId};
}

#-------------------------------------------------------------------

=head2 validUserId ( userId )

Returns true if the userId exists in the users table. 

=cut

sub validUserId {
	my ($class, $session, $userId) = @_;
	my $sth = $session->db->read('select userId from users where userId=?',[$userId]);
	return ($sth->rows == 1);
}

1;
