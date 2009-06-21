package WebGUI::Asset::Story;

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
use base 'WebGUI::Asset';
use Tie::IxHash;
use WebGUI::Utility;
use WebGUI::International;
use JSON qw/from_json to_json/;
use Storable qw/dclone/;
use Data::Dumper;

=head1 NAME

Package WebGUI::Asset::Story

=head1 DESCRIPTION

The Story Asset is like a Thread for the Collaboration.

=head1 SYNOPSIS

use WebGUI::Asset::Story;


=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 addChild ( )

You can't add children to a Story.

=cut

sub addChild {
    return undef;
}

#-------------------------------------------------------------------

=head2 addRevision

Copy storage locations so that purging individual revisions works correctly.

Request autocommit.

=cut

sub addRevision {
    my $self    = shift;
    my $session = $self->session;
    my $newSelf = $self->next::method(@_);

    my $newProperties = {
        isHidden => 1,
    };

    $newSelf->update($newProperties);

    my $newPhotoData = $newSelf->duplicatePhotoData;
    $newSelf->setPhotoData($newPhotoData);
    $newSelf->requestAutoCommit;

    return $newSelf;
}

#-------------------------------------------------------------------

=head2 canEdit ( )

You can't add children to a Story.

=cut

sub canEdit {
    my $self = shift;
    my $userId = shift || $self->session->user->userId;
    if ($userId eq $self->get("ownerUserId")) {
        return 1;
    }
    my $user = WebGUI::User->new($self->session, $userId);
    return $self->SUPER::canEdit($userId)
        || $self->getArchive->canPostStories($userId);
}

#-------------------------------------------------------------------

=head2 definition ( session, definition )

defines asset properties for New Asset instances.  You absolutely need 
this method in your new Assets. 

=head3 session

=head3 definition

A hash reference passed in from a subclass definition.

=cut

sub definition {
    my $class = shift;
    my $session = shift;
    my $definition = shift;
    my %properties;
    tie %properties, 'Tie::IxHash';
    my $i18n = WebGUI::International->new($session, 'Asset_Story');
    %properties = (
        headline => {
            fieldType    => 'text',  
            #label        => $i18n->get('headline'),
            #hoverHelp    => $i18n->get('headline help'),
            defaultValue => '',
        },
        subtitle => {
            fieldType    => 'text',  
            #label        => $i18n->get('subtitle'),
            #hoverHelp    => $i18n->get('subtitle help'),
            defaultValue => '',
        },
        byline => {
            fieldType    => 'text',  
            #label        => $i18n->get('byline'),
            #hoverHelp    => $i18n->get('byline help'),
            defaultValue => '',
        },
        location => {
            fieldType    => 'text',  
            #label        => $i18n->get('location'),
            #hoverHelp    => $i18n->get('location help'),
            defaultValue => '',
        },
        highlights => {
            fieldType    => 'textarea',  
            #label        => $i18n->get('highlights'),
            #hoverHelp    => $i18n->get('highlights help'),
            defaultValue => '',
        },
        story => {
            fieldType    => 'HTMLArea',  
            #label        => $i18n->get('highlights'),
            #hoverHelp    => $i18n->get('highlights help'),
            #richEditId  => $self->parent->getStoryRichEdit,
            defaultValue => '',
        },
        photo => {
            fieldType    => 'text',
            defaultValue => '[]',
            noFormPost   => 1,
        },
    );
    push(@{$definition}, {
        assetName         => $i18n->get('assetName'),
        icon              => 'story.gif',
        tableName         => 'Story',
        className         => 'WebGUI::Asset::Story',
        properties        => \%properties,
        autoGenerateForms => 0,
    });
    return $class->next::method($session, $definition);
}


#-------------------------------------------------------------------

=head2 duplicate ( )

Extent the method from Asset to handle duplicating storage locations.

=cut

sub duplicate {
	my $self = shift;
	my $newSelf = $self->next::method(@_);
    my $newPhotoData = $newSelf->duplicatePhotoData;
    $newSelf->setPhotoData($newPhotoData);
	return $newSelf;
}

#-------------------------------------------------------------------

=head2 duplicatePhotoData ( )

