package WebGUI::Asset::Template;

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
use base 'WebGUI::Asset';
use WebGUI::International;
use WebGUI::Asset::Template::HTMLTemplate;
use WebGUI::Utility;
use WebGUI::Form;
use WebGUI::Exception;
use Tie::IxHash;
use Clone qw/clone/;
use HTML::Packer;

=head1 NAME

Package WebGUI::Asset::Template

=head1 DESCRIPTION

Provides a mechanism to provide a templating system in WebGUI.

=head1 SYNOPSIS

use WebGUI::Asset::Template;


=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 definition ( session, definition )

Defines the properties of this asset.

=head3 session

A reference to an existing session.

=head3 definition

A hash reference passed in from a subclass definition.

=cut

sub definition {
    my $class       = shift;
	my $session     = shift;
    my $definition  = shift;
	my $i18n        = WebGUI::International->new($session,"Asset_Template");
    push @{$definition}, {
		assetName   => $i18n->get('assetName'),
		icon        => 'template.gif',
        tableName   => 'template',
        className   => 'WebGUI::Asset::Template',
        properties  => {
            template => {
                fieldType       => 'codearea',
                syntax          => "html",
                defaultValue    => undef,
                filter          => 'packTemplate',
            },
            isEditable => {
                noFormPost      => 1,
                fieldType       => 'hidden',
                defaultValue    => 1,
            },
            isDefault => {
                fieldType       => 'hidden',
                defaultValue    => 0,
            },
            showInForms => {
                fieldType       => 'yesNo',
                defaultValue    => 1,
            },
            parser => {
                noFormPost      => 1,
                fieldType       => 'selectBox',
                defaultValue    => [$session->config->get("defaultTemplateParser")],
            },	
            namespace => {
                fieldType       => 'combo',
                defaultValue    => undef,
            },
            templatePacked => {
                fieldType       => 'hidden',
                defaultValue    => undef,
                noFormPost      => 1,
            },
            usePacked => {
                fieldType       => 'yesNo',
                defaultValue    => 0,
            },
        },
    };
    return $class->SUPER::definition($session,$definition);
}

#-------------------------------------------------------------------

=head2 addAttachments ( attachments )

Adds attachments to this template.  Attachments is an arrayref of hashrefs,
where each hashref should have at least url, type, and sequence as keys.

=cut

sub addAttachments {
    my ($self, $attachments) = @_;

    my $db = $self->session->db;

    my $sql = q{
        INSERT INTO template_attachments
            (templateId, revisionDate, url, type, sequence)
        VALUES
            (?,          ?,            ?,   ?,    ?)
    };

    foreach my $a (@$attachments) {
        my @params = (
            $self->getId, 
            $self->get('revisionDate'),
            @{$a}{qw(url type sequence)}
        );
        $db->write($sql, \@params);
    }
}

#-------------------------------------------------------------------

=head2 addRevision ( )

Override the master addRevision to copy attachments

=cut

sub addRevision {
    my ( $self, $properties, @args ) = @_;
    my $asset = $self->SUPER::addRevision($properties, @args);
    delete $properties->{templatePacked};
    $asset->addAttachments($self->getAttachments);
    return $asset;
}

#-------------------------------------------------------------------

=head2 drawExtraHeadTags ( )

Override the master drawExtraHeadTags to prevent Style template from having
Extra Head Tags.

=cut

sub drawExtraHeadTags {
	my ($self, $params) = @_;
    if ($self->get('namespace') eq 'style') {
        my $i18n = WebGUI::International->new($self->session);
        return $i18n->get(881);
    }
    return $self->SUPER::drawExtraHeadTags($params);
}


#-------------------------------------------------------------------

=head2 duplicate

Subclass the duplicate method so that the isDefault flag is set to 0 on any
copy.

=cut

sub duplicate {
	my $self = shift;
	my $newTemplate = $self->SUPER::duplicate;
    $newTemplate->update({isDefault => 0});
    return $newTemplate;
}

#-------------------------------------------------------------------

=head2 exportAssetData (  )

Override to add attachments to package data

=cut

