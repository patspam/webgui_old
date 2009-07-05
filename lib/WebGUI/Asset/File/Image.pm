package WebGUI::Asset::File::Image;

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
use base 'WebGUI::Asset::File';
use WebGUI::Storage;
use WebGUI::HTMLForm;
use WebGUI::Utility;
use WebGUI::Form::Image;

=head1 NAME

Package WebGUI::Asset::File::Image

=head1 DESCRIPTION

Extends WebGUI::Asset::File to add image manipulation operations.

=head1 SYNOPSIS

use WebGUI::Asset::File::Image;


=head1 METHODS

These methods are available from this class:

=cut



#-------------------------------------------------------------------

=head2 applyConstraints ( options ) 

Things that are done after a new file is attached.

=head3 options

A hash reference of optional parameters.

=head4 maxImageSize

An integer (in pixels) representing the longest edge the image may have.

=head4 thumbnailSize

An integer (in pixels) representing the longest edge a thumbnail may have.

=cut

sub applyConstraints {
    my $self = shift;
    my $options = shift;
    $self->SUPER::applyConstraints($options);
    my $maxImageSize = $options->{maxImageSize} || $self->get('maxImageSize') || $self->session->setting->get("maxImageSize");
    my $thumbnailSize = $options->{thumbnailSize} || $self->get('thumbnailSize') || $self->session->setting->get("thumbnailSize");
	my $parameters = $self->get("parameters");
    my $storage = $self->getStorageLocation;
	unless ($parameters =~ /alt\=/) {
		$self->update({parameters=>$parameters.' alt="'.$self->get("title").'"'});
	}
    my $file = $self->get("filename");
    $storage->adjustMaxImageSize($file, $maxImageSize);
    $self->generateThumbnail($thumbnailSize);
    $self->setSize;
}



#-------------------------------------------------------------------

=head2 definition ( definition )

Defines the properties of this asset.

=head3 definition

A hash reference passed in from a subclass definition.

=cut

sub definition {
    my $class       = shift;
    my $session     = shift;
    my $definition  = shift;
    my $i18n        = WebGUI::International->new($session,"Asset_Image");
    push @{$definition}, {
        assetName       => $i18n->get('assetName'),
        tableName       => 'ImageAsset',
        className       => 'WebGUI::Asset::File::Image',
        icon            => 'image.gif',
        properties => {
            thumbnailSize => {
                fieldType       => 'integer',
                defaultValue    => $session->setting->get("thumbnailSize"),
            },
            parameters => {
                fieldType       => 'textarea',
                defaultValue    => 'style="border-style:none;"',
            },
            annotations => {
                fieldType       => 'hidden',
                noFormPost      => 1,
                defaultValue    => '',
            },
        },
    };
    return $class->SUPER::definition($session,$definition);
}



#-------------------------------------------------------------------

=head2 generateThumbnail ( [ thumbnailSize ] ) 

Generates a thumbnail for this image.

=head3 thumbnailSize

A size, in pixels, of the maximum height or width of a thumbnail. If specified this will change the thumbnail size of the image. If unspecified the thumbnail size set in the properties of this asset will be used.

=cut

sub generateThumbnail {
	my $self = shift;
	my $thumbnailSize = shift;
	if (defined $thumbnailSize) {
		$self->update({thumbnailSize=>$thumbnailSize});
	}
	$self->getStorageLocation->generateThumbnail($self->get("filename"),$self->get("thumbnailSize"));
}


#-------------------------------------------------------------------

=head2 getEditForm ( )

Returns the TabForm object that will be used in generating the edit page for this asset.

=cut