Duplicate photo data, particularly storage locations.  Returns the duplicated
perl structure.

=cut

sub duplicatePhotoData {
	my $self      = shift;
    my $session   = $self->session;
    my $photoData = $self->getPhotoData;
    PHOTO: foreach my $photo (@{ $photoData }) {
        next PHOTO unless $photo->{storageId};
        my $oldStorage      = WebGUI::Storage->get($session, $photo->{storageId});
        my $newStorage      = $oldStorage->copy;
        $photo->{storageId} = $newStorage->getId;
    }
	return $photoData;
}

#-------------------------------------------------------------------

=head2 exportAssetData ( )

See WebGUI::AssetPackage::exportAssetData() for details.
Adds all storage locations to the package data.

=cut

sub exportAssetData {
	my $self = shift;
	my $exportData = $self->next::method;
    PHOTO: foreach my $photo (@{ $self->getPhotoData }) {
        next PHOTO unless $photo->{storageId};
        push @{ $exportData->{storage} }, $photo->{storageId};
    }
    return $exportData;
}

#-------------------------------------------------------------------

=head2 formatDuration ( $lastUpdated )

Format the time since this story was last updated.  If it is longer than 1 week, then
return the date.

=head3 $lastUpdated

The date this was last updated.  If left blank, it uses the revisionDate.

=cut

sub formatDuration {
    my ($self, $lastUpdated) = @_;
    $lastUpdated = defined $lastUpdated ? $lastUpdated : $self->get('revisionDate');
    my $session = $self->session;
    my $datetime = $session->datetime;
    my $duration = time() - $lastUpdated;
    if ($duration > 86400) { ##1 day
        return join ' ', $datetime->secondsToInterval($duration);
    }
    else {
        my $formattedDuration = '';
        my $hours = int($duration/3600) * 3600;
        my @hours = $datetime->secondsToInterval($hours);
        if ($hours[0]) {
            $formattedDuration = join ' ', @hours;
        }
        my $minutes = round(($duration - $hours)/60)*60;
        my @minutes = $datetime->secondsToInterval($minutes);
        if ($minutes[0]) {
            $formattedDuration .= ', ', if $formattedDuration;
            $formattedDuration .= join ' ', @minutes;
        }
        return $formattedDuration;
    }
}

#-------------------------------------------------------------------

=head2 getArchive (  )

Returns the parent archive for this Story.  Cache the entry for speed.

=cut

sub getArchive {
    my $self = shift;
    if (!$self->{_archive}) {
        $self->{_archive} = $self->getParent->getParent;
    }
    return $self->{_archive};
}

#-------------------------------------------------------------------

=head2 getAutoCommitWorkflowId (  )

Get the autocommit workflow from the archive containing this Story and
use it.

=cut

sub getAutoCommitWorkflowId {
	my $self    = shift;
    my $archive = $self->getArchive;
    if ($archive->hasBeenCommitted) {
        return $archive->get('approvalWorkflowId')
            || $self->session->setting->get('defaultVersionTagWorkflow');
    }
    return undef;
}


#-------------------------------------------------------------------

=head2 getCrumbTrail (  )

Returns the crumb trail for this Story.  If rendered from inside
a Topic, it will insert the Topic information into the crumb trail.

The crumb trail will be a loop of variables, in order from this Story's
StoryArchive, the topic, if present, and then this story.

=cut

sub getCrumbTrail {
    my $self    = shift;
    my $crumb_loop = [];
    my $archive = $self->getArchive;
    push @{ $crumb_loop }, {
        title => $archive->getTitle,
        url   => $archive->getUrl,
    };
    my $topic = $self->topic;
    if ($topic) {
        push @{ $crumb_loop }, {
            title => $topic->getTitle,
            url   => $topic->getUrl,
        };
    }
    push @{ $crumb_loop }, {
        title => $self->getTitle,
        url   => $self->getUrl,
    };
    return $crumb_loop;
}

#-------------------------------------------------------------------

=head2 getEditForm (  )

Returns a templated form for adding or editing Stories.

=cut