sub exportAssetData {
    my ( $self ) = @_;
    my $data    = $self->SUPER::exportAssetData;
    $data->{template_attachments} = $self->getAttachments;
    return $data;
}

#-------------------------------------------------------------------

=head2 getAttachments ( [type] )

Returns an arrayref of hashrefs representing all attachments for this template
of the specified type (link, bodyScript, headScript).

=head3 type

If defined, will limit the attachments to this type; e.g., passing
'stylesheet' will return only stylesheets.

=cut

sub getAttachments {
	my ( $self, $type ) = @_;
	my @params = ($self->getId, $self->get('revisionDate'));
	my $typeString;

	if ($type) {
		$typeString = 'AND type = ?';
		push(@params, $type);
	}

	my $sql = qq{
		SELECT 
			* 
		FROM 
			template_attachments 
		WHERE 
			templateId = ?
            AND revisionDate = ?
			$typeString
		ORDER BY
			type, sequence ASC
	};
	return $self->session->db->buildArrayRefOfHashRefs($sql, \@params);
}

#-------------------------------------------------------------------

=head2 getEditForm ( )

Returns the TabForm object that will be used in generating the edit page for this asset.

=cut

sub getEditForm {
	my $self = shift;
	my $tabform = $self->SUPER::getEditForm();
	my $i18n = WebGUI::International->new($self->session, 'Asset_Template');
	$tabform->hidden({
		name=>"returnUrl",
		value=>$self->session->form->get("returnUrl")
		});
	if ($self->getValue("namespace") eq "") {
		my $namespaces = $self->session->dbSlave->buildHashRef("select distinct(namespace) from template order by namespace");
		$tabform->getTab("properties")->combo(
			-name=>"namespace",
			-options=>$namespaces,
			-label=>$i18n->get('namespace'),
			-hoverHelp=>$i18n->get('namespace description'),
			-value=>[$self->session->form->get("namespace")] 
			);
	} else {
		$tabform->getTab("meta")->readOnly(
			-label=>$i18n->get('namespace'),
			-hoverHelp=>$i18n->get('namespace description'),
			-value=>$self->getValue("namespace")
			);	
		$tabform->getTab("meta")->hidden(
			-name=>"namespace",
			-value=>$self->getValue("namespace")
			);
	}
	$tabform->getTab("display")->yesNo(
		-name=>"showInForms",
		-value=>$self->getValue("showInForms"),
		-label=>$i18n->get('show in forms'),
		-hoverHelp=>$i18n->get('show in forms description'),
		);
	$tabform->getTab("properties")->codearea(
		-name=>"template",
		-label=>$i18n->get('assetName'),
		-hoverHelp=>$i18n->get('template description'),
		-syntax => "html",
		-value=>$self->getValue("template")
		);
    $tabform->getTab('properties')->yesNo(
        name        => "usePacked",
        label       => $i18n->get('usePacked label'),
        hoverHelp   => $i18n->get('usePacked description'),
        value       => $self->getValue("usePacked"),
    );
	if($self->session->config->get("templateParsers")){
		my @temparray = @{$self->session->config->get("templateParsers")};
		tie my %parsers, 'Tie::IxHash';
		while(my $a = shift @temparray){
			$parsers{$a} = $self->getParser($self->session, $a)->getName();
		}
		my $value = [$self->getValue("parser")];
		$value = \[$self->session->config->get("defaultTemplateParser")] if(!$self->getValue("parser"));
		$tabform->getTab("properties")->selectBox(
			-name=>"parser",
			-options=>\%parsers,
			-value=>$value,
			-label=>$i18n->get('parser'),
			-hoverHelp=>$i18n->get('parser description'),
			);
	}

    ### Template attachments
	my $session = $self->session;
	my @headers = map { '<th>' . $i18n->get("attachment header $_") . '</th>' } 
                      qw(index type url remove);

    tie my %attachmentTypeNames, 'Tie::IxHash' => (
        stylesheet => $i18n->get('css label'),
        headScript => $i18n->get('js head label'),
        bodyScript => $i18n->get('js body label'),
    );

	my $table = '<table id="attachmentDisplay">';
	$table .= "<thead><tr>@headers</tr></thead><tbody id='addAnchor'>";
	foreach my $a ( @{ $self->getAttachments } ) {
		my ($seq, $type, $url) = @{$a}{qw(sequence type url)};
        # escape macros in the url so they don't get processed
        $url =~ s/\^/&#94;/g;
		my $del = WebGUI::Form::checkbox(
			$session, { 
				name   => 'removeAttachment',
				value  => $url,
				extras => 'class="id"',
            }
        );
		my @data = (
			"<td class='index'>$seq</td>", 
			"<td class='type'>$type</td>", 
			"<td class='url'>$url</td>", 
			"<td>$del</td>",
		);
		$table .= "<tr class='existingAttachment'>@data</tr>";
	}
	$table .= '</tbody></table>';
	my $properties = $tabform->getTab('properties');
	my $label = $i18n->get('attachment display label');
	$properties->raw("<tr><td>$label</td><td>$table</td></tr>");

	my @data = map { "<td>$_</td>" } (
		WebGUI::Form::integer(
			$session, { size => '2', id => 'addBoxIndex' }
		),
		WebGUI::Form::selectBox(
			$session, { options => \%attachmentTypeNames, id => 'addBoxType' }
		),
		WebGUI::Form::text($session, { id => 'addBoxUrl', size => 40 }),
		WebGUI::Form::button(
			$session, { 
				value  => $i18n->get('attachment add button'), 
				extras => 'onclick="addClick()"' 
			}
		),
	);

	my ($style, $url) = $self->session->quick(qw(style url));
	$style->setScript($url->extras('yui/build/yahoo/yahoo-min.js'), {type => 'text/javascript'});
	$style->setScript($url->extras('yui/build/json/json-min.js'),   {type => 'text/javascript'});
	$style->setScript($url->extras('yui/build/dom/dom-min.js'),     {type => 'text/javascript'});

	pop(@headers);
	my $scriptUrl = $url->extras('templateAttachments.js');
	$table = "<table id='addBox'><tr>@headers</tr><tr>@data</tr></table>";
	$table .= qq(<script type="text/javascript" src="$scriptUrl"></script>);
	$label = $i18n->get('attachment add field label');
	$properties->raw("<tr><td>$label</td><td>$table</td></tr>");

	return $tabform;
}


