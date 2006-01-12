package WebGUI::Operation::FormHelpers;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Asset;
use WebGUI::HTMLForm;
use WebGUI::Session;
use WebGUI::Style;

#-------------------------------------------------------------------
sub www_formAssetTree {
	my $session = shift;
	my $base = WebGUI::Asset->newByUrl || WebGUI::Asset->getRoot;
	my @crumb;
	my $ancestors = $base->getLineage(["self","ancestors"],{returnObjects=>1});
	foreach my $ancestor (@{$ancestors}) {
		push(@crumb,'<a href="'.$ancestor->getUrl("op=formAssetTree;classLimiter=".$session->form->process("classLimiter").";formId="
                        .$session->form->process("formId")).'">'.$ancestor->get("menuTitle").'</a>');
	}	
	my $output = '<p>'.join(" &gt; ", @crumb)."</p>\n";
	my $children = $base->getLineage(["children"],{returnObjects=>1});
	foreach my $child (@{$children}) {
		next unless $child->canView;
		if ($child->get("className") =~ /^$session->form->process("classLimiter")/) {
			$output .= '<a href="#" onclick="window.opener.document.getElementById(\''.$session->form->process("formId")
				.'\').value=\''.$child->getId.'\';window.opener.document.getElementById(\''.
				$session->form->process("formId").'_display\').value=\''.$child->get("title").'\';window.close();">(&bull;)</a> ';
		} else {
			$output .= "(&bull;) ";
		}
		$output .= '<a href="'.$child->getUrl("op=formAssetTree;classLimiter=".$session->form->process("classLimiter").";formId="
			.$session->form->process("formId")).'">'.$child->get("menuTitle").'</a>'."<br />\n";	
	}
	$session->style->useEmptyStyle("1")
	return $output;
}


#-------------------------------------------------------------------

sub www_richEditPageTree {
	my $session = shift;
	my $i18n = WebGUI::International->new($session);
	my $f = WebGUI::HTMLForm->new($session,-action=>"#",-extras=>'name"linkchooser"');
	$f->text(
		-name=>"url",
		-label=>$i18n->get(104),
		-hoverHelp=>$i18n->get('104 description'),
		);
	$f->selectBox(
		-name=>"target",
		-label=>$i18n->get('target'),
		-hoverHelp=>$i18n->get('target description'),
		-options=>{"_self"=>$i18n->get('link in same window'),
		           "_blank"=>$i18n->get('link in new window')},
		);
	$f->button(
		-value=>$i18n->get('done'),
		-extras=>'onclick="createLink()"'
		);
	$session->style->setScript($session->config->get("extrasURL")."/tinymce/jscripts/tiny_mce/tiny_mce_popup.js",{type=>"text/javascript"});
	my $output = '<fieldset><legend>Insert A Link</legend>
		<fieldset><legend>Link Settings</legend>'.$f->print.'</fieldset>
	<script type="text/javascript">
function createLink() {
    if (window.opener) {        
        if (document.getElementById("url_formId").value == "") {
           alert("'.$i18n->get("link enter alert").'");
           document.getElementById("url_formId").focus();
        }
window.opener.tinyMCE.insertLink("^" + "/" + ";" + document.getElementById("url_formId").value,document.getElementById("target_formId").value);
     window.close();
    }
}
</script><fieldset><legend>Pages</legend> ';
	my $base = WebGUI::Asset->newByUrl || WebGUI::Asset->getRoot;
	my @crumb;
	my $ancestors = $base->getLineage(["self","ancestors"],{returnObjects=>1});
	foreach my $ancestor (@{$ancestors}) {
		push(@crumb,'<a href="'.$ancestor->getUrl("op=richEditPageTree").'">'.$ancestor->get("menuTitle").'</a>');
	}	
	$output .= '<p>'.join(" &gt; ", @crumb)."</p>\n";
	my $children = $base->getLineage(["children"],{returnObjects=>1});
	foreach my $child (@{$children}) {
		next unless $child->canView;
		$output .= '<a href="#" onclick="document.getElementById(\'url_formId\').value=\''.$child->get("url").'\'">(&bull;)</a> <a href="'.$child->getUrl("op=richEditPageTree").'">'.$child->get("menuTitle").'</a>'."<br />\n";	
	}
	$session->style->useEmptyStyle("1")
	return $output.'</fieldset></fieldset>';
}



#-------------------------------------------------------------------
sub www_richEditImageTree {
	my $session = shift;
	my $base = WebGUI::Asset->newByUrl || WebGUI::Asset->getRoot;
	my @crumb;
	my $ancestors = $base->getLineage(["self","ancestors"],{returnObjects=>1});
	foreach my $ancestor (@{$ancestors}) {
		push(@crumb,'<a href="'.$ancestor->getUrl("op=richEditImageTree").'">'.$ancestor->get("menuTitle").'</a>');
	}	
	my $output = '<p>'.join(" &gt; ", @crumb)."</p>\n";
	my $children = $base->getLineage(["children"],{returnObjects=>1});
	foreach my $child (@{$children}) {
		next unless $child->canView;
		if ($child->get("className") =~ /^WebGUI::Asset::File::Image/) {
			$output .= '<a href="'.$child->getUrl("op=richEditViewThumbnail").'" target="viewer">(&bull;)</a> ';
		} else {
			$output .= "(&bull;) ";
		}
		$output .= '<a href="'.$child->getUrl("op=richEditImageTree").'">'.$child->get("menuTitle").'</a>'."<br />\n";	
	}
	$session->style->useEmptyStyle("1")
	return $output;
}


#-------------------------------------------------------------------
sub www_richEditViewThumbnail {
	my $session = shift;
	my $image = WebGUI::Asset->newByUrl;
	$session->style->useEmptyStyle("1")
	if ($image->get("className") =~ /WebGUI::Asset::File::Image/) {
		my $output = '<div align="center">';
		$output .= '<img src="'.$image->getThumbnailUrl.'" border="0" alt="Preview">';
		$output .= '<br />';
		$output .= $image->get("filename");
		$output .= '</div>';
		$output .= '<script type="text/javascript">';
		$output .= "\nvar src = '".$image->getFileUrl."';\n";
		$output .= "if(src.length > 0) {
				var manager=window.parent;
   				if(manager)		      	
		      		manager.document.getElementById('txtFileName').value = src;
    			}
    		    </script>\n";
		return $output;
	}
	return '<div align="center"><img src="'.$session->config->get("extrasURL").'/tinymce/images/icon.gif" border="0" alt="Image Manager"></div>';
}





1;