sub getEditForm {
    my $self    = shift;
    my $session = $self->session;
    my $i18n    = WebGUI::International->new($session, 'Asset_Story');
    my $form    = $session->form;
    my $archive = $self->getArchive;
    my $isNew   = $self->getId eq 'new';
    my $url     = $isNew ? $archive->getUrl : $self->getUrl;
    my $title   = $self->getTitle;
    my $var     = {
        formHeader     => WebGUI::Form::formHeader($session, {action => $url})
                        . WebGUI::Form::hidden($session, { name => 'func',    value => 'editSave' })
                        . WebGUI::Form::hidden($session, { name => 'proceed', value => 'showConfirmation' })
                        ,
        formFooter     => WebGUI::Form::formFooter($session),
        formTitle      => $isNew
                        ? $i18n->get('add a story','Asset_StoryArchive')
                        : $i18n->get('editing','Asset_WikiPage').' '.$title,
        headlineForm   => WebGUI::Form::text($session, {
                             name  => 'headline',
                             value => $form->get('headline') || $self->get('headline'),
                          } ),
        titleForm      => WebGUI::Form::text($session, {
                             name  => 'title',
                             value => $form->get('title')    || $self->get('title'),
                          } ),
        subtitleForm   => WebGUI::Form::text($session, {
                             name  => 'subtitle',
                             value => $form->get('subtitle') || $self->get('subtitle')
                          } ),
        bylineForm     => WebGUI::Form::text($session, {
                             name  => 'byline',
                             value => $form->get('byline')   || $self->get('byline')
                          } ),
        locationForm   => WebGUI::Form::text($session, {
                             name  => 'location',
                             value => $form->get('location') || $self->get('location')
                          } ),
        keywordsForm   => WebGUI::Form::keywords($session, {
                            name  => 'keywords',
                            value => $form->get('keywords')  || WebGUI::Keyword->new($session)->getKeywordsForAsset({ asset => $self })
                         } ),
        highlightsForm => WebGUI::Form::textarea($session, {
                            name  => 'highlights',
                            value => $form->get('highlights') || $self->get('highlights')
                          } ),
        storyForm      => WebGUI::Form::HTMLArea($session, {
                            name  => 'story',
                            value => $form->get('story')      || $self->get('story'),
                            richEditId => $archive->get('richEditorId')
                          }),
        saveButton     => WebGUI::Form::submit($session, {
                            name  => 'saveStory',
                            value => $i18n->get('save story'),
                          }),
        cancelButton   => WebGUI::Form::button($session, {
                            name   => 'cancel',
                            value  => $i18n->get('cancel','WebGUI'),
                            extras => q|onclick="history.go(-1);" class="backwardButton"|,
                          }),
        saveAndAddButton  => WebGUI::Form::submit($session, {
                            name  => 'saveAndReturn',
                            value => $i18n->get('save and add another photo'),
                          }),
    };
    $var->{ photo_form_loop } = [];
    ##Provide forms for the existing photos, if any
    ##Existing photos get a delete Yes/No.
    ##And a form for new ones
    my $photoData      = $self->getPhotoData;
    my $numberOfPhotos = scalar @{ $photoData };
    foreach my $photoIndex (1..$numberOfPhotos) {
        my $photo = $photoData->[$photoIndex-1];
        push @{ $var->{ photo_form_loop } }, {
            imgUploadForm  => WebGUI::Form::image($session, {
                                 name           => 'photo'.$photoIndex,
                                 maxAttachments => 1,
                                 value          => $photo->{storageId},
                              }),
            imgCaptionForm => WebGUI::Form::text($session, {
                                 name  => 'imgCaption'.$photoIndex,
                                 value => $photo->{caption},
                              }),
            imgByLineForm  => WebGUI::Form::text($session, {
                                 name  => 'imgByline'.$photoIndex,
                                 value => $photo->{byLine},
                              }),
            imgAltForm     => WebGUI::Form::text($session, {
                                 name  => 'imgAlt'.$photoIndex,
                                 value => $photo->{alt},
                              }),
            imgTitleForm   => WebGUI::Form::text($session, {
                                 name  => 'imgTitle'.$photoIndex,
                                 value => $photo->{title},
                              }),
            imgUrlForm     => WebGUI::Form::url($session, {
                                 name  => 'imgUrl'.$photoIndex,
                                 value => $photo->{url},
                              }),
            imgDeleteForm  => WebGUI::Form::yesNo($session, {
                                 name  => 'deletePhoto'.$photoIndex,
                                 value => 0,
                              }),
        };
    }
    push @{ $var->{ photo_form_loop } }, {
        imgUploadForm  => WebGUI::Form::image($session, {
                             name           => 'newPhoto',
                             maxAttachments => 1,
                          }),
        imgCaptionForm => WebGUI::Form::text($session, {
                             name => 'newImgCaption',
                          }),
        imgByLineForm  => WebGUI::Form::text($session, {
                             name => 'newImgByline',
                          }),
        imgAltForm     => WebGUI::Form::text($session, {
                             name => 'newImgAlt',
                          }),
        imgTitleForm   => WebGUI::Form::text($session, {
                             name => 'newImgTitle',
                          }),
        imgUrlForm     => WebGUI::Form::url($session, {
                             name => 'newImgUrl',
                          }),
    };
    if ($isNew) {
        $var->{formHeader} .= WebGUI::Form::hidden($session, { name => 'assetId', value => 'new' })
                           .  WebGUI::Form::hidden($session, { name => 'class',   value => $form->process('class', 'className') });
    }
    else {
        $var->{formHeader} .= WebGUI::Form::hidden($session, { name => 'url',     value => $url});
    }
    return $self->processTemplate($var, $archive->get('editStoryTemplateId'));

}