sub getEditForm {
	my $self = shift;
	my $tabform = $self->SUPER::getEditForm();
	my $i18n = WebGUI::International->new($self->session,"Asset_Image");
        $tabform->getTab("properties")->integer(
               	-name=>"thumbnailSize",
		-label=>$i18n->get('thumbnail size'),
		-hoverHelp=>$i18n->get('Thumbnail size description'),
		-value=>$self->getValue("thumbnailSize")
               	);
	$tabform->getTab("properties")->textarea(
		-name=>"parameters",
		-label=>$i18n->get('parameters'),
		-hoverHelp=>$i18n->get('Parameters description'),
		-value=>$self->getValue("parameters")
		);
	if ($self->get("filename") ne "") {
		$tabform->getTab("properties")->readOnly(
			-label=>$i18n->get('thumbnail'),
			-hoverHelp=>$i18n->get('Thumbnail description'),
			-value=>'<a href="'.$self->getFileUrl.'"><img src="'.$self->getThumbnailUrl.'?noCache='.$self->session->datetime->time().'" alt="thumbnail" /></a>'
			);
		my ($x, $y) = $self->getStorageLocation->getSizeInPixels($self->get("filename"));
        	$tabform->getTab("properties")->readOnly(
			-label=>$i18n->get('image size'),
			-value=>$x.' x '.$y
			);
	}
	return $tabform;
}

#-------------------------------------------------------------------

=head2 getThumbnailUrl 

Returns the URL to the thumbnail of the image stored in the Asset.

=cut

sub getThumbnailUrl {
	my $self = shift;
	return $self->getStorageLocation->getThumbnailUrl($self->get("filename"));
}

#-------------------------------------------------------------------

=head2 getToolbar ( )

Returns a toolbar with a set of icons that hyperlink to functions that delete, edit, promote, demote, cut, and copy.

=cut

sub getToolbar {
	my $self = shift;
	return undef if ($self->getToolbarState);
	return $self->SUPER::getToolbar();
}

#-------------------------------------------------------------------

=head2 view 

Renders this asset.

=cut

sub view {
	my $self = shift;
	if (!$self->session->var->isAdminOn && $self->get("cacheTimeout") > 10) {
		my $out = WebGUI::Cache->new($self->session,"view_".$self->getId)->get;
		return $out if $out;
	}
	my %var = %{$self->get};
    my ($crop_js, $domMe) = $self->annotate_js({ just_image => 1 });

    if ($crop_js) {
        my ($style, $url) = $self->session->quick(qw(style url));

        $style->setLink($url->extras('yui/build/fonts/fonts-min.css'), {rel=>'stylesheet', type=>'text/css'});
        $style->setLink($url->extras('yui/container/assets/container.css'), {rel=>'stylesheet', type=>'text/css'});
        $style->setScript($url->extras('yui/build/yahoo-dom-event/yahoo-dom-event.js'), {type=>'text/javascript'});
        $style->setScript($url->extras('yui/build/container/container-min.js'), {type=>'text/javascript'});
    }

	$var{controls} = $self->getToolbar;
	$var{fileUrl} = $self->getFileUrl;
	$var{fileIcon} = $self->getFileIconUrl;
	$var{thumbnail} = $self->getThumbnailUrl;
	$var{annotateJs} = "$crop_js$domMe";
    $var{parameters} = sprintf("id=%s", $self->getId());
	my $form = $self->session->form;
    my $out = $self->processTemplate(\%var,undef,$self->{_viewTemplate});
	if (!$self->session->var->isAdminOn && $self->get("cacheTimeout") > 10) {
		WebGUI::Cache->new($self->session,"view_".$self->getId)->set($out,$self->get("cacheTimeout"));
	}
       	return $out;
}


#----------------------------------------------------------------------------

=head2 setFile ( filename )

Extend the superclass setFile to automatically generate thumbnails.

=cut

sub setFile {
    my $self    = shift;
    $self->SUPER::setFile(@_);
    $self->generateThumbnail;
}

#-------------------------------------------------------------------

=head2 www_edit 

Override the master class to add image editing controls to the edit screen.
Also adds the Image template form variable.

=cut