#-------------------------------------------------------------------

=head2 getList ( session, namespace [,clause] )

Returns a hash reference containing template ids and template names of all the templates in the specified namespace.

NOTE: This is a class method.

=head3 session

A reference to the current session.

=head3 namespace

Specify the namespace to build the list for.  If no namespace is specified,
then an empty hash reference will be returned.

=head3 clause

An extra clause that can be used to further limit the list, such as "assetData.status='approved'

=cut

sub getList {
	my $class = shift;
	my $session = shift;
	my $namespace = shift;
    my $clause      = shift;
    if ($clause) {
        $clause = ' and ' . $clause;
    }
    else {
        $clause = '';
    }
	my $sql = "select asset.assetId, assetData.revisionDate from template left join asset on asset.assetId=template.assetId left join assetData on assetData.revisionDate=template.revisionDate and assetData.assetId=template.assetId where template.namespace=? and template.showInForms=1 and asset.state='published' and assetData.revisionDate=(SELECT max(revisionDate) from assetData where assetData.assetId=asset.assetId and (assetData.status='approved' or assetData.tagId=?)) $clause order by assetData.title";
	my $sth = $session->dbSlave->read($sql, [$namespace, $session->scratch->get("versionTag")]);
	my %templates;
	tie %templates, 'Tie::IxHash';
	while (my ($id, $version) = $sth->array) {
		$templates{$id} = WebGUI::Asset::Template->new($session,$id,undef,$version)->getTitle;
	}	
	$sth->finish;	
	return \%templates;
}

#-------------------------------------------------------------------

=head2 getParser ( session, parser )

Returns a template parser object.

NOTE: This is a class method.

=head3 session

A reference to the current session.

=head3 parser

A parser class to use. Defaults to "WebGUI::Asset::Template::HTMLTemplate"

=cut