#-------------------------------------------------------------------

=head2 getPhotoData (  )

Returns the photo hash formatted as perl data.  See also L<setPhotoData>.

=cut

sub getPhotoData {
	my $self     = shift;
	if (!exists $self->{_photoData}) {
        my $json = $self->get('photo');
        $json ||= '[]';
        $self->{_photoData} = from_json($json);
	}
	return dclone($self->{_photoData});
}

#-------------------------------------------------------------------

=head2 getRssData (  )

Returns RSS data for this Story.  The date of the RSS item is the lastModified
property of the Asset.

=cut

sub getRssData {
	my $self = shift;
    my $data = {
        title       => $self->get('headline') || $self->getTitle,
        description => $self->get('subtitle'),
        'link'      => $self->getUrl,
        author      => $self->get('byline'),
        date        => $self->get('lastModified'),
    };
	return $data;
}

#-------------------------------------------------------------------

=head2 prepareView ( )

Extent the default method to handle the case when a Story Topic is rendering
this Story.

=cut

sub prepareView {
    my $self       = shift;
    $self->next::method();
    my $templateId;
    my $topic = $self->topic;
    if ($topic) {
        $templateId = $topic->get('storyTemplateId');
    }
    else {
        $templateId = $self->getArchive->get('storyTemplateId');
    }
    my $template = WebGUI::Asset::Template->new($self->session, $templateId);
    $template->prepare;
    $self->{_viewTemplate} = $template;
}


#-------------------------------------------------------------------

=head2 processPropertiesFromFormPost ( )

Handle photos and photo metadata, like captions, etc.

=cut

sub processPropertiesFromFormPost {
    my $self = shift;
    my $session = $self->session;
    $self->next::method;
    my $form    = $session->form;
    ##Handle old data first, to avoid iterating across a newly added photo.
    my $photoData      = $self->getPhotoData;
    my $numberOfPhotos = scalar @{ $photoData };
    ##Post process photo data here.
    PHOTO: foreach my $photoIndex (1..$numberOfPhotos) {
        ##TODO: Deletion check and storage cleanup
        my $storageId = $photoData->[$photoIndex-1]->{storageId};
        if ($form->process('deletePhoto'.$photoIndex, 'yesNo')) {
            my $storage = WebGUI::Storage->get($session, $storageId);
            $storage->delete if $storage;
            splice @{ $photoData }, $photoIndex-1, 1;
            next PHOTO;
        }
        my $newPhoto = {
            storageId => $form->process('photo'     .$photoIndex, 'image', $storageId),
            caption   => $form->process('imgCaption'.$photoIndex, 'text'),
            alt       => $form->process('imgAlt'    .$photoIndex, 'text'),
            title     => $form->process('imgTitle'  .$photoIndex, 'text'),
            byLine    => $form->process('imgByline' .$photoIndex, 'text'),
            url       => $form->process('imgUrl'    .$photoIndex, 'url' ),
        };
        splice @{ $photoData }, $photoIndex-1, 1, $newPhoto;
    }
    my $newStorage = $form->process('newPhoto', 'image');
    if ($newStorage) {
        push @{ $photoData }, {
            caption   => $form->process('newImgCaption', 'text'),
            alt       => $form->process('newImgAlt',     'text'),
            title     => $form->process('newImgTitle',   'text'),
            byLine    => $form->process('newImgByline',  'text'),
            url       => $form->process('newImgUrl',     'url'),
            storageId => $newStorage,
        };
    }
    $self->setPhotoData($photoData);
}


