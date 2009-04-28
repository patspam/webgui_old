package WebGUI::Asset::Wobject::StoryTopic;

$VERSION = "1.0.0";

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use Tie::IxHash;
use WebGUI::International;
use WebGUI::Utility;
use WebGUI::Asset::Story;
use Class::C3;
use base qw/WebGUI::AssetAspect::RssFeed WebGUI::Asset::Wobject/;

use constant DATE_FORMAT => '%c_%D_%y';

#-------------------------------------------------------------------

=head2 definition ( )

defines wobject properties for New Wobject instances.  You absolutely need 
this method in your new Wobjects.  If you choose to "autoGenerateForms", the
getEditForm method is unnecessary/redundant/useless.  

=cut

sub definition {
    my $class = shift;
    my $session = shift;
    my $definition = shift;
    my $i18n = WebGUI::International->new($session, 'Asset_StoryTopic');
    my %properties;
    tie %properties, 'Tie::IxHash';
    %properties = (
        storiesPer => {
            tab          => 'display',  
            fieldType    => 'integer',  
            label        => $i18n->get('stories per topic'),
            hoverHelp    => $i18n->get('stories per topic help'),
            defaultValue => 15,
        },
        storiesShort => {
            tab          => 'display',  
            fieldType    => 'integer',  
            label        => $i18n->get('stories short'),
            hoverHelp    => $i18n->get('stories short help'),
            defaultValue => 5,
        },
        templateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('template'),
            hoverHelp    => $i18n->get('template help'),
            filter       => 'fixId',
            namespace    => 'StoryTopic',
            defaultValue => 'A16v-YjWAShXWvSACsraeg',
        },
        storyTemplateId => {
            tab          => 'display',
            fieldType    => 'template',
            label        => $i18n->get('story template'),
            hoverHelp    => $i18n->get('story template help'),
            filter       => 'fixId',
            namespace    => 'Story',
            defaultValue => 'TbDcVLbbznPi0I0rxQf2CQ',
        },
    );
    push(@{$definition}, {
        assetName=>$i18n->get('assetName'),
        icon=>'assets.gif',
        autoGenerateForms=>1,
        tableName=>'StoryTopic',
        className=>'WebGUI::Asset::Wobject::StoryTopic',
        properties=>\%properties,
    });
    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2 getRssFeedItems ( )

Returns an arrayref of hashrefs, containing information on stories
for generating an RSS and Atom feeds.

=cut

sub getRssFeedItems {
    my ($self)   = @_;
    my $session  = $self->session;    
    my $wordList = WebGUI::Keyword::string2list($self->get('keywords'));
    my $key      = WebGUI::Keyword->new($session);
    my $storyIds = $key->getMatchingAssets({
        keywords     => $wordList,
        isa          => 'WebGUI::Asset::Story',
        rowsPerPage  => $self->get('storiesPer'),
    });
    my $storyData = [];
    STORY: foreach my $storyId (@{ $storyIds }) {
        my $story = WebGUI::Asset->newByDynamicClass($session, $storyId);
        next STORY unless $story;
        push @{ $storyData }, $story->getRssData;
    }
    return $storyData;
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
    my $self = shift;
    $self->SUPER::prepareView();
    my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
    $template->prepare;
    $self->{_viewTemplate} = $template;
}


#-------------------------------------------------------------------

=head2 view ( )

Method called by the www_view method.  Returns a processed template
to be displayed within the page style.  

=cut

sub view {
    my $self = shift;
    my $session = $self->session;    

    #This automatically creates template variables for all of your wobject's properties.
    my $var = $self->viewTemplateVariables;

    return $self->processTemplate($var, undef, $self->{_viewTemplate});
}

#-------------------------------------------------------------------

=head2 viewTemplateVars ( )

Make template variables for the view template.

=cut

