package WebGUI::AssetAspect::Comments;

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
use Class::C3;
use JSON;
use Tie::IxHash;
use WebGUI::Exception;
use WebGUI::Form;
use WebGUI::HTML;
use WebGUI::Utility;

=head1 NAME

Package WebGUI::AssetAspect::Comments

=head1 DESCRIPTION

This is an aspect which makes adding comments to existing assets trivial.

=head1 SYNOPSIS

 use Class::C3;
 use base qw(WebGUI::AssetAspect::Comments WebGUI::Asset);
 
And then where-ever you would call $self->SUPER::someMethodName call $self->next::method instead.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 addComment ( comment [, rating, user ] )

Posts a comment.

=head3 comment

A string that acts as a comment from a user.

=head3 rating

Defaults to 0. An integer between 0 and 5 inclusive. 0 represents N/A, 1 represents a negative rating, 3 represents a neutral rating, and 5 represents a positive rating.

=head3 user

Defaults to the current user. A WebGUI::User object.

=cut

sub addComment {
	my ($self, $comment, $rating, $user) = @_;
	my $session = $self->session;
	$user ||= $session->user;
	$rating ||= 0;
	
	# add the new comment to the list of comments
	my $comments = $self->get('comments');
	push @$comments, {
		id			=> $session->id->generate,
		alias		=> $user->profileField('alias'),
		userId		=> $user->userId,
		comment		=> $comment,
		rating		=> $rating,
		date		=> time(),
		ip			=> $session->var->get('lastIP'),
		};
	
	# calculate average
	my $sum = 0;
	my $count = 0;
	foreach my $comment (@$comments) {
		next unless $comment->{rating} > 0; # skip n/a ratings
		$count++;
		$sum += $comment->{rating};
	}
	my $average = 0;
	if ($count > 0) {
		$average = $sum/$count;
	}
	
	# update the database
	$self->update({comments=>$comments, averageCommentRating=>$average});
	
	# add karma
	if ($session->setting->get('useKarma')) {
		unless ($user->isVisitor) {
			$user->karma($self->getKarmaAmountPerComment, $self->getId, 'Left comment for '.$self->getName.' '.$self->getTitle);
		}
	}
}

#-------------------------------------------------------------------

=head2 canComment ()

Returns a boolean indicating whether the current user can post a comment.

=cut

sub canComment {
	my $self = shift;
	return $self->session->user->isInGroup($self->getGroupToComment) || $self->canEdit;
}


#-------------------------------------------------------------------

=head2 definition

Extends the definition to add the comments and averageCommentRating fields.

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	%properties = (
		comments => {
			noFormPost		=> 1,
			fieldType       => "hidden",
			defaultValue    => [],
			},
		averageCommentRating => {
			noFormPost		=> 1,
			fieldType       => "hidden",
			defaultValue    => 0,
			},
	    );
	push(@{$definition}, {
		autoGenerateForms   => 1,
		tableName           => 'assetAspectComments',
		className           => 'WebGUI::Asset::Sku::BazaarItem',
		properties          => \%properties
	    });
	return $class->next::method($session, $definition);
}

#-------------------------------------------------------------------

=head2 deleteComment ( id )

Deletes a comment.

=head3 id

The GUID for the comment to delete.

=cut

sub deleteComment {
	my ($self, $id) = @_;
	my $session = $self->session;
	
	# remove the comment from the list of comments and calculate the average
	my $comments = $self->get('comments');
	my @updatedComments;
	my $sum = 0;
	my $count = 0;
	my $userId;
	foreach my $comment (@$comments) {
		if ($comment->{id} eq $id) {
			$userId = $comment->{userId};
			next;
		}
		push @updatedComments, $comment;
		next unless $comment->{rating} > 0; # skip n/a ratings
		$count++;
		$sum += $comment->{rating};
	}
	
	# update the database
	my $average = 0;
	if ($count > 0) {
		$average = $sum/$count;
	}
	$self->update({comments=>\@updatedComments, averageCommentRating=>$average});
	
	# remove karma
	if ($session->setting->get('useKarma')) {
		if (defined $userId) {
			my $user = WebGUI::User->new($session, $userId);
			unless ($user->isVisitor) {
				$user->karma(($self->getKarmaAmountPerComment * -1), $self->getId, 'Deleted comment for '.$self->getName.' '.$self->getTitle);
			}
		}
	}
}

