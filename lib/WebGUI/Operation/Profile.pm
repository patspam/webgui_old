package WebGUI::Operation::Profile;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict qw(vars subs);
use URI;
use WebGUI::Asset::Template;
use WebGUI::Operation::Auth;
use WebGUI::HTML;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::SQL;
use WebGUI::User;
use WebGUI::Utility;
use WebGUI::ProfileField;
use WebGUI::ProfileCategory;
use WebGUI::Operation::Shared;
use WebGUI::Operation::Friends;

=head1 NAME

Package WebGUI::Operation::Profile

=head1 DESCRIPTION

Operational handler for viewing, editing and validating user profile data.

=head1 METHODS

These methods are available from this package:

=cut

#-------------------------------------------------------------------

=head2 getRequiredProfileFields ( session )

Returns an array of hashes for required profile fields.  This array is ready
to be used as template variables in the WebGUI template system.

This method is deprecated, and should not be used in new code.  Use
the getRequiredFields method from WebGUI::ProfileField and specify the
translation to template variables directly instead.

NOTE: You should use the getRequiredFields method in WebGUI::ProfileField instead.

=head3 session

The current WebGUI session object.

=cut

# Builds Extra form requirements for anonymous registration.
sub getRequiredProfileFields {
	my $session = shift;
	my @array;
	foreach my $field (@{WebGUI::ProfileField->getRequiredFields($session)}) {
		push(@array, {
			'profile.formElement' => $field->formField,
			'profile.formElement.label' => $field->getLabel
			});
	}	
	return \@array;
}

#-------------------------------------------------------------------

=head2 isDuplicateEmail ( email )

Checks the value of the email address passed in to see if it is
duplicated in the system.  Returns true of false.  Will return false
if the email address passed in is same as the email address of the
current user.

=head3 email

email address to check for duplication

=cut

sub isDuplicateEmail {
    my $session     = shift;
    my $email       = shift;
    my ($otherEmail) 
        = $session->db->quickArray(
            'select count(*) from userProfileData where email = ? and userId <> ?',
            [$email, $session->user->userId]
        );
    return ($otherEmail > 0);
}

#-------------------------------------------------------------------

=head2 saveProfileFields ( session, user, profile )

Saves profile data to a user's profile.  Does not validate any of the data.

=head3 session

WebGUI session object

=head3 user

User object.  Profile data will be placed in this user's profile.

=head3 profile

Hash ref of profile data to save.

=cut

sub saveProfileFields {
	my $session = shift;
	my $u = shift;
	my $profile = shift;

	foreach my $fieldName (keys %{$profile}) {
		$u->profileField($fieldName,${$profile}{$fieldName});
	}
}

#-------------------------------------------------------------------

=head2 validateProfileData ( session )

Validates profile data from the session form variables.  Returns processed data, warnings
and errors.

There are two levels of validation:

=over 4

=item 1

If the profile field is required, and the form field is blank, returns an error.

=item 2

If the profile field label is "email", then checks for a duplicate email and returns a
warning if it is a duplicate.

=back

=cut

sub validateProfileData {
	my $session = shift;
	my $opts = shift || {};
    my $regOnly = $opts->{regOnly};
    my %data = ();
	my $error = "";
	my $warning = "";
	my $i18n = WebGUI::International->new($session);
    my $fields = $regOnly ? WebGUI::ProfileField->getRegistrationFields($session)
                          : WebGUI::ProfileField->getEditableFields($session);
	foreach my $field (@$fields) {
		my $fieldValue = $field->formProcess;
		if (ref $fieldValue eq "ARRAY") {
			$data{$field->getId} = $$fieldValue[0];
		} else {
			$data{$field->getId} = $fieldValue;
		}
		if ($field->isRequired && $data{$field->getId} eq "") {
			$error .= '<li>'.$field->getLabel.' '.$i18n->get(451).'</li>';
		} elsif ($field->getId eq "email" && isDuplicateEmail($session,$data{$field->getId}) && WebGUI::ProfileField->new($session, "email")->isRequired() ) {
			$warning .= '<li>'.$i18n->get(1072).'</li>';
		}
		if ($field->getId eq "language" && $fieldValue ne "") { 
			unless (exists $i18n->getLanguages()->{$fieldValue}) {
				$error .= '<li>'.$field->getLabel.' '.$i18n->get(451).'</li>';
			}
		}
	}
	return (\%data, $error, $warning);
}

#-------------------------------------------------------------------

=head2 www_editProfile ( session )

Provide a form where user profile data can be entered or edited.  The subroutine
makes a large set of template variables which are passed to a template for presentation
and styling.  The default template is PBtmpl0000000000000051 and is not user
selectable.

Calls www_editProfileSave on submission.

=head3 session

A reference to the current session.

=cut

