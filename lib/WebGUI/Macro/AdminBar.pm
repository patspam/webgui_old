package WebGUI::Macro::AdminBar;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict qw(refs vars);
use WebGUI::AdminConsole;
use WebGUI::Asset;
use WebGUI::International;
use WebGUI::Macro;
use WebGUI::Utility;
use WebGUI::VersionTag;

=head1 NAME

Package WebGUI::Macro::AdminBar

=head1 DESCRIPTION

Macro for displaying administrative functions to a user with Admin turned on.

=head2 process ( )

process takes one optional parameters for customizing the layout of the Admin bar.

=cut


sub process {
	my $session = shift;
	return undef unless $session->var->isAdminOn;
	my $i18n = WebGUI::International->new($session,'Macro_AdminBar');
	my ($url, $style, $asset, $user, $config) = $session->quick(qw(url style asset user config));
	$style->setScript($url->extras('yui/build/utilities/utilities.js'), {type=>'text/javascript'});
	$style->setScript($url->extras('accordion/accordion.js'), {type=>'text/javascript'});
	$style->setLink($url->extras('macro/AdminBar/slidePanel.css'), {type=>'text/css', rel=>'stylesheet'});

	my $out = q{<dl class="accordion-menu">};

	# admin console
	my $ac = WebGUI::AdminConsole->new($session);
    $out .= q{<dt class="a-m-t">}.$i18n->get("admin console","AdminConsole").q{</dt><dd class="a-m-d"><div class="bd">};
	foreach my $item (@{$ac->getAdminFunction}) {
		next unless $item->{canUse};
		$out .= q{<a class="link" href="}.$item->{url}.q{">}
			.q{<img src="}.$item->{'icon.small'}.q{" style="border: 0px; vertical-align: middle;" alt="icon" /> }
			.$item->{title}.q{</a>};
	}
	$out .= qq{</div></dd>\n};

	# version tags
	my $versionTags = WebGUI::VersionTag->getOpenTags($session);
	if (scalar(@$versionTags)) {
		$out .= q{<dt class="a-m-t">}.$i18n->get("version tags","VersionTag").q{</dt><dd class="a-m-d"><div class="bd">};
		my $working = WebGUI::VersionTag->getWorking($session, 1);
		my $workingId = "";
		if ($working) {
			$workingId = $working->getId;
			my $commitUrl = "";
			if ($session->setting->get("skipCommitComments")) {
				$commitUrl = $url->page("op=commitVersionTagConfirm;tagId=".$workingId);
			}
			else {
				$commitUrl = $url->page("op=commitVersionTag;tagId=".$workingId);
			}
			$out .= q{<a class="link" href="}.$commitUrl.q{">}
				.q{<img src="}.$url->extras('adminConsole/small/versionTags.gif').q{" style="border: 0px; vertical-align: middle;" alt="icon" /> }
				.$i18n->get("commit my changes").q{</a>};
		}
		foreach my $tag (@{$versionTags}) {
			next unless $user->isInGroup($tag->get("groupToUse"));
			my $switchUrl = $url->page("op=" . ($tag->getId eq $workingId ? "editVersionTag" : "setWorkingVersionTag") . ";backToSite=1;tagId=".$tag->getId);
			my $title = ($tag->getId eq $workingId) ?  '<span style="color: #000080;">* '.$tag->get("name").'</span>' : $tag->get("name");
			$out .= q{<a class="link" href="}.$switchUrl.q{">}.$title.q{</a>};
		}
		$out .= qq{</div></dd>\n};
	}

	
	# stuff to do if we're on a page with an asset
	if ($asset) {
		
        my $proceed = $session->form->get('op') eq 'assetManager' ?  ';proceed=manageAssets' : '';
		# clipboard
		my $clipboardItems = $session->asset->getAssetsInClipboard(1);
		if (scalar (@$clipboardItems)) {
			$out .= q{<dt class="a-m-t">}.$i18n->get("1082").q{</dt><dd class="a-m-d"><div class="bd">};
			foreach my $item (@{$clipboardItems}) {
				my $title = $asset->getTitle;
				$out .= q{<a class="link" href="}.$asset->getUrl("func=pasteList;assetId=".$item->getId.$proceed).q{">}
					.q{<img src="}.$item->getIcon(1).q{" style="border: 0px; vertical-align: middle;" alt="icon" /> }
					.$item->getTitle.q{</a>};
			}
			$out .= qq{</div></dd>\n};
		}

		### new content menu

		# determine new content categories
		my %rawCategories = %{$config->get('assetCategories')};
		my %categories;
		my %categoryTitles;
		my $userUiLevel = $user->profileField('uiLevel');
		foreach my $category (keys %rawCategories) {
			next if $rawCategories{$category}{uiLevel} > $userUiLevel;
			next if (exists $rawCategories{$category}{group} && !$user->isInGroup($rawCategories{$category}{group}));
			my $title = $rawCategories{$category}{title};
			WebGUI::Macro::process($session, \$title);
			$categories{$category}{title} = $title;
			$categoryTitles{$title} = $category;
		}

		# assets
		my %assetList = %{$config->get('assets')};
		foreach my $assetClass (keys %assetList) {
			my $dummy = WebGUI::Asset->newByPropertyHashRef($session,{dummy=>1, className=>$assetClass});
            next unless defined $dummy;
			next if $dummy->getUiLevel($assetList{$assetClass}{uiLevel}) > $userUiLevel;
			next unless ($dummy->canAdd($session));
			next unless exists $categories{$assetList{$assetClass}{category}};
			$categories{$assetList{$assetClass}{category}}{items}{$dummy->getTitle} = {
				icon	=> $dummy->getIcon(1),
				url		=> $asset->getUrl("func=add;class=".$dummy->get('className').$proceed),
				};
		}

		# packages
		foreach my $package (@{$session->asset->getPackageList}) {
			next unless ($package->canView && $package->canAdd($session) && $package->getUiLevel <= $userUiLevel);
            $categories{packages}{items}{$package->getTitle} = {
				url		=> $asset->getUrl("func=deployPackage;assetId=".$package->getId.$proceed),
				icon	=> $package->getIcon(1),
				};
        }
		if (scalar keys %{$categories{packages}{items}}) {
			$categories{packages}{title} = $i18n->get('packages');
			$categoryTitles{$i18n->get('packages')} = "packages";
		}
		
		# prototypes
		foreach my $prototype (@{ $session->asset->getPrototypeList }) {
			next unless ($prototype->canView && $prototype->canAdd($session) && $prototype->getUiLevel <= $userUiLevel);
            $categories{prototypes}{items}{$prototype->getTitle} = {
				url		=> $asset->getUrl("func=add;class=".$prototype->get('className').";prototype=".$prototype->getId.$proceed),
				icon	=> $prototype->getIcon(1),
				};
		}
		if (scalar keys %{$categories{prototypes}{items}}) {
			$categories{prototypes}{title} = $i18n->get('prototypes');
			$categoryTitles{$i18n->get('prototypes')} = "prototypes";
		}
		
		# render new content menu
	    $out .= q{<dt id="newContentMenu" class="a-m-t">}.$i18n->get("1083").q{</dt><dd class="a-m-d"><div class="bd">};
		foreach my $categoryTitle (sort keys %categoryTitles) {
			$out .= '<div class="ncmct">'.$categoryTitle.'</div>';
			my $items = $categories{$categoryTitles{$categoryTitle}}{items};
			next unless (ref $items eq 'HASH'); # in case the category is empty
			foreach my $title (sort keys %{$items}) {
				$out .= q{<a class="link" href="}.$items->{$title}{url}.q{">}
					.q{<img src="}.$items->{$title}{icon}.q{" style="border: 0px; vertical-align: middle;" alt="icon" /> }
					.$title.q{</a>};
			}
			$out .= '<br />';
		}
		$out .= qq{</div></dd>\n};
	}
	
	$out .= q{</dl>
	<script type="text/javascript">
	    YAHOO.util.Event.on(window, "load", function () { document.body.style.marginLeft = "160px"; });
		AccordionMenu.openDtById("newContentMenu");
	</script>};
	return $out;
}

1;