sub www_edit {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;
	my $i18n = WebGUI::International->new($self->session, 'Asset_Image');
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=resize'),$i18n->get("resize image")) if ($self->get("filename"));
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=rotate'),$i18n->get("rotate image")) if ($self->get("filename"));
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=crop'),$i18n->get("crop image")) if ($self->get("filename"));
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=annotate'),$i18n->get("annotate image")) if ($self->get("filename"));
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=undo'),$i18n->get("undo image")) if ($self->get("filename"));
	my $tabform = $self->getEditForm;
	$tabform->getTab("display")->template(
		-value=>$self->get("templateId"),
		-namespace=>"ImageAsset",
		-hoverHelp=>$i18n->get('image template description'),
		-defaultValue=>"PBtmpl0000000000000088"
		);
        return $self->getAdminConsole->render($tabform->print,$i18n->get("edit image"));
}

#-------------------------------------------------------------------

=head2 www_undo 

Rolls back the last revision of this asset, undoing any work that may
have been done to it.

=cut

sub www_undo {
    my $self = shift;
    my $previous = (@{$self->getRevisions()})[1];
    # instantiate assetId 
    if ($previous) {
	    # my $session = $self->session;

	    # my $cache = WebGUI::Cache->new($self->session, ["asset",$self->getId,$self->getRevisionDate]);
	    # $cache->flush;
	    # my $cache = WebGUI::Cache->new($previous->session, ["asset",$previous->getId,$previous->getRevisionDate]);
	    # $cache->flush;

	    $self = $self->purgeRevision();
	    # $self = undef;
	    # $self = WebGUI::Asset->new($previous->session, $previous->getId, ref $previous, $previous->getRevisionDate);
	    $self = $previous;
	    $self->generateThumbnail;
    }
    return $self->www_edit();
}

#-------------------------------------------------------------------

# 
# All of the images will have to change to support annotate.
# The revision system doesn't support the blobs, it seems.
# All of the image operations will have to be updated to support annotations.
#

=head2 www_annotate 

Allow the user to place some text on their image.  This is done via JS and tooltips

=cut

sub www_annotate {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;
	if (1) {
		my $newSelf = $self->addRevision();
		delete $newSelf->{_storageLocation};
		$newSelf->getStorageLocation->annotate($newSelf->get("filename"),$newSelf,$newSelf->session->form);
		$newSelf->setSize($newSelf->getStorageLocation->getFileSize($newSelf->get("filename")));
		$self = $newSelf;
		$self->generateThumbnail;
	}

    my ($style, $url) = $self->session->quick(qw(style url));
    # $style->setLink($url->extras('annotate/imageMap.css'), {rel=>'stylesheet', type=>'text/css'});

	$style->setLink($url->extras('yui/build/resize/assets/skins/sam/resize.css'), {rel=>'stylesheet', type=>'text/css'});
	$style->setLink($url->extras('yui/build/fonts/fonts-min.css'), {rel=>'stylesheet', type=>'text/css'});
	$style->setLink($url->extras('yui/build/imagecropper/assets/skins/sam/imagecropper.css'), {rel=>'stylesheet', type=>'text/css'});

	$style->setScript($url->extras('yui/build/yahoo-dom-event/yahoo-dom-event.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/element/element-beta-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/dragdrop/dragdrop-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/resize/resize-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/imagecropper/imagecropper-beta-min.js'), {type=>'text/javascript'});

    # my $imageAsset = $self->session->db->getRow("ImageAsset","assetId",$self->getId);

	my @pieces = split(/\n/, $self->get('annotations'));
	# my ($top_left, $width_height, $note) = split(/\n/, $imageAsset->{annotations});
	
    my ($img_null, $tooltip_block, $tooltip_none) = ('', '', '');
	for (my $i = 0; $i < $#pieces; $i += 3) {
        $img_null .= "YAHOO.img.container.tt$i = null;\n";
        $tooltip_block .= "YAHOO.util.Dom.setStyle('tooltip$i', 'display', 'block');\n";
        $tooltip_none .= "YAHOO.util.Dom.setStyle('tooltip$i', 'display', 'none');\n";
        my $j = $i + 2;
        # warn("i: $i: ", $self->session->form->process("delAnnotate$i"));
    }

    my $image = '<div align="center" class="yui-skin-sam"><img src="'.$self->getStorageLocation->getUrl($self->get("filename")).'" style="border-style:none;" alt="'.$self->get("filename").'" id="yui_img" /></div>';

	my ($width, $height) = $self->getStorageLocation->getSize($self->get("filename"));

	my @checkboxes = ();
	my $i18n = WebGUI::International->new($self->session,"Asset_Image");
	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);

	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=edit'),$i18n->get("edit image"));
	$f->hidden(
		-name=>"func",
		-value=>"annotate"
		);
    $f->text(
		-label=>$i18n->get('annotate image'),
		-value=>'',
		-hoverHelp=>$i18n->get('annotate image description'),
		-name=>'annotate_text'
		);
	$f->integer(
		-label=>$i18n->get('top'),
		-name=>"annotate_top",
		-value=>,
		);
	$f->integer(
		-label=>$i18n->get('left'),
		-name=>"annotate_left",
		-value=>,
		);
	$f->integer(
		-label=>$i18n->get('width'),
		-name=>"annotate_width",
		-value=>,
		);
	$f->integer(
		-label=>$i18n->get('height'),
		-name=>"annotate_height",
		-value=>,
		);
    $f->button(
        -value=>$i18n->get('annotate'),
        -extras=>'onclick="switchState();"',
        );
	$f->submit;
    my ($crop_js, $domMe) = $self->annotate_js();
    return $self->getAdminConsole->render($f->print."$image$crop_js$domMe",$i18n->get("annotate image"));
}

