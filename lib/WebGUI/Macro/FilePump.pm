package WebGUI::Macro::FilePump;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::FilePump::Bundle;
use Path::Class;

=head1 NAME

Package WebGUI::Macro::Build

=head1 DESCRIPTION

Macro to access FilePump bundle information.

=head2 process( $session, $bundleName, $type )

Deliver the bundle files.  If in admin mode, give raw links to the files.
If not in admin mode, give links to the bundled, minified files.

=over 4

=item *

A session variable

=item *

$bundleName, the name of a File Pump bundle.

=item *

$type, the type of files from the Bundle that you are accessing.  Either JS or javascript, or CSS or css.

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session    = shift;
	my $bundleName = shift;
	my $type       = shift;
    $type          = lc $type;
	my $output     = "";

    my $bundleId = WebGUI::FilePump::Bundle->getAllIds($session, {
        constraints => [ { 'bundleName = ?' => [$bundleName]}, ], 
        limit       => 1,
    });
    return '' unless $bundleId and $bundleId->[0];

    my $bundle = WebGUI::FilePump::Bundle->new($session, $bundleId->[0]);
    return '' unless $bundle;
    my $uploadsDir = Path::Class::Dir->new($session->config->get('uploadsPath'));
    my $uploadsUrl = Path::Class::Dir->new($session->config->get('uploadsURL'));

    ##Normal mode
    if (! $session->var->isAdminOn) {
        my $dir = $bundle->getPathClassDir->relative($uploadsDir);
        if ($type eq 'js' || $type eq 'javascript') {
            my $file = $uploadsUrl->file($dir, $bundle->bundleUrl . '.js');
            return sprintf qq|<script type="text/javascript" src="%s">\n|, $file->stringify;
        }
        elsif ($type eq 'css') {
            my $file = $uploadsUrl->file($dir, $bundle->bundleUrl . '.css');
            return sprintf qq|<link rel="stylesheet" type="text/css" href="%s">\n|, $file->stringify;
        }
        else {
            return '';
        }
    }
    ##Admin/Design mode
    else {
        my $template;
        my $files;
        if ($type eq 'js' || $type eq 'javascript') {
            $template = qq|<script type="text/javascript" src="%s">\n|;
            $files    = $bundle->get('jsFiles');
        }
        elsif ($type eq 'css') {
            $template = qq|<link rel="stylesheet" type="text/css" href="%s">\n|;
            $files    = $bundle->get('cssFiles');
        }
        else {
            return '';
        }
        foreach my $file (@{ $files }) {
            my $uri    = URI->new($file->{uri});
            my $scheme = $uri->scheme;
            my $url = '';
            if ($scheme eq 'asset') {
                $url = $uri->opaque;
            }
            elsif ($scheme eq 'file') {
                my $file           = Path::Class::File->new($uri->path);
                my $uploadsRelFile = $file->relative($uploadsDir);
                $url               = $uploadsUrl->file($uploadsRelFile)->stringify;

            }
            elsif ($scheme eq 'http' or $scheme eq 'https') {
                $url = $uri->as_string;
            }
            $url =~ tr{/}{/}s;
            $output .= sprintf $template, $url;
        }
        return $output;
    }
	return '';
}

1;

#vim:ft=perl
