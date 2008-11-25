package WebGUI::Asset::File;

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
use base 'WebGUI::Asset';
use Carp;
use WebGUI::Cache;
use WebGUI::Storage;
use WebGUI::SQL;
use WebGUI::Utility;


=head1 NAME

Package WebGUI::Asset::File

=head1 DESCRIPTION

Provides a mechanism to upload files to WebGUI.

=head1 SYNOPSIS

use WebGUI::Asset::File;


=head1 METHODS

These methods are available from this class:

=cut



#-------------------------------------------------------------------

=head2 addRevision

Override the default method in order to deal with attachments.

=cut

sub addRevision {
    my $self        = shift;
    my $newSelf = $self->SUPER::addRevision(@_);

    if ($newSelf->get("storageId") && $newSelf->get("storageId") eq $self->get('storageId')) {
        my $newStorage = $self->getStorageClass->get($self->session,$self->get("storageId"))->copy;
        $newSelf->update({storageId => $newStorage->getId});
    }

    return $newSelf;
}

#-------------------------------------------------------------------

=head2 applyConstraints ( options )

Enforce certain things when new files are uploaded.

=head3 options

A hash reference of optional parameters. None at this time.

=cut

sub applyConstraints {
    my $self = shift;
	$self->getStorageLocation->setPrivileges($self->get('ownerUserId'), $self->get('groupIdView'), $self->get('groupIdEdit'));
    $self->setSize;
}


#-------------------------------------------------------------------

=head2 definition ( definition )

Defines the properties of this asset.

=head3 definition

A hash reference passed in from a subclass definition.

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session,"Asset_File");
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		tableName=>'FileAsset',
		className=>'WebGUI::Asset::File',
		properties=>{
			cacheTimeout => {
				tab => "display",
				fieldType => "interval",
				defaultValue => 3600,
				uiLevel => 8,
				label => $i18n->get("cache timeout"),
				hoverHelp => $i18n->get("cache timeout help")
				},
			filename=>{
				noFormPost=>1,
				fieldType=>'hidden',
				defaultValue=>undef
			},
			storageId=>{
				noFormPost=>1,
				fieldType=>'hidden',
				defaultValue=>undef
			},
			templateId=>{
				fieldType=>'template',
				defaultValue=>'PBtmpl0000000000000024'
			}
		}
	});
	return $class->SUPER::definition($session, $definition);
}


#-------------------------------------------------------------------

sub duplicate {
	my $self = shift;
	my $newAsset = $self->SUPER::duplicate(@_);
	my $newStorage = $self->getStorageLocation->copy;
	$newAsset->update({storageId=>$newStorage->getId});
	return $newAsset;
}


#-------------------------------------------------------------------

=head2 exportAssetData ( )

See WebGUI::AssetPackage::exportAssetData() for details.

=cut

sub exportAssetData {
	my $self = shift;
	my $data = $self->SUPER::exportAssetData;
	push(@{$data->{storage}}, $self->get("storageId")) if ($self->get("storageId") ne "");
	return $data;
}


#-------------------------------------------------------------------

=head2 getEditForm ( )

Returns the TabForm object that will be used in generating the edit page for this asset.

=cut

sub getEditForm {
    my $self        = shift;
    my $tabform     = $self->SUPER::getEditForm();
    my $i18n        = WebGUI::International->new($self->session, 'Asset_File');

    $tabform->getTab("properties")->raw( 
        '<tr><td>'.$i18n->get('new file').'<td colspan="2">'
        . $self->getEditFormUploadControl 
        . '</td></tr>'
    );

    return $tabform;
}

#----------------------------------------------------------------------------

=head2 getEditFormUploadControl

Returns the HTML to render the upload box and link to delete the existing 
file, if necessary.

=cut

sub getEditFormUploadControl {
    my $self        = shift;
    my $session     = $self->session;
    my $i18n        = WebGUI::International->new($session, 'Asset_File');
    my $html        = '';

    if ($self->get("filename") ne "") {
        $html .= WebGUI::Form::readOnly( $session, {
            label       => $i18n->get('current file'),
            hoverHelp   => $i18n->get('current file description', 'Asset_File'),
            value       => '<p style="display:inline;vertical-align:middle;"><a href="'.$self->getFileUrl.'"><img src="'.$self->getFileIconUrl.'" alt="'.$self->get("filename").'" style="border-style:none;vertical-align:middle;" /> '.$self->get("filename").'</a></p>'
        });
    }

    # Control to upload a new file
    $html .= WebGUI::Form::file( $session, {
        name        => 'newFile',
        label       => $i18n->get('new file'),
        hoverHelp   => $i18n->get('new file description'),
    });

    return $html;
}


