package WebGUI::Operation::Cache;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2005 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::AdminConsole;
use WebGUI::Cache;
use WebGUI::International;
use WebGUI::Privilege;
use WebGUI::Session;
use WebGUI::Form;

=head1 NAME

Package WebGUI::Operation::Cache

=head1 DESCRIPTION

Operational handler for caching functions.

=cut

#-------------------------------------------------------------------

=head2 _submenu ( $workarea [,$title ] )

Internal subroutine for rendering output with an Admin Console.  Returns
the rendered output.

=head3 $workarea

The output that should be wrapped with an Admin Console.

=head3 $title

An optional title for the Admin Console.  If it evaluates to true,  the title
is looked up in the i18n table in the WebGUI namespace.

=cut

sub _submenu {
	my $workarea = shift;
	my $title = shift;
	$title = WebGUI::International::get($title) if ($title);
	my $ac = WebGUI::AdminConsole->new("cache");
	if ($session{setting}{trackPageStatistics}) {
		$ac->addSubmenuItem( WebGUI::URL::page('op=manageCache'), WebGUI::International::get('manage cache'));
	}
        return $ac->render($workarea, $title);
}


#-------------------------------------------------------------------

=head2 www_flushCache ( duration )


This method can be called directly, but is usually called from
www_manageCache. It flushes the cache.  Afterwards, it calls
www_manageCache.

=head3 duration

Text description of how long the subscription lasts.

=cut

sub www_flushCache {
        return WebGUI::Privilege::adminOnly() unless (WebGUI::Grouping::isInGroup(3));
	my $cache = WebGUI::Cache->new();
	$cache->flush;
	return www_manageCache();
}

#-------------------------------------------------------------------

=head2 www_manageCache ( )

Display information about the current cache type and cache statistics.  Also
provides an option to clear the cache.

=cut

sub www_manageCache {
        return WebGUI::Privilege::adminOnly() unless (WebGUI::Grouping::isInGroup(3));
        my ($output, $data);
	my $cache = WebGUI::Cache->new();
	my $flushURL =  WebGUI::URL::page('op=flushCache');
        $output .= '<table>';
        $output .= '<tr><td align="right" class="tableHeader">'.WebGUI::International::get('cache type').':</td><td class="tableData">'.ref($cache).'</td></tr>';
        $output .= '<tr><td align="right" valign="top" class="tableHeader">'.WebGUI::International::get('cache statistics').':</td><td class="tableData"><pre>'.$cache->stats.'</pre></td></tr>';
        $output .= '<tr><td align="right" valign="top" class="tableHeader">&nbsp;</td><td class="tableData">'.
			WebGUI::Form::button({
				value=>WebGUI::International::get("clear cache"),
				extras=>qq{onclick="document.location.href='$flushURL';"},
			}).
		   '</td></tr>';

	$output .= "</table>";
        return _submenu($output);
}


1;

