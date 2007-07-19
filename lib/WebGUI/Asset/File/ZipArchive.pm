package WebGUI::Asset::File::ZipArchive;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2007 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Asset::File';
use WebGUI::HTMLForm;
use WebGUI::SQL;
use WebGUI::Utility;

use Archive::Tar;
use Archive::Zip;



=head1 NAME

Package WebGUI::Asset::ZipArchive

=head1 DESCRIPTION

Provides a mechanism to upload and automatically extract a zip archive
containing related items.  An asset setting will set the launch point of the archive.

=head1 SYNOPSIS

use WebGUI::Asset::ZipArchive;

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------
sub unzip {
	my $self = shift;
	my $storage = shift;
	my $filename = shift;
   
	my $filepath = $storage->getPath();
	chdir $filepath;
   
	my $i18n = WebGUI::International->new($self->session,"Asset_ZipArchive");
	if ($filename =~ m/\.zip/i) {
		my $zip = Archive::Zip->new();
		unless ($zip->read($filename) == $zip->AZ_OK){
			$self->session->errorHandler->warn($i18n->get("zip_error"));
			return 0;
		}
		$zip->extractTree();  
	} elsif ($filename =~ m/\.tar/i) {
		Archive::Tar->extract_archive($filepath.'/'.$filename,1);
		if (Archive::Tar->error) {
			$self->session->errorHandler->warn(Archive::Tar->error);
			return 0;
		}
	} else {
		$self->session->errorHandler->warn($i18n->get("bad_archive"));
	}

	return 1;
}

#-------------------------------------------------------------------

=head2 addRevision ( )

   This method exists for demonstration purposes only.  The superclass
   handles revisions to ZipArchive Assets.

=cut

sub addRevision {
	my $self = shift;
	my $newSelf = $self->SUPER::addRevision(@_);
	return $newSelf;
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
	my $i18n = WebGUI::International->new($session,"Asset_ZipArchive");
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		tableName=>'ZipArchiveAsset',
		autoGenerateForms=>1,
		icon=>'ziparchive.gif',
		className=>'WebGUI::Asset::File::ZipArchive',
		properties=>{
			showPage=>{
				tab=>"properties",
				label=>$i18n->get('show page'),
				hoverHelp=>$i18n->get('show page description'),
				fieldType=>'text',
				defaultValue=>'index.html'
			},
			templateId=>{
				tab=>"display",
				label=>$i18n->get('template label'),
				namespace=>"ZipArchiveAsset",
				fieldType=>'template',
				defaultValue=>''
			},
		}
	});
	return $class->SUPER::definition($session,$definition);
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

=head2 processPropertiesFromFormPost ( )

Used to process properties from the form posted.  In this asset, we use
this method to deflate the zip file into the proper folder

=cut

sub processPropertiesFromFormPost {
	my $self = shift;
	#File should be saved here by the superclass
	$self->SUPER::processPropertiesFromFormPost;
	my $storage = $self->getStorageLocation();
	
	my $file = $self->get("filename");
	
	#return unless $file;
	my $i18n = WebGUI::International->new($self->session, 'Asset_ZipArchive');
	unless ($self->session->form->process("showPage")) {
		$storage->delete;
		$self->session->db->write("update FileAsset set filename=NULL where assetId=".$self->session->db->quote($self->getId));
		$self->session->scratch->set("za_error",$i18n->get("za_show_error"));
		return;
	}
	
	unless ($file =~ m/\.tar/i || $file =~ m/\.zip/i) {
		$storage->delete;
		$self->session->db->write("update FileAsset set filename=NULL where assetId=".$self->session->db->quote($self->getId));
		$self->session->scratch->set("za_error",$i18n->get("za_error"));
		return;
	}
	
	unless ($self->unzip($storage,$self->get("filename"))) {
		$self->session->errorHandler->warn($i18n->get("unzip_error"));
	}
}


#-------------------------------------------------------------------

=head2 view ( )

Method called by the container www_view method.  In this asset, this is
used to show the file to administrators.

=cut

sub view {
	my $self = shift;
	if (!$self->session->var->isAdminOn && $self->get("cacheTimeout") > 10) {
		my $out = WebGUI::Cache->new($self->session,"view_".$self->getId)->get;
		return $out if $out;
	}
	my %var = %{$self->get};
	#$self->session->errorHandler->warn($self->getId);
	$var{controls} = $self->getToolbar;
	if($self->session->scratch->get("za_error")) {
	   $var{error} = $self->session->scratch->get("za_error");
	}
	$self->session->scratch->delete("za_error");
	my $storage = $self->getStorageLocation;
	if($self->get("filename") ne "") {
	   $var{fileUrl} = $storage->getUrl($self->get("showPage"));
	   $var{fileIcon} = $storage->getFileIconUrl($self->get("showPage"));
	}
	unless($self->get("showPage")) {
	   $var{pageError} = "true";
	}
	my $i18n = WebGUI::International->new($self->session,"Asset_ZipArchive");
	$var{noInitialPage} = $i18n->get('noInitialPage');
	$var{noFileSpecified} = $i18n->get('noFileSpecified');
       	my $out = $self->processTemplate(\%var,undef,$self->{_viewTemplate});
	if (!$self->session->var->isAdminOn && $self->get("cacheTimeout") > 10) {
		WebGUI::Cache->new($self->session,"view_".$self->getId)->set($out,$self->get("cacheTimeout"));
	}
       	return $out;
}


#-------------------------------------------------------------------

=head2 www_edit ( )

Web facing method which is the default edit page

=cut

sub www_edit {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;
    $self->getAdminConsole->setHelp("zip archive add/edit", "Asset_ZipArchive");
	my $i18n = WebGUI::International->new($self->session, 'Asset_Wobject');
	my $addEdit = ($self->session->form->process("func") eq 'add') ? $i18n->get('add') : $i18n->get('edit');
    return $self->getAdminConsole->render($self->getEditForm->print,$addEdit.' '.$self->getName);
}

#-------------------------------------------------------------------

=head2 www_view ( )

Web facing method which is the default view page.  This method does a 
302 redirect to the "showPage" file in the storage location.

=cut

sub www_view {
	my $self = shift;
	return $self->session->privilege->noAccess() unless $self->canView;
	if ($self->session->var->isAdminOn) {
		return $self->session->asset($self->getContainer)->www_view;
	}
	$self->session->http->setRedirect($self->getFileUrl($self->getValue("showPage")));
	return "1";
}


1;