#-------------------------------------------------------------------

=head2 annotate_js ($opts)

Returns some javascript and other supporting text.

=head3 $opts

A hash reference of options

=head4 just_image

=cut

sub annotate_js {
    my $self = shift;
    my $opts = shift;

	my @pieces = split(/\n/, $self->get('annotations'));

    # warn("pieces: $#pieces: ". $self->getId());
    return "" if !@pieces && $opts->{just_image};

    my ($img_null, $tooltip_block, $tooltip_none) = ('', '', '');
	for (my $i = 0; $i < $#pieces; $i += 3) {
        $img_null .= "YAHOO.img.container.tt$i = null;\n";
        $tooltip_block .= "YAHOO.util.Dom.setStyle('tooltip$i', 'display', 'block');\n";
        $tooltip_none .= "YAHOO.util.Dom.setStyle('tooltip$i', 'display', 'none');\n";
        my $j = $i + 2;
        # warn("i: $i: ", $self->session->form->process("delAnnotate$i"));
    }

    my $id = $$opts{just_image} ? $self->getId : "yui_img";

	my $crop_js = qq(
        <script type="text/javascript">
        var crop;
        function switchState() {
            $img_null

            if (crop) {
                crop.destroy();
                crop = null;
                $tooltip_block
            }
            else {
                crop = new YAHOO.widget.ImageCropper('$id', { 
                    initialXY: [20, 20], 
                    keyTick: 5, 
                    shiftKeyTick: 50 
                }); 
                crop.on('moveEvent', function() { 
                    var region = crop.getCropCoords();
                    element = document.getElementById('annotate_width_formId');
                    element.value = region.width;
                    element = document.getElementById('annotate_height_formId');
                    element.value = region.height;
                    element = document.getElementById('annotate_top_formId');
                    element.value = region.top;
                    element = document.getElementById('annotate_left_formId');
                    element.value = region.left;
                }); 
                $tooltip_none
            }
        }
		</script>
    );

    my $hotspots = '';
    my $domMe = '';

	for (my $i = 0; $i < $#pieces; $i += 3) {
		my $top_left = $pieces[$i];
		my $width_height = $pieces[$i + 1];
		my $note = $pieces[$i + 2];

        if ($top_left =~ /top: (\d+)px; left: (\d+)px;/) {
            $top_left = "xy[0]+$1, xy[1]+$2";
        }

        my ($width, $height) = ("", "");
        if ($width_height =~ /width: (\d+)px; height: (\d+)px;/) {
            ($width, $height) = ("$1px", "$2px");
        }

        # next if 3 == $i;

        $domMe .= qq(
                <style type="text/css">
                    div#tooltip$i { position: absolute; border:1px solid; }
                </style>

                <span id=span_tooltip$i>
                </span>

                <script type="text/javascript">
                    function on_load_$i() {
                        var xy = YAHOO.util.Dom.getXY('$id'); 

                        document.getElementById('span_tooltip$i').innerHTML = "<div id=tooltip$i style='border:1px solid;'></div>";
                        YAHOO.util.Dom.setStyle('tooltip$i', 'display', 'block');
                        YAHOO.util.Dom.setStyle('tooltip$i', 'height', '$height');
                        YAHOO.util.Dom.setStyle('tooltip$i', 'width', '$width');
                        YAHOO.util.Dom.setXY('span_tooltip$i', [$top_left]); 
                        YAHOO.util.Dom.setXY('tooltip$i', [$top_left]); 

                        YAHOO.namespace("img.container");
                        YAHOO.img.container.tt$i = new YAHOO.widget.Tooltip("tt$i", { showdelay: 0, visible: true, context:"tooltip$i", position:"relative", container:"tooltip$i", text:"$note" });
                    }
                    if (document.addEventListener) {
                        document.addEventListener("DOMContentLoaded", on_load_$i, false);
                    }
                    else if (window.attachEvent){
                        window.attachEvent('onload', on_load_$i);
                    }

                </script>
        );
    }

    return($crop_js, $domMe);
}