#-------------------------------------------------------------------

=head2 get ()

See SUPER::get(). Extends the get() method to automatically decode the comments field into a Perl hash structure.

=cut

sub get {
	my $self = shift;
	my $param = shift;
	if ($param eq 'comments') {
		return JSON->new->decode($self->next::method('comments')||'[]');
	}
	return $self->next::method($param, @_);
}

#-------------------------------------------------------------------

=head2 getAverageCommentRatingIcon ()

Returns the HTML needed to render the average rating icon.

=cut

sub getAverageCommentRatingIcon {
	my $self = shift;
	return q{<img src="}.$self->session->url->extras('form/CommentRating/'.round($self->get('averageCommentRating'),0).'.png').q{" style="vertical-align: middle;" alt="}.$self->get('averageCommentRating').q{" />};
	
}

#-------------------------------------------------------------------

=head2 getFormattedComments ()

Returns an HTML string listing the comments so far and the leave a comment form if the user canComment().

=cut

sub getFormattedComments {
	my $self = shift;
	my $session = $self->session;
	my $url = $session->url;
	my $out = '<div class="assetAspectComments">';
	my $canEdit = $self->canEdit;
	my $comments = $self->get('comments');
	foreach my $comment (@$comments) {
		$out .= q{<div class="assetAspectComment"><img src="}.$url->extras('form/CommentRating/'.$comment->{rating}.'.png').q{" alt="}.$comment->{rating}.q{" style="vertical-align: bottom;" />};
		if ($canEdit) {
			$out .= q{ <a href="}.$self->getUrl("func=deleteComment;commentId=".$comment->{id}).q{">[X]</a> };
		}
		$out .= q{<b>}.$comment->{alias}.q{:</b> "}.WebGUI::HTML::format($comment->{comment},'text').q{"</div>};
	}
	if ($self->canComment) {
		$out .= '<div class="assetAspectCommentForm">';
		$out .= WebGUI::Form::formHeader($session, {action=>$self->getUrl});
		$out .= WebGUI::Form::hidden($session, {name=>"func",value=>"addComment"});
		$out .= WebGUI::Form::textarea($session, {name=>"comment"});
		$out .= WebGUI::Form::commentRating($session, {name=>"rating"});
		$out .= WebGUI::Form::submit($session);
		$out .= WebGUI::Form::formFooter($session);
		$out .= '</div>';
	}
	$out .= '</div>';
	return $out;
}

#-------------------------------------------------------------------

=head2 getGroupToComment ()

Returns '2' aka Registered Users. However, should be overridden by subclasses that wish to make this a settable property.

=cut

sub getGroupToComment {
	return '2';
}

#-------------------------------------------------------------------

=head2 getKarmaAmountPerComment ()

Returns 3. However, should be overridden by subclasses that wish to make this a settable property.

=cut

sub getKarmaAmountPerComment {
	return 3;
}


#-------------------------------------------------------------------

=head2 update ()

See SUPER::update(). Extends the update() method to encode the comments field into something storable in the database.

=cut

sub update {
	my $self = shift;
	my $properties = shift;
	if (exists $properties->{comments}) {
        my $comments = $properties->{comments};
        if (ref $comments ne 'ARRAY') {
			$comments = eval{JSON->new->decode($comments)};
            if (WebGUI::Error->caught || ref $comments ne 'ARRAY') {
                $comments = [];
			}
        }
        $properties->{comments} = JSON->new->encode($comments);
    }
	$self->next::method($properties, @_);
}

#-------------------------------------------------------------------

=head2 www_addComment ()

Posts a comment after verifying the user's privileges.

=cut

sub www_addComment {
	my $self = shift;
	my $session = $self->session;
	return $session->privilege->insufficient() unless ($self->canComment);
	my $form = $session->form;
	my $comment = $form->get('comment','textarea');
	WebGUI::Macro::negate(\$comment);
	if ($comment ne '') {
		$self->addComment($comment, $form->get('rating','commentRating'));
	}
	$self->www_view;
}

#-------------------------------------------------------------------

=head2 www_deleteComment ()

Removes a comment.

=cut

sub www_deleteComment {
	my $self = shift;
	my $session = $self->session;
	return $session->privilege->insufficient() unless ($self->canEdit);
	$self->deleteComment($session->form->get('commentId'));
	$self->www_view;
}

1;

