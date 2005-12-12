package WebGUI::Style;

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
use Tie::CPHash;
use WebGUI::International;
use WebGUI::Macro;
use WebGUI::Session;
use WebGUI::Asset::Template;
use WebGUI::URL;

=head1 NAME

Package WebGUI::Style

=head1 DESCRIPTION

This package contains utility methods for WebGUI's style system.

=head1 SYNOPSIS

 use WebGUI::Style;
 $html = WebGUI::Style::process($content);

 $html = generateAdditionalHeadTags();
 setLink($url,\%params);
 setMeta(\%params);
 setRawHeadTags($html);
 setScript($url, \%params);

=head1 SUBROUTINES 

These subroutines are available from this package:

=cut

#-------------------------------------------------------------------

=head2 generateAdditionalHeadTags ( )

Creates tags that were set using setLink, setMeta, setScript, extraHeadTags, and setRawHeadTags.

=cut

sub generateAdditionalHeadTags {
	# generate additional raw tags
	my $tags = $session{page}{head}{raw};
        # generate additional link tags
	foreach my $url (keys %{$session{page}{head}{link}}) {
		$tags .= '<link href="'.$url.'"';
		foreach my $name (keys %{$session{page}{head}{link}{$url}}) {
			$tags .= ' '.$name.'="'.$session{page}{head}{link}{$url}{$name}.'"';
		}
		$tags .= ' />'."\n";
	}
	# generate additional javascript tags
	foreach my $tag (@{$session{page}{head}{javascript}}) {
		$tags .= '<script';
		foreach my $name (keys %{$tag}) {
			$tags .= ' '.$name.'="'.$tag->{$name}.'"';
		}
		$tags .= '></script>'."\n";
	}
	# generate additional meta tags
	foreach my $tag (@{$session{page}{head}{meta}}) {
		$tags .= '<meta';
		foreach my $name (keys %{$tag}) {
			$tags .= ' '.$name.'="'.$tag->{$name}.'"';
		}
		$tags .= ' />'."\n";
	}
	# append extraHeadTags
	$tags .= $session{asset}->getExtraHeadTags."\n" if ($session{asset});
	
	delete $session{page}{head};
	return $tags;
}


#-------------------------------------------------------------------

=head2 process ( content, templateId )

Returns a parsed style with content based upon the current WebGUI session information.

=head3 content

The content to be parsed into the style. Usually generated by WebGUI::Page::generate().

=head3 templateId

The unique identifier for the template to retrieve. 

=cut

sub process {
	my %var;
	$var{'body.content'} = shift;
	my $templateId = shift;
	if ($session{page}{makePrintable} && exists $session{asset}) {
		$templateId = $session{asset}->get("printableStyleTemplateId");
		my $currAsset = $session{asset};
		until ($templateId) {
			# some assets don't have this property.  But at least one ancestor should....
			$currAsset = $currAsset->getParent;
			$templateId = $currAsset->get("printableStyleTemplateId");
		}
	} elsif ($session{scratch}{personalStyleId} ne "") {
		$templateId = $session{scratch}{personalStyleId};
	} elsif ($session{page}{useEmptyStyle}) {
		$templateId = 6;
	}
$var{'head.tags'} = '
<meta name="generator" content="WebGUI '.$WebGUI::VERSION.'" />
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<script type="text/javascript">
function getWebguiProperty (propName) {
var props = new Array();
props["extrasURL"] = "'.$session{config}{extrasURL}.'";
props["pageURL"] = "'.WebGUI::URL::page(undef, undef, 1).'";
return props[propName];
}
</script>
';
if (WebGUI::Grouping::isInGroup(2)) {
	# This "triple incantation" panders to the delicate tastes of various browsers for reliable cache suppression.
	$var{'head.tags'} .= '
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Cache-Control" content="no-cache, must-revalidate, max-age=0" />
<meta http-equiv="Expires" content="0" />
';
}
	$var{'head.tags'} .= "\n<!-- macro head tags -->\n";
	my $style = WebGUI::Asset::Template->new($templateId);
	my $output;
	if (defined $style) {
		$output = $style->process(\%var);
	} else {
		$output = "WebGUI was unable to instantiate your style template.".$var{'body.content'};
	}
	WebGUI::Macro::process(\$output);
	my $macroHeadTags = generateAdditionalHeadTags();
	WebGUI::Macro::process(\$macroHeadTags);
	$output =~ s/\<\!-- macro head tags --\>/$macroHeadTags/;
	return $output;
}	


#-------------------------------------------------------------------

=head2 setLink ( url, params )

Sets a <link> tag into the <head> of this rendered page for this page view. This is typically used for dynamically adding references to CSS and RSS documents.

=head3 url

The URL to the document you are linking.

=head3 params

A hash reference containing the other parameters to be included in the link tag, such as "rel" and "type".

=cut

sub setLink {
	my $url = shift;
	my $params = shift;
	$session{page}{head}{link}{$url} = $params;
}



#-------------------------------------------------------------------

=head2 setMeta ( params )

Sets a <meta> tag into the <head> of this rendered page for this page view. 

=head3 params

A hash reference containing the parameters of the meta tag.

=cut

sub setMeta {
	my $params = shift;
	push(@{$session{page}{head}{meta}},$params);
}



#-------------------------------------------------------------------

=head2 setRawHeadTags ( tags )

Sets data to be output into the <head> of the current rendered page for this page view.

=head3 tags

A raw string containing tags. This is just a raw string so you must actually pass in the full tag to use this call.

=cut

sub setRawHeadTags {
	my $tags = shift;
	$session{page}{head}{raw} .= $tags;
}


#-------------------------------------------------------------------

=head2 setScript ( url, params )

Sets a <script> tag into the <head> of this rendered page for this page view. This is typically used for dynamically adding references to Javascript or ECMA script.

=head3 url

The URL to your script.

=head3 params

A hash reference containing the additional parameters to include in the script tag, such as "type" and "language".

=cut

sub setScript {
	my $url = shift;
	my $params = shift;
	$params->{src} = $url;
	my $found = 0;
	foreach my $script (@{$session{page}{head}{javascript}}) {
		$found = 1 if ($script->{src} eq $url);
	}
	push(@{$session{page}{head}{javascript}},$params) unless ($found);	
}


1;