sub viewTemplateVariables {
    my ($self)          = @_;
    my $session         = $self->session;    
    my $exporting       = $session->scratch->get('isExporting');
    my $numberOfStories = $self->{_standAlone}
                        ? $self->get('storiesPer')
                        : $self->get('storiesShort');
    my $var = $self->get();
    my $wordList = WebGUI::Keyword::string2list($self->get('keywords'));
    my $key      = WebGUI::Keyword->new($session);
    my $p        = $key->getMatchingAssets({
        keywords     => $wordList,
        isa          => 'WebGUI::Asset::Story',
        usePaginator => 1,
        rowsPerPage  => $numberOfStories,
    });
    my $storyIds = $p->getPageData();
    $var->{story_loop} = [];
    ##Only build objects for the assets that we need
    STORY: foreach my $storyId (@{ $storyIds }) {
        my $story = WebGUI::Asset->new($session, $storyId->{assetId}, $storyId->{className}, $storyId->{revisionDate});
        next STORY unless $story;
        push @{$var->{story_loop}}, {
            url           => ( $exporting
                               ? $story->getUrl
                               : $session->url->append($self->getUrl, 'func=viewStory;assetId='.$storyId->{assetId}) ),
            title         => $story->getTitle,
            creationDate  => $story->get('creationDate'),
        }
    }

    if ($self->{_standAlone}) {
        my $topStoryData = $storyIds->[0];
        shift @{ $var->{story_loop} };
        ##Note, this could have saved from the loop above, but this looks more clean and encapsulated to me.
        my $topStory   = WebGUI::Asset->new($session, $topStoryData->{assetId}, $topStoryData->{className}, $topStoryData->{revisionDate});
        $var->{topStoryTitle}          = $topStory->getTitle;
        $var->{topStorySubtitle}       = $topStory->get('subtitle');
        $var->{topStoryUrl}            = $session->url->append($self->getUrl, 'func=viewStory;assetId='.$topStoryData->{assetId}),
        $var->{topStoryCreationDate}   = $topStory->get('creationDate');
        ##TODO: Photo variables
        my $photoData = $topStory->getPhotoData;
        PHOTO: foreach my $photo (@{ $photoData }) {
            next PHOTO unless $photo->{storageId};
            my $storage  = WebGUI::Storage->get($session, $photo->{storageId});
            my $file     = $storage->getFiles->[0];
            next PHOTO unless $file;
            my $imageUrl = $storage->getUrl($file);
            $var->{topStoryImageUrl}     = $imageUrl;
            $var->{topStoryImageCaption} = $photo->{caption};
            $var->{topStoryImageByline}  = $photo->{byLine};
            $var->{topStoryImageAlt}     = $photo->{alt};
            $var->{topStoryImageTitle}   = $photo->{title};
            $var->{topStoryImageLink}    = $photo->{url};
            last PHOTO;
        }
    }
    $var->{standAlone} = $self->{_standAlone};
    $var->{rssUrl}     = $self->getRssFeedUrl;
    $var->{atomUrl}    = $self->getAtomFeedUrl;

    return $var;
}

#-------------------------------------------------------------------

=head2 www_view ( )

Overside the method inherited from Wobject to set the mode so template
variables are set correctly in viewTemplateVars.

=cut


sub www_view {
    my $self = shift;
    $self->{_standAlone} = 1;
    return $self->SUPER::www_view;
}

#-------------------------------------------------------------------

=head2 www_viewStory ( )

Display a story, set in the form variable assetId

=cut


sub www_viewStory {
    my $self    = shift;
    my $session = $self->session;
    my $storyId = $session->form->get('assetId');
    my $story;
    if ($storyId) {
        $story = WebGUI::Asset->new($session, $storyId);
    }
    if (! $story) {
        my $notFound = WebGUI::Asset->getNotFound($session);
        $session->asset($notFound);
        return $notFound->www_view;
    }
    $story->topic($self);
    return $story->www_view;
}


1;
#vim:ft=perl
