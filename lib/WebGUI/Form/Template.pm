package WebGUI::Form::Template;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2005 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Form::SelectBox';
use WebGUI::Asset::Template;
use WebGUI::Icon;
use WebGUI::International;
use WebGUI::Session;
use WebGUI::URL;

=head1 NAME

Package WebGUI::Form::Template

=head1 DESCRIPTION

Creates a template chooser control.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::SelectBox.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the super class for additional details.

=head3 additionalTerms

The following additional parameters have been added via this sub class.

=head4 name

The identifier for this field. Defaults to "templateId".

=head4 namespace        
                
The namespace for the list of templates to return. If this is omitted, all templates will be displayed.
                
=head4 label

A text label that will be displayed if toHtmlWithWrapper() is called. Defaults to getName().

=cut

sub definition {
	my $class = shift;
	my $definition = shift || [];
	push(@{$definition}, {
		formName=>{
			defaultValue=>WebGUI::International::get("assetName","Asset_Template")
			},
		label=>{
			defaultValue=>WebGUI::International::get("assetName","Asset_Template")
			},
		name=>{
			defaultValue=>"templateId"
			},
		namespace=>{
			defaultValue=>undef
			},
		});
	return $class->SUPER::definition($definition);
}

#-------------------------------------------------------------------

=head2 toHtml ( )

Renders a template picker control.

=cut

sub toHtml {
	my $self = shift;
        my $templateList = WebGUI::Asset::Template->getList($self->get("namespace"));
        #Remove entries from template list that the user does not have permission to view.
        for my $assetId ( keys %{$templateList} ) {
          	my $asset = WebGUI::Asset::Template->new($assetId);
          	if (!$asset->canView($self->session->user->profileField("userId"))) {
            		delete $templateList->{$assetId};
          	}
        }
	$self->get("options") = $templateList;
	$self->setManageIcons();
	return $self->SUPER::toHtml();
}

#-------------------------------------------------------------------

=head2 toHtmlWithWrapper ( )

Renders the form field to HTML as a table row complete with labels, subtext, hoverhelp, etc. Also adds manage and edit icons next to the field if the current user is in the admins group.

=cut

sub toHtmlWithWrapper {
	my $self = shift;
	$self->setManageIcons();
	return $self->SUPER::toHtmlWithWrapper;
}

#-------------------------------------------------------------------

=head2 setManageIcons ( )

Adds code to the extras field of the form so that buttons for managing or
editing the template show up if the user is allowed to do that.

=cut

sub setManageIcons {
	my $self = shift;
	my $template = WebGUI::Asset::Template->new($self->get("value"));
        if (defined $template && $template->canEdit) {
                my $returnUrl;
                if (exists $self->session->asset) {
                        $returnUrl = ";proceed=goBackToPage;returnUrl=".$self->session->url->escape($self->session->asset->getUrl);
                }
                my $buttons = editIcon("func=edit".$returnUrl,$template->get("url"));
                $buttons .= manageIcon("func=manageAssets",$template->getParent->get("url"));
		$self->get("subtext") = $buttons . $self->get("subtext");
	}
}

1;