#-------------------------------------------------------------------

=head2 www_rotate 

Displays a form to the user to rotate their image.  If the C<Rotate> form variable
is true, does the rotation as well.

Returns the user to the roate form.

=cut

sub www_rotate {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;
	if (defined $self->session->form->process("Rotate")) {
		my $newSelf = $self->addRevision();
		delete $newSelf->{_storageLocation};
		$newSelf->getStorageLocation->rotate($newSelf->get("filename"),$newSelf->session->form->process("Rotate"));
		$newSelf->setSize($newSelf->getStorageLocation->getFileSize($newSelf->get("filename")));
		$self = $newSelf;
		$self->generateThumbnail;
	}

	my ($x, $y) = $self->getStorageLocation->getSizeInPixels($self->get("filename"));

	##YUI specific datatable CSS
	my ($style, $url) = $self->session->quick(qw(style url));

	my $img_name = $self->getStorageLocation->getUrl($self->get("filename"));
	my $img_file = $self->get("filename");
	my $image = '<div align="center" class="yui-skin-sam"><img src="'.$self->getStorageLocation->getUrl($self->get("filename")).'" style="border-style:none;" alt="'.$self->get("filename").'" id="yui_img" /></div>';

	my $i18n = WebGUI::International->new($self->session,"Asset_Image");
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=edit'),$i18n->get("edit image"));
	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
	$f->hidden(
		-name=>"func",
		-value=>"rotate"
		);
    $f->button(
        -value=>"Left",
        -extras=>qq(onclick="var deg = document.getElementById('Rotate_formId').value; deg = parseInt(deg) + 90; document.getElementById('Rotate_formId').value = deg;"),
        );
    $f->button(
        -value=>"Right",
        -extras=>qq(onclick="var deg = document.getElementById('Rotate_formId').value; deg = parseInt(deg) - 90; document.getElementById('Rotate_formId').value = deg;"),
        );
	$f->integer(
		-label=>$i18n->get('degree'),
		-name=>"Rotate",
		-value=>0,
		);
	$f->submit;
        return $self->getAdminConsole->render($f->print.$image,$i18n->get("rotate image"));
}