#-------------------------------------------------------------------

=head2 purge ( )

Cleaning up all storage objects in all revisions.

=cut

sub purge {
    my $self = shift;
    ##Delete all storage locations from all revisions of the Asset
    my $sth = $self->session->db->read("select photo from Story where assetId=?",[$self->getId]);
    STORAGE: while (my ($json) = $sth->array) {
        my $photos = from_json($json);
        PHOTO: foreach my $photo (@{ $photos }) {
            next PHOTO unless $photo->{storageId};
            my $storage = WebGUI::Storage->get($self->session,$photo->{storageId});
            $storage->delete if $storage;
        }
	}
    $sth->finish;
    return $self->next::method;
}

#-------------------------------------------------------------------

=head2 purgeRevision

Remove the storage locations for this revision of the Asset.

=cut

sub purgeRevision {
	my $self    = shift;
    my $session = $self->session;
    foreach my $photo ( @{ $self->getPhotoData} ) {
        my $storage = WebGUI::Storage->get($session, $self-$photo->{storageId});
        $storage->delete if $storage;
    }
	return $self->next::method;
}

#-------------------------------------------------------------------

=head2 setPhotoData ( $perlStructure )

Update the JSON stored in the object from its perl equivalent, and update the database
as well via update.  This deletes the cached copy of the equivalent perl structure.

=head3 $perlStructure

This should be an array of hashes.  Photos will be in the order uploaded.
The values in the hash will be metadata about the Photo, and the storageId
that holds the image.  Each storageId will hold only 1 file.

=over 4

=item *

caption

=item *

byLine

=item *

alt

=item *

title

=item *

url

=item *

storageId

=back

subhash keys can be empty, or missing altogether.  Shoot, you can really put anything you
want in there as there's no valid content checking.

=cut

sub setPhotoData {
	my $self      = shift;
    my $photoData = shift || [];
    ##Convert to JSON
    my $photo     = to_json($photoData);
    ##Update the db.
    $self->update({photo => $photo});
    delete $self->{_photoData};
    return;
}

#-------------------------------------------------------------------

=head2 setSize ( fileSize )

Set the size of this asset by including all the files in its storage
location. C<fileSize> is an integer of additional bytes to include in
the asset size.

=cut

sub setSize {
    my $self        = shift;
    my $fileSize    = shift || 0;
    my $session     = $self->session;
    PHOTO: foreach my $photo (@{ $self->getPhotoData }) {
        my $storage     = WebGUI::Storage->get($session, $photo->{storageId});
        next PHOTO unless defined $storage;
        foreach my $file (@{$storage->getFiles}) {
            $fileSize += $storage->getFileSize($file);
        }
    }
    return $self->next::method($fileSize);
}

#-------------------------------------------------------------------

=head2 topic ( $topicAsset )

Tells the Story that it is being viewed from a Topic, and to behave
accordingly.  Returns a StoryTopic asset if set.

=head3 $topicAsset

The topic that is displaying this Story.

=cut

sub topic {
    my $self    = shift;
    my $topic    = shift;
    if (defined $topic) {
        $self->{_topic} = $topic;
    }
    return $self->{_topic};
}

#-------------------------------------------------------------------

=head2 update

Extend the superclass to make sure that the asset always stays hidden from navigation.

=cut

sub update {
    my $self   = shift;
    my $properties = shift;
    return $self->next::method({%$properties, isHidden => 1});
}

#-------------------------------------------------------------------

=head2 validParent