#-------------------------------------------------------------------
sub getFileUrl {
	my $self = shift;
	#return $self->get("url");
	return $self->getStorageLocation->getUrl($self->get("filename"));
}

#-------------------------------------------------------------------
sub getFileIconUrl {
	my $self = shift;
        return undef unless $self->get("filename"); ## Why do I have to do this when creating new Files?
	return $self->getStorageLocation->getFileIconUrl($self->get("filename"));
}



#-------------------------------------------------------------------
sub getIcon {
	my $self = shift;
	my $small = shift;
	if ($small && $self->get("dummy")) {
		return $self->session->url->extras('assets/small/file.gif');
	} elsif ($small) {
		return $self->getFileIconUrl;	
	}
	return $self->session->url->extras('assets/file.gif');
}


#----------------------------------------------------------------------------

=head2 getStorageClass

Get the full classname of the WebGUI::Storage we should use for this asset.

=cut

sub getStorageClass {
    return 'WebGUI::Storage';
}

#-------------------------------------------------------------------

=head2 getStorageFromPost

Get the storage location created by the form post.

=cut

sub getStorageFromPost {
    my $self      = shift;
    my $storageId = shift;
    my $fileStorageId = WebGUI::Form::File->new($self->session, {name => 'newFile', value=>$storageId })->getValue;
    $self->session->errorHandler->info( "File Storage Id: $fileStorageId" );
    return $self->getStorageClass->get($self->session, $fileStorageId);
}


#-------------------------------------------------------------------

sub getStorageLocation {
	my $self = shift;
	unless (exists $self->{_storageLocation}) {
		$self->setStorageLocation;
	}
	return $self->{_storageLocation};
}


#-------------------------------------------------------------------

=head2 indexContent ( )

Indexing the content of the attachment. See WebGUI::Asset::indexContent() for additonal details. 

=cut

sub indexContent {
	my $self = shift;
	my $indexer = $self->SUPER::indexContent;
	$indexer->addFile($self->getStorageLocation->getPath($self->get("filename")));
}


#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
	$template->prepare($self->getMetaDataAsTemplateVariables);
	$self->{_viewTemplate} = $template;
}


#-------------------------------------------------------------------
sub processPropertiesFromFormPost {
    my $self    = shift;
    my $session = $self->session;

    my $errors  = $self->SUPER::processPropertiesFromFormPost || [];
    return $errors if @$errors;

    if (my $storageId = $session->form->get('newFile','File')) {
        $session->errorHandler->info("Got a new file for asset " . $self->getId);
        my $storage     = $self->getStorageClass->get( $session, $storageId);
        my $filePath    = $storage->getPath( $storage->getFiles->[0] );
        $self->setFile( $filePath );
        $storage->delete;
    }
    else {
        $self->applyConstraints;
    }

    return undef;
}


#-------------------------------------------------------------------