sub www_editProfile {
	my $session = shift;
	return WebGUI::Operation::Auth::www_auth($session,"init") if($session->user->userId eq '1');
	my $i18n = WebGUI::International->new($session);
	my $vars = {};
	$vars->{displayTitle} .= $i18n->get(338);
	$vars->{'profile.message'} = $_[0] if($_[0]);
	$vars->{'profile.form.header'} = "\n\n".WebGUI::Form::formHeader($session,{});
	$vars->{'profile.form.footer'} = WebGUI::Form::formFooter($session,);

	$vars->{'profile.form.hidden'} = WebGUI::Form::hidden($session,{"name"=>"op","value"=>"editProfileSave"});
	$vars->{'profile.form.hidden'} .= WebGUI::Form::hidden($session,{"name"=>"uid","value"=>$session->user->userId});
	my @array = ();
	foreach my $category (@{WebGUI::ProfileCategory->getCategories($session)}) {
		next unless $category->isEditable;
		my @temp = ();
		foreach my $field (@{$category->getFields}) {
			next unless ($field->isEditable);
			next if $field->getId =~ /contentPositions/;
			push(@temp, {
				'profile.form.element' => $field->formField,
				'profile.form.element.label' => $field->getLabel,
				'profile.form.element.subtext' => $field->isRequired ? "*" : undef
				});
		}
		push(@array, {
			'profile.form.category' => $category->getLabel,
                        'profile.form.category.loop' => \@temp
			});
	}
	$vars->{'profile.form.elements'} = \@array;
	$vars->{'profile.form.submit'} = WebGUI::Form::submit($session,{});
	$vars->{'profile.accountOptions'} = WebGUI::Operation::Shared::accountOptions($session);
	return $session->style->userStyle(WebGUI::Asset::Template->new($session, $session->setting->get('editUserProfileTemplate'))->process($vars));
}

#-------------------------------------------------------------------

=head2 www_editProfileSave ( session )

Validates all data submitted by www_editProfile.  If errors or warnings are present, 
they are concatenated and sent back to www_editProfile for display and to let the user
correct their mistakes.

If no mistakes are present, saves the data to the user's profile, updates the session user
object.

Returns the user to WebGUI::Operation::Auth::www_auth when done.

=head3 session

A reference to the current session.

=cut

sub www_editProfileSave {
	my $session = shift;
	my ($profile, $error, $warning);
	return WebGUI::Operation::Auth::www_auth($session, "init") if ($session->user->userId eq '1');
	($profile, $error, $warning) = validateProfileData($session);
	$error .= $warning;
	return www_editProfile($session, '<ul>'.$error.'</ul>') if($error ne "");
	foreach my $fieldName (keys %{$profile}) {
		$session->user->profileField($fieldName,$profile->{$fieldName});
	}
	return WebGUI::Operation::Auth::www_auth($session);
}

#-------------------------------------------------------------------

=head2 www_viewProfile ( session )

View the profile data for a user by the userId specified by the form variable C<uid>.
Validates that the user requesting the profile data is allowed to see it.
Similarly to www_editProfile, this method is templated.  The default template
is PBtmpl0000000000000052.  The template is not user selectable.

=head3 session

A reference to the current session.

=cut

sub www_viewProfile {
    my $session = shift;
    my $u       = WebGUI::User->new($session,$session->form->process("uid"));
    my $i18n    = WebGUI::International->new($session);
    my $vars    = {};
    $vars->{displayTitle} = $i18n->get(347).' '.$u->username;

    return $session->privilege->notMember() if($u->username eq "");

    return $session->style->userStyle($vars->{displayTitle}.'. '.$i18n->get(862)) if($u->profileField("publicProfile") < 1 && ($session->user->userId ne $session->form->process("uid") || $session->user->isInGroup(3)));
    return $session->privilege->insufficient() if(!$session->user->isInGroup(2));

    my @array = ();
    foreach my $category (@{WebGUI::ProfileCategory->getCategories($session)}) {
        next unless ($category->get("visible"));
        push(@array, {'profile.category' => $category->getLabel});
        foreach my $field (@{$category->getFields}) {
            next unless ($field->get("visible"));
            next if ($field->get("fieldName") eq "email" && !$u->profileField("publicEmail"));
            push @array, {
                'profile.label' => $field->getLabel,
                'profile.value' => $field->formField(undef,2,$u),
            };
        }
    }
    $vars->{'profile.elements'} = \@array;

    if ($session->user->userId eq $session->form->process("uid")) {
        $vars->{'profile.accountOptions'} = WebGUI::Operation::Shared::accountOptions($session);
    }
    else {
        ## TODO: Make this more legible code, maybe refactor into a method
        push @{$vars->{'profile.accountOptions'}}, {
            'options.display'   => '<a href="'.$session->url->page("op=addFriend;userId=".$u->userId).'">'.$i18n->get('add to friends list', 'Friends').'</a>',
        }, {
            'options.display'   => '<a href="'.$session->url->page('op=sendPrivateMessage;uid='.$session->form->process("uid")).'">'.$i18n->get('send private message').'</a>',
        };
    }

    return $session->style->userStyle(WebGUI::Asset::Template->new($session, $session->setting->get('viewUserProfileTemplate'))->process($vars));
}


1;