sub getParser {
    my $class = shift;
    my $session = shift;
    my $parser = shift || $session->config->get("defaultTemplateParser") || "WebGUI::Asset::Template::HTMLTemplate";

    if ($parser eq "") {
        return WebGUI::Asset::Template::HTMLTemplate->new($session);
    } else {
        eval("use $parser");
        return $parser->new($session);
    }
}

#-------------------------------------------------------------------

=head2 importAssetCollateralData ( data )

Override to import attachments

=cut

sub importAssetCollateralData {
    my ( $self, $data, @args ) = @_;
    $self->removeAttachments;
    $self->addAttachments( $data->{template_attachments} );
    return $self->SUPER::importAssetCollateralData( $data, @args );
}
    
#-------------------------------------------------------------------

=head2 indexContent ( )

Making private. See WebGUI::Asset::indexContent() for additonal details. 

=cut

sub indexContent {
	my $self = shift;
	my $indexer = $self->SUPER::indexContent;
	$indexer->addKeywords($self->get("namespace"));
	$indexer->setIsPublic(0);
}

#-------------------------------------------------------------------

=head2 packTemplate ( template )

Pack the template into a minified version for faster downloads.

=cut

sub packTemplate {
    my ( $self, $template ) = @_;
    my $packed  = $template;
    HTML::Packer::minify( \$packed, {
        remove_comments     => 1,
        remove_newlines     => 1,
        do_javascript       => "shrink",
        do_stylesheet       => "minify",
    } );
    $self->update({ templatePacked => $packed });
    return $template;
}

#-------------------------------------------------------------------

=head2 prepare ( headerTemplateVariables )

This method sets the tags from the head block parameter of the template into the HTML head block in the style. You only need to call this method if you're using the HTML streaming features of WebGUI, like is done in the prepareView()/view()/www_view() methods of WebGUI assets.

=head3 headerTemplateVariables

A hash reference containing template variables to be processed for the head block. Typically obtained via $asset->getMetaDataAsTemplateVariables.

=cut

sub prepare {
	my $self = shift;
	my $vars = shift;
	$self->{_prepared} = 1;

	my $sent = $self->session->stow->get('templateHeadersSent');
	unless ($sent) {
		$self->session->stow->set('templateHeadersSent', $sent = []);
	}

	my $id   = $self->getId;
	# don't send head block if we've already sent it for this template
	return if isIn($id, @$sent);

	my $session      = $self->session;
	my ($db, $style) = $session->quick(qw(db style));
	my $parser       = $self->getParser($session, $self->get('parser'));
	my $headBlock    = $parser->process($self->getExtraHeadTags, $vars);

	$style->setRawHeadTags($headBlock);

	foreach my $sheet ( @{ $self->getAttachments('stylesheet') } ) {
		my %props = ( type => 'text/css', rel => 'stylesheet' );
		$style->setLink($sheet->{url}, \%props);
	}

	my $doScripts = sub {
		my ($type, $body) = @_;
		foreach my $script ( @{ $self->getAttachments($type) } ) {
			my %props = ( type => 'text/javascript' );
			$style->setScript($script->{url}, \%props, $body);
		}
	};

	$doScripts->('headScript');
	$doScripts->('bodyScript', 1);

	push(@$sent, $id);
}


#-------------------------------------------------------------------

=head2 process ( vars )

Evaluate a template replacing template commands for HTML.  If the internal property templatePacked
is set to true, the packed, minimized template will be used.  Otherwise, the original template
will be used.

=head3 vars

A hash reference containing template variables and loops. Automatically includes the entire WebGUI session.

=cut

# TODO: Have this throw an error so we can catch it and print more information
# about the template that has the error. Finding an "ERROR: Error in template" 
# in the error log is not very helpful...
sub process {
	my $self = shift;
	my $vars = shift;
	$self->prepare unless ($self->{_prepared});
    my $parser      = $self->getParser($self->session, $self->get("parser"));
    my $template    = $self->get('usePacked')
                    ? $self->get('templatePacked')
                    : $self->get('template')
                    ;
    my $output;
    eval { $output = $parser->process($template, $vars); };
    if (my $e = Exception::Class->caught) {
        $self->session->log->error(sprintf "Error processing template: %s, %s, %s", $self->getUrl, $self->getId, $e->error);
        my $i18n = WebGUI::International->new($self->session, 'Asset_Template');
        $output = sprintf $i18n->get('template error').$e->error, $self->getUrl, $self->getId;
    }
	return $output;
}