sub purge {
	my $self = shift;
	my $sth = $self->session->db->read("select storageId from FileAsset where assetId=".$self->session->db->quote($self->getId));
	while (my ($storageId) = $sth->array) {
		$self->getStorageClass->get($self->session,$storageId)->delete;
	}
	$sth->finish;
	return $self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 purgeCache ( )

See WebGUI::Asset::purgeCache() for details.

=cut

sub purgeCache {
	my $self = shift;
	WebGUI::Cache->new($self->session,"view_".$self->getId)->delete;
	$self->SUPER::purgeCache;
}

#-------------------------------------------------------------------

sub purgeRevision {
	my $self = shift;
	$self->getStorageLocation->delete;
	return $self->SUPER::purgeRevision;
}

#----------------------------------------------------------------------------

=head2 setFile ( [pathtofile] )

Tells the asset to do all the postprocessing on the file (setting privs, thubnails, or whatever).

=head3 pathtofile

If specified will copy a new file into the storage location from this path and delete any existing file.


=cut

sub setFile {
    my $self        = shift;
    my $filename    = shift;

	if ($filename) {
	    my $storage     = $self->getStorageLocation;
		# Clear the old file if any
		$storage->clear;
	
		$storage->addFileFromFilesystem($filename) 
			|| croak "Couldn't setFile: " . join(", ",@{ $storage->getErrors });
			# NOTE: We should not croak here, the WebGUI::Storage should croak for us.
			
	}

    $self->updatePropertiesFromStorage;
    $self->applyConstraints;
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
    my $storage     = $self->getStorageLocation;
    if (defined $storage) {	
        foreach my $file (@{$storage->getFiles}) {
            $fileSize += $storage->getFileSize($file);
        }
    }
    return $self->SUPER::setSize($fileSize);
}

#-------------------------------------------------------------------

sub setStorageLocation {
    my $self    = shift;
    my $storage = shift;
    if (defined $storage) {
        $self->{_storageLocation} = $storage;
    }
    elsif ($self->get("storageId") eq "") {
        $self->{_storageLocation} = $self->getStorageClass->create($self->session);
        $self->update({storageId=>$self->{_storageLocation}->getId});
    }
    else {
        $self->{_storageLocation} = $self->getStorageClass->get($self->session,$self->get("storageId"));
    }
}

#-------------------------------------------------------------------

=head2 update

We override the update method from WebGUI::Asset in order to handle file system privileges.

=cut

sub update {
	my $self = shift;
	my %before = (
		owner => $self->get("ownerUserId"),
		view => $self->get("groupIdView"),
		edit => $self->get("groupIdEdit"),
		storageId => $self->get('storageId'),
	);
	$self->SUPER::update(@_);
	##update may have entered a new storageId.  Reset the cached one just in case.
	if ($self->get("storageId") ne $before{storageId}) {
		$self->setStorageLocation;
	}
	if ($self->get("ownerUserId") ne $before{owner} || $self->get("groupIdEdit") ne $before{edit} || $self->get("groupIdView") ne $before{view}) {
		$self->getStorageLocation->setPrivileges($self->get("ownerUserId"),$self->get("groupIdView"),$self->get("groupIdEdit"));
	}
}

#----------------------------------------------------------------------------

=head2 updatePropertiesFromStorage ( )

Updates the asset properties from the file tracked by this asset. Should be
called every time the file is changed to ensure the correct filename is
in the asset properties.

=cut

sub updatePropertiesFromStorage {
    my $self        = shift;
    my $storage     = $self->getStorageLocation; 
    my $filename    = $storage->getFiles->[0];
    $self->session->errorHandler->info("Updating file asset filename to $filename");
    $self->update({
        filename        => $filename,
    });
    return undef;
}

#-------------------------------------------------------------------
sub view {
	my $self = shift;
	if (!$self->session->var->isAdminOn && $self->get("cacheTimeout") > 10) {
		my $out = WebGUI::Cache->new($self->session,"view_".$self->getId)->get;
		return $out if $out;
	}
	my %var = %{$self->get};
	$var{controls} = $self->getToolbar;
	$var{fileUrl} = $self->getFileUrl;
	$var{fileIcon} = $self->getFileIconUrl;
	$var{fileSize} = formatBytes($self->get("assetSize"));
       	my $out = $self->processTemplate(\%var,undef,$self->{_viewTemplate});
	if (!$self->session->var->isAdminOn && $self->get("cacheTimeout") > 10) {
		WebGUI::Cache->new($self->session,"view_".$self->getId)->set($out,$self->get("cacheTimeout"));
	}
       	return $out;
}


#-------------------------------------------------------------------
sub www_edit {
	my $self = shift;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	return $self->session->privilege->locked() unless $self->canEditIfLocked;
	my $i18n = WebGUI::International->new($self->session);
	my $tabform = $self->getEditForm;
	$tabform->getTab("display")->template(
		-value=>$self->getValue("templateId"),
		-hoverHelp=>$i18n->get('file template description','Asset_File'),
		-namespace=>"FileAsset"
	);
	return $self->getAdminConsole->render($tabform->print,$self->addEditLabel);
}

#-------------------------------------------------------------------

# setStreamedFile and setRedirect do not interact well with the
# exporter.  We have a separate method for this now.
sub exportHtml_view {
	my $self = shift;
	my $path = $self->getStorageLocation->getPath($self->get('filename'));
    open my $fh, '<:raw', $path or return "";
    while ( read $fh, my $block, 16384 ) {
        $self->session->output->print($block, 1);
    }
    close $fh;
    return 'chunked';
}

#--------------------------------------------------------------------
sub www_view {
	my $self = shift;
	return $self->session->privilege->noAccess() unless $self->canView;
	
	# Check to make sure it's not in the trash or some other weird place
	if ($self->get("state") ne "published") {
		my $i18n = WebGUI::International->new($self->session,'Asset_File');
		$self->session->http->setStatus("404");
		return sprintf($i18n->get("file not found"), $self->getUrl());
	}

    $self->session->http->setRedirect($self->getFileUrl);
    $self->session->http->setStreamedFile($self->getStorageLocation->getPath($self->get("filename")));
    $self->session->http->sendHeader;
    return 'chunked';
}


1;