#-------------------------------------------------------------------

=head2 www_resize 

Displays a form for the user to resize this image.  If either of the C<newWidth> or
C<newHeight> form variables are true, also does the resizing.

Returns the user to the resize form.

=cut

sub www_resize {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;
	if ($self->session->form->process("newWidth") || $self->session->form->process("newHeight")) {
		my $newSelf = $self->addRevision();
		delete $newSelf->{_storageLocation};
		$newSelf->getStorageLocation->resize($newSelf->get("filename"),$newSelf->session->form->process("newWidth"),$newSelf->session->form->process("newHeight"));
		$newSelf->setSize($newSelf->getStorageLocation->getFileSize($newSelf->get("filename")));
		$self = $newSelf;
		$self->generateThumbnail;
	}

	my ($x, $y) = $self->getStorageLocation->getSizeInPixels($self->get("filename"));

	##YUI specific datatable CSS
	my ($style, $url) = $self->session->quick(qw(style url));

	$style->setLink($url->extras('yui/build/fonts/fonts-min.css'), {rel=>'stylesheet', type=>'text/css'});
	$style->setLink($url->extras('yui/build/resize/assets/skins/sam/resize.css'), {rel=>'stylesheet', type=>'text/css'});
	$style->setScript($url->extras('yui/build/yahoo-dom-event/yahoo-dom-event.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/element/element-beta-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/dragdrop/dragdrop-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/resize/resize-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/animation/animation-min.js'), {type=>'text/javascript'});

	my $resize_js = qq(
		<script>
		(function() { 
			  var Dom = YAHOO.util.Dom, 
			      Event = YAHOO.util.Event; 
		       
			      var resize = new YAHOO.util.Resize('yui_img', { 
				  handles: 'all', 
				  knobHandles: true, 
				  height: '${x}px', 
				  width: '${y}px', 
				    proxy: true, 
				    ghost: true, 
				    status: true, 
				    draggable: false, 
				    ratio: true,
				    animate: true, 
				    animateDuration: .75, 
				    animateEasing: YAHOO.util.Easing.backBoth 
				}); 
			 
				resize.on('startResize', function() { 
				    this.getProxyEl().innerHTML = '<img src="' + this.get('element').src + '" style="height: 100%; width: 100%;">'; 
				    Dom.setStyle(this.getProxyEl().firstChild, 'opacity', '.25'); 
				}, resize, true); 

				resize.on('resize', function(e) { 
				    element = document.getElementById('newWidth_formId');
				    element.value = e.width;

				    element = document.getElementById('newHeight_formId');
				    element.value = e.height;
			        }, resize, true); 
			})(); 
		</script>
	);

	my $i18n = WebGUI::International->new($self->session,"Asset_Image");
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=edit'),$i18n->get("edit image"));
	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
	$f->hidden(
		-name=>"func",
		-value=>"resize"
		);
       	$f->readOnly(
		-label=>$i18n->get('image size'),
		-hoverHelp=>$i18n->get('image size description'),
		-value=>$x.' x '.$y,
		);
	$f->integer(
		-label=>$i18n->get('new width'),
		-hoverHelp=>$i18n->get('new width description'),
		-name=>"newWidth",
		-value=>$x,
		);
	$f->integer(
		-label=>$i18n->get('new height'),
		-hoverHelp=>$i18n->get('new height description'),
		-name=>"newHeight",
		-value=>$y,
		);
	$f->submit;
	my $image = '<div align="center" class="yui-skin-sam"><img src="'.$self->getStorageLocation->getUrl($self->get("filename")).'" style="border-style:none;" alt="'.$self->get("filename").'" id="yui_img" /></div>'.$resize_js;
        return $self->getAdminConsole->render($f->print.$image,$i18n->get("resize image"));
}

#-------------------------------------------------------------------

=head2 www_crop 

Display a form that allows the user to Crop their images.  Also does the
cropping if any of the C<Width>, C<Height>, C<Top> or C<Left> form
variables are true.