#-------------------------------------------------------------------

sub processPropertiesFromFormPost {
	my $self = shift;
	$self->SUPER::processPropertiesFromFormPost;
    # TODO: Perhaps add a way to check template syntax before it blows stuff up?
    my %data;
    my $needsUpdate = 0;
	if ($self->getValue("parser") ne $self->session->form->process("parser","className") && ($self->session->form->process("parser","className") ne "")) {
        $needsUpdate = 1;
		if (isIn($self->session->form->process("parser","className"),@{$self->session->config->get("templateParsers")})) {
			%data = ( parser => $self->session->form->process("parser","className") );
		} else {
			%data = ( parser => $self->session->config->get("defaultTemplateParser") );
		}
	}
	if ($self->session->form->process("namespace") eq 'style') {
        $needsUpdate = 1;
        $data{extraHeadTags} = '';
    }

    if ($needsUpdate) {
        $self->update(\%data);
    }

    ### Template attachments
    my $f    = $self->session->form;
    my $p    = $f->paramsHashRef;
    my @nums = grep {$_} map { my ($i) = /^attachmentUrl(\d+)$/; $i } keys %$p;
    my @add;
    
    # Remove all attachments first, then re-add whatever's left in the form
    $self->removeAttachments;

    foreach my $n (@nums) {
        my ($index, $type, $url) = 
            map { $f->process('attachment' . $_ . $n) }
            qw(Index Type Url);

        push(
            @add, {
                sequence     => $index,
                url          => $url,
                type         => $type,
            }
        );
    }
    $self->addAttachments(\@add);

    return;
}

#-------------------------------------------------------------------

=head2 processRaw ( session, template, vars [ , parser ] )

Process an arbitrary template string. This is a class method.

=head3 session

A reference to the current session.

=head3 template

A scalar containing the template text.

=head3 vars

A hash reference containing template variables.

=head3 parser

Optionally specify the class name of a parser to use.

=cut

sub processRaw {
	my $class = shift;
	my $session = shift;
	my $template = shift;
	my $vars = shift;
	my $parser = shift;
	return $class->getParser($session,$parser)->process($template, $vars);
}

#-------------------------------------------------------------------

=head2 purgeRevision ( )

Override the master purgeRevision to purge attachments

=cut

sub purgeRevision {
    my $self = shift;
    $self->removeAttachments;
    return $self->SUPER::purgeRevision(@_);
}

#-------------------------------------------------------------------

=head2 removeAttachments ( urls )

Removes attachments. C<urls> is an arrayref of URLs to remove. If C<urls>
is not defined, will remove all attachments for this revision.

=cut

sub removeAttachments {
    my ($self, $urls) = @_;

    my $db    = $self->session->db;
    my $dbh   = $db->dbh;
    my $rmsql = qq{
        DELETE FROM 
            template_attachments
        WHERE
            templateId = ?
            AND revisionDate = ?
    };
    
    if ( $urls && @{$urls} ) {
        my $in    = join(',', map { $dbh->quote($_) } @{$urls});
        $rmsql .= qq{
            AND url IN ($in)
        };
    }

    my @params = (
        $self->getId,
        $self->get('revisionDate'),
    );
    $db->write($rmsql, \@params);
}

#-------------------------------------------------------------------

=head2 update

Override update from Asset.pm to handle backwards compatibility with the old
packages that contain headBlocks. This will be removed in the future.  Don't plan
on this being here.

=cut

sub update {
    my $self = shift;
    my $requestedProperties = shift;
    my $properties = clone($requestedProperties);

    if (exists $properties->{headBlock}) {
        $properties->{extraHeadTags} .= $properties->{headBlock};
        delete $properties->{headBlock};
    }

    $self->SUPER::update($properties);
}


