package WebGUI::Asset::RssAspectDummy;

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
use Tie::IxHash;
use Class::C3;
use base qw/WebGUI::AssetAspect::RssFeed WebGUI::Asset/;

=head1 NAME

Package WebGUI::Asset::RssAspectDummy

=head1 DESCRIPTION

A dummy module for testing the RssAspect.  The module really doesn't
do anything, except provide suport modules for testing.

The module inherits directly from WebGUI::Asset.

=head1 SYNOPSIS

use WebGUI::Asset::RssAspectDummy;

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 getRssFeedItems ( )

Returns an arrayref of hashrefs, containing information on stories
for generating an RSS and Atom feeds.

=cut

sub getRssFeedItems {

return [
    {
        title       => 'this title',
        description => 'this description',
        'link'      => 'this link',
        author      => 'this author',
        date        => 'this date',
    },
    {
        title       => 'another title',
        description => 'another description',
        'link'      => 'another link',
        author      => 'another author',
        date        => 'another date',
    },
];

}

1;

#vim:ft=perl