Returns the user to the cropping form.

=cut

sub www_crop {
    my $self = shift;
    return $self->session->privilege->insufficient() unless $self->canEdit;
    return $self->session->privilege->locked() unless $self->canEditIfLocked;

    if ($self->session->form->process("Width") || $self->session->form->process("Height") 
        || $self->session->form->process("Top") || $self->session->form->process("Left")) {
        my $newSelf = $self->addRevision();
        delete $newSelf->{_storageLocation};
        $newSelf->getStorageLocation->crop(
            $newSelf->get("filename"),
            $newSelf->session->form->process("Width"),
            $newSelf->session->form->process("Height"),
            $newSelf->session->form->process("Top"),
            $newSelf->session->form->process("Left")
        );
		$self = $newSelf;
		$self->generateThumbnail;
    }

	my $filename = $self->get("filename");

	##YUI specific datatable CSS
    my ($style, $url) = $self->session->quick(qw(style url));

	my $crop_js = qq(
		<script>
		(function() {
            var Dom = YAHOO.util.Dom, Event = YAHOO.util.Event, results = null; 

        Event.onDOMReady(function() { 
                var crop = new YAHOO.widget.ImageCropper('yui_img', { 
                    initialXY: [20, 20], 
                    keyTick: 5, 
                    shiftKeyTick: 50 
                }); 
                crop.on('moveEvent', function() { 
                    var region = crop.getCropCoords(); 
                    element = document.getElementById('Width_formId');
                    element.value = region.width;
                    element = document.getElementById('Height_formId');
                    element.value = region.height;
                    element = document.getElementById('Top_formId');
                    element.value = region.top;
                    element = document.getElementById('Left_formId');
                    element.value = region.left;
                }); 
            }); 
        })(); 
		</script>
    );

	$style->setLink($url->extras('yui/build/resize/assets/skins/sam/resize.css'), {rel=>'stylesheet', type=>'text/css'});
	$style->setLink($url->extras('yui/build/fonts/fonts-min.css'), {rel=>'stylesheet', type=>'text/css'});
	$style->setLink($url->extras('yui/build/imagecropper/assets/skins/sam/imagecropper.css'), {rel=>'stylesheet', type=>'text/css'});
	$style->setScript($url->extras('yui/build/yahoo-dom-event/yahoo-dom-event.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/element/element-beta-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/dragdrop/dragdrop-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/resize/resize-min.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('yui/build/imagecropper/imagecropper-beta-min.js'), {type=>'text/javascript'});

	my $i18n = WebGUI::International->new($self->session,"Asset_Image");

	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=edit'),$i18n->get("edit image"));
	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
	$f->hidden(
		-name=>"degree",
		-value=>"0"
		);
	$f->hidden(
		-name=>"func",
		-value=>"crop"
		);
	my ($x, $y) = $self->getStorageLocation->getSizeInPixels($filename);
	$f->integer(
		-label=>$i18n->get('width'),
		-hoverHelp=>$i18n->get('new width description'),
		-name=>"Width",
		-value=>$x,
		);
	$f->integer(
		-label=>$i18n->get('height'),
		-hoverHelp=>$i18n->get('new height description'),
		-name=>"Height",
		-value=>$y,
		);
	$f->integer(
		-label=>$i18n->get('top'),
		-hoverHelp=>$i18n->get('new width description'),
		-name=>"Top",
		-value=>$x,
		);
	$f->integer(
		-label=>$i18n->get('left'),
		-hoverHelp=>$i18n->get('new height description'),
		-name=>"Left",
		-value=>$y,
		);
	$f->submit;

	my $image = '<div align="center" class="yui-skin-sam"><img src="'.$self->getStorageLocation->getUrl($filename).'" style="border-style:none;" alt="'.$filename.'" id="yui_img" /></div>'.$crop_js;

    return $self->getAdminConsole->render($f->print.$image,$i18n->get("crop image"));
}

1;