#-------------------------------------------------------------------
sub www_edit {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;
    my $session = $self->session;
    my $form    = $session->form;
    my $url     = $session->url;
    my $i18n    = WebGUI::International->new($session, "Asset_Template");
    my $output  = '';

    # Add an unfriendly warning message if this is a default template
    if ( $self->get( 'isDefault' ) ) {
        # Get a proper URL to make the duplicate
        my $duplicateUrl = $self->getUrl( "func=editDuplicate" );
        if ( $form->get( "proceed" ) ) {
            $duplicateUrl = $url->append( $duplicateUrl, "proceed=" . $form->get( "proceed" ) );
            if ( $form->get( "returnUrl" ) ) {
                $duplicateUrl = $url->append( $duplicateUrl, "returnUrl=" . $form->get( "returnUrl" ) );
            }
        }
        
        $session->style->setRawHeadTags( <<'ENDHTML' );
<style type="text/css">
.wGwarning { 
    border              : 1px solid red;
    background-color    : #FF6666;
    padding             : 10px;
    margin              : 5px;
    /* TODO: Add a nice little image here */
    /* TODO: Make this a generic warning class from the default webgui stylesheet */
}
</style>
ENDHTML

        $output .= q{<div class="wGwarning"><p>}
                . $i18n->get( "warning default template" )
                . q{</p><p>}
                . sprintf( q{<a href="} . $duplicateUrl . q{">%s</a>}, $i18n->get( "make duplicate label" ) )
                . q{</p></div}
                ;
    }
    
    $output .= $self->getEditForm->print;

    $self->getAdminConsole->addSubmenuItem($self->getUrl('func=styleWizard'),$i18n->get("style wizard")) if ($self->get("namespace") eq "style");
    return $self->getAdminConsole->render( $output, $i18n->get('edit template') );
}

#-------------------------------------------------------------------
sub www_goBackToPage {
	my $self = shift;
	$self->session->http->setRedirect($self->session->form->get("returnUrl")) if ($self->session->form->get("returnUrl"));
	return undef;
}

#----------------------------------------------------------------------------

=head2 www_editDuplicate

Make a duplicate of this template and edit that instead.

=cut

sub www_editDuplicate {
    my $self        = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;

    my $session     = $self->session;
    my $form        = $self->session->form;

    my $newTemplate = $self->duplicate;
    $newTemplate->update( { 
        isDefault   => 0, 
        title       => $self->get( "title" ) . " (copy)",
        menuTitle   => $self->get( "menuTitle" ) . " (copy)",
    } );

    # Make our asset use our new template
    if ( $self->session->form->get( "proceed" ) eq "goBackToPage" ) {
        if ( my $asset = WebGUI::Asset->newByUrl( $session, $form->get( "returnUrl" ) ) ) {
            # Find which property we should set by comparing namespaces and current values
            DEF: for my $def ( @{ $asset->definition( $self->session ) } ) {
                my $properties  = $def->{ properties };
                PROP: for my $prop ( keys %{ $properties } ) {
                    next PROP unless lc $properties->{ $prop }->{ fieldType } eq "template";
                    next PROP unless $asset->get( $prop ) eq $self->getId;
                    if ( $properties->{ $prop }->{ namespace } eq $self->get( "namespace" ) ) {
                        $asset->addRevision( { $prop => $newTemplate->getId } );

                        # Auto-commit our revision if necessary
                        # TODO: This needs to be handled automatically somehow...
                        WebGUI::VersionTag->autoCommitWorkingIfEnabled($self->session);
                        last DEF;
                    }
                }
            }
        }
    }
    
    return $newTemplate->www_edit;
}

#-------------------------------------------------------------------
sub www_manage {
	my $self = shift;
	#takes the user to the folder containing this template.
	return $self->getParent->www_manageAssets;
}