Make sure that the current session asset is a StoryArchive for pasting and adding checks.

This is a class method.

=cut

sub validParent {
    my $class   = shift;
    my $session = shift;
    return $session->asset && $session->asset->isa('WebGUI::Asset::Wobject::StoryArchive');
}

#-------------------------------------------------------------------

=head2 view ( )

method called by the container www_view method. 

=cut

##Keyword cloud generated by WebGUI::Keyword

sub view {
    my $self    = shift;
    my $session = $self->session;    
    my $var = $self->viewTemplateVariables();
    return $self->processTemplate($var,undef, $self->{_viewTemplate});
}

#-------------------------------------------------------------------

=head2 viewTemplateVars ( $var )

Add template variables to the existing template variables.  This includes asset level variables.

=head3 $var

Template variables will be added onto this hash ref.

=cut

sub viewTemplateVariables {
    my ($self)  = @_;
    my $session = $self->session;    
    my $archive = $self->getArchive;
    my $var     = $self->get;

    if ($var->{highlights}) {
        my @highlights = split "\n+", $var->{highlights};
        foreach my $highlight (@highlights) {
            push @{ $var->{highlights_loop} }, { highlight => $highlight };
        }
    }

    my $key = WebGUI::Keyword->new($session);
    my $keywords = $key->getKeywordsForAsset( { asArrayRef => 1, asset => $self  });
    $var->{keyword_loop} = [];
    foreach my $keyword (@{ $keywords }) {
        push @{ $var->{keyword_loop} }, {
            keyword => $keyword,
            url     => $archive->getUrl("func=view;keywords=".$session->url->escape($keyword)),
        };
    }
    $var->{updatedTime}      = $self->formatDuration();
    $var->{updatedTimeEpoch} = $self->get('revisionDate');

    $var->{crumb_loop}       = $self->getCrumbTrail();
    my $photoData = $self->getPhotoData;
    $var->{photo_loop}       = [];
    my $photoCounter = 0;
    PHOTO: foreach my $photo (@{ $photoData }) {
        next PHOTO unless $photo->{storageId};
        my $storage  = WebGUI::Storage->get($session, $photo->{storageId});
        my $file = $storage->getFiles->[0];
        next PHOTO unless $file;
        my $imageUrl = $storage->getUrl($file);
        push @{ $var->{photo_loop} }, {
            imageUrl     => $imageUrl,
            imageCaption => $photo->{caption},
            imageByline  => $photo->{byLine},
            imageAlt     => $photo->{alt},
            imageTitle   => $photo->{title},
            imageLink    => $photo->{url},
        };
        ++$photoCounter;
    }
    $var->{hasPhotos}   = $photoCounter;
    $var->{singlePhoto} = $photoCounter == 1;
    $var->{canEdit}     = $self->canEdit;
    return $var;
}


#-------------------------------------------------------------------

=head2 www_edit ( )

Web facing method which is the default edit page.  Unless the method needs
special handling or formatting, it does not need to be included in
the module.

Overridden because the standard, autogenerated form is not used.

=cut

sub www_edit {
    my $self = shift;
    my $session = $self->session;
    return $session->privilege->insufficient() unless $self->canEdit;
    return $session->privilege->locked() unless $self->canEditIfLocked;
    return $self->getArchive->processStyle($self->getEditForm);
}

#-------------------------------------------------------------------

=head2 www_showConfirmation ( )

Shows a confirmation message letting the user know their page has been submitted.

=cut

sub www_showConfirmation {
    my $self = shift;
    my $i18n = WebGUI::International->new($self->session, 'Asset_Story');
    return $self->getArchive->processStyle('<p>'.$i18n->get('story received').'</p><p><a href="'.$self->getArchive->getUrl.'">'.$i18n->get('493','WebGUI').'</a></p>');
}

#-------------------------------------------------------------------

=head2 www_view

Override www_view from asset because Stories inherit a style template from
the Story Archive that contains them.

=cut

sub www_view {
	my $self = shift;
	return $self->session->privilege->noAccess unless $self->canView;
	$self->session->http->sendHeader;
	$self->prepareView;
	return $self->getArchive->processStyle($self->view);
}


1;

#vim:ft=perl