#-------------------------------------------------------------------
sub www_styleWizard {
	my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;
	my $i18n = WebGUI::International->new($self->session, "Asset_Template");
	my $form = $self->session->form;
	my $output = "";
	if ($form->get("step") == 2) {
		my $f = WebGUI::HTMLForm->new($self->session,{action=>$self->getUrl});
		$f->hidden(name=>"func", value=>"styleWizard");
		$f->hidden(name=>"proceed", value=>"manageAssets") if ($form->get("proceed"));
		$f->hidden(name=>"step", value=>3);
		$f->hidden(name=>"layout", value=>$form->get("layout"));
		$f->text(
			name=>"heading",
			value=>"My Site",
			label=>$i18n->get("site name"),
			hoverHelp=>$i18n->get("site name description")
		);
		$f->file(
			name=>"logo",
			label=>$i18n->get("logo"),
			hoverHelp=>$i18n->get("logo description"),
			subtext=>$i18n->get("logo subtext")
		);
		$f->color(
			name=>"pageBackgroundColor",
			value=>"#ccccdd",
			label=>$i18n->get("page background color"),
			hoverHelp=>$i18n->get("page background color description"),
		);
		$f->color(
			name=>"headingBackgroundColor",
			value=>"#ffffff",
			label=>$i18n->get("header background color"),
			hoverHelp=>$i18n->get("header background color description"),
		);
		$f->color(
			name=>"headingForegroundColor",
			value=>"#000000",
			label=>$i18n->get("header text color"),
			hoverHelp=>$i18n->get("header text color description"),
		);
		$f->color(
			name=>"bodyBackgroundColor",
			value=>"#ffffff",
			label=>$i18n->get("body background color"),
			hoverHelp=>$i18n->get("body background color description"),
		);
		$f->color(
			name=>"bodyForegroundColor",
			value=>"#000000",
			label=>$i18n->get("body text color"),
			hoverHelp=>$i18n->get("body text color description"),
		);
		$f->color(
			name=>"menuBackgroundColor",
			value=>"#eeeeee",
			label=>$i18n->get("menu background color"),
			hoverHelp=>$i18n->get("menu background color description"),
		);
		$f->color(
			name=>"linkColor",
			value=>"#0000ff",
			label=>$i18n->get("link color"),
			hoverHelp=>$i18n->get("link color description"),
		);
		$f->color(
			name=>"visitedLinkColor",
			value=>"#ff00ff",
			label=>$i18n->get("visited link color"),
			hoverHelp=>$i18n->get("visited link color description"),
		);
		$f->submit;
		$output = $f->print;
	} elsif ($form->get("step") == 3) {
		my $storageId = $form->get("logo","file");
		my $logo;
		my $logoContent = '';
		if ($storageId) {
			my $storage = WebGUI::Storage->get($self->session,$storageId);
			$logo = $self->addChild({
				className=>"WebGUI::Asset::File::Image",
				title=>join(' ', $form->get("heading"), $i18n->get('logo')),
				menuTitle=>join(' ', $form->get("heading"), $i18n->get('logo')),
				url=>join(' ', $form->get("heading"), $i18n->get('logo')),
				storageId=>$storage->getId,
				filename=>@{$storage->getFiles}[0],
				templateId=>"PBtmpl0000000000000088"
				});
			$logo->generateThumbnail;
			$logoContent = '<div class="logo"><a href="^H(linkonly);">^AssetProxy('.$logo->get("url").');</a></div>';
		}
		my $customHead = '';
		if ($form->get("layout") eq "1") {
			$customHead .= '
			.bodyContent {
			 	background-color: '.$form->get("bodyBackgroundColor","color").';
                		color: '.$form->get("bodyForegroundColor","color").';
				width: 70%; 
				float: left;
			}
			.menu {
				width: 30%;
				float: left;
			}
			.wrapper { 
				width: 80%;
				margin-right: 10%;
				margin-left: 10%;
				background-color: '.$form->get("menuBackgroundColor","color").';
			}
			';
		} else {
			$customHead .= '
			.bodyContent {
			 	background-color: '.$form->get("bodyBackgroundColor","color").';
                		color: '.$form->get("bodyForegroundColor","color").';
				width: 100%;
			}
			.menu {
                		background-color: '.$form->get("menuBackgroundColor","color").';
				width: 100%;
				text-align: center;
			}
			.wrapper { 
				width: 80%;
				margin-right: 10%;
				margin-left: 10%;
			}
			';
		}
		my $style = '<html>
<head>
	<tmpl_var head.tags>
	<title>^Page(title); - ^c;</title>
	<style type="text/css">
	.siteFunctions {
		float: right;
		font-size: 12px;
	}
	.copyright {
		font-size: 12px;
	}
	body {
		background-color: '.$form->get("pageBackgroundColor","color").';
		font-family: helvetica;
		font-size: 14px;
	}
	.heading {
		background-color: '.$form->get("headingBackgroundColor","color").';
		color: '.$form->get("headingForegroundColor","color").';
		font-size: 30px;
		margin-left: 10%;
		margin-right: 10%;
		vertical-align: middle;
	}
	.logo {
		width: 200px; 
		float: left;
		text-align: center;
	}
	.logo img {
		border: 0px;
	}
	.endFloat {
		clear: both;
	}
	.padding {
		padding: 5px;
	}
	'.$customHead.'
	a {
		color: '.$form->get("linkColor","color").';
	}
	a:visited {
		color: '.$form->get("visitedLinkColor","color").';
	}
	</style>
</head>
<body>
^AdminBar;
<div class="heading">
	<div class="padding">
		'.$logoContent.'
		'.$form->get("heading").'
		<div class="endFloat"></div>
	</div>
</div>
<div class="wrapper">
	<div class="menu">
		<div class="padding">^AssetProxy('.($form->get("layout") == 1 ? 'flexmenu' : 'toplevelmenuhorizontal').');</div>
	</div>
	<div class="bodyContent">
		<div class="padding"><tmpl_var body.content></div>
	</div>
	<div class="endFloat"></div>
</div>
<div class="heading">
	<div class="padding">
		<div class="siteFunctions">^a(^@;); ^AdminToggle;</div>
		<div class="copyright">&copy; ^D(%y); ^c;</div>
	<div class="endFloat"></div>
	</div>
</div>
</body>
</html>';
		return $self->addRevision({
			template=>$style
			})->www_edit;
	} else {
		$output = WebGUI::Form::formHeader($self->session,{action=>$self->getUrl}).WebGUI::Form::hidden($self->session,{name=>"func", value=>"styleWizard"});
		$output .= WebGUI::Form::hidden($self->session,{name=>"proceed", value=>"manageAssets"}) if ($form->get("proceed"));
		$output .= '<style type="text/css">
			.chooser { float: left; width: 150px; height: 150px; } 
			.representation, .representation td { font-size: 12px; width: 120px; border: 1px solid black; } 
			.representation { height: 130px; }
			</style>';
		$output .= $i18n->get('choose a layout');
		$output .= WebGUI::Form::hidden($self->session,{name=>"step", value=>2});
		$output .= '<div class="chooser">'.WebGUI::Form::radio($self->session,{name=>"layout", value=>1, checked=>1}).sprintf(q|<table class="representation"><tbody>
			<tr><td>%s</td><td>%s</td></tr>
			<tr><td>%s</td><td>%s</td></tr>
			</tbody></table></div>|,
			$i18n->get('logo'),
			$i18n->get('heading'),
			$i18n->get('menu'),
			$i18n->get('body content'),
			);
		$output .= '<div class="chooser">'.WebGUI::Form::radio($self->session,{name=>"layout", value=>2}).sprintf(q|<table class="representation"><tbody>
			<tr><td>%s</td><td>%s</td></tr>
			<tr><td style="text-align: center;" colspan="2">%s</td></tr>
			<tr><td colspan="2">%s</td></tr>
			</tbody></table></div>|,
			$i18n->get('logo'),
			$i18n->get('heading'),
			$i18n->get('menu'),
			$i18n->get('body content'),
			);
		$output .= WebGUI::Form::submit($self->session);
		$output .= WebGUI::Form::formFooter($self->session);
	}
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=edit'),$i18n->get("edit template")) if ($self->get("url"));
        return $self->getAdminConsole->render($output,$i18n->get('style wizard'));
}

#-------------------------------------------------------------------
sub www_view {
	my $self = shift;
	return $self->session->asset($self->getContainer)->www_view;
}



1;
