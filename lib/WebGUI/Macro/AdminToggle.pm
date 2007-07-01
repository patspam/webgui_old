package WebGUI::Macro::AdminToggle;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2007 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::International;
use WebGUI::Asset::Template;

=head1 NAME

Package WebGUI::Macro::AdminToggle

=head1 DESCRIPTION

Macro for displaying a url to the user for turning Admin mode on and off.

=head2 process ( [turnOn,turnOff,template ] )

process takes three optional parameters for customizing the content and layout
of the account link.

=head3 turnOn

The text displayed to the user if Admin mode is turned off and they are in the
Turn On Admin group.  If this is blank an internationalized default is used.

=head3 turnOff

The text displayed to the user if Admin mode is turned on and they are in the
Turn On Admin group.  If this is blank an internationalized default is used.

=head3 template

A template from the Macro/AdminToggle namespace to use for formatting the link.

=cut

#-------------------------------------------------------------------
sub process {
	my $session = shift;
         if ($session->user->isInGroup(12)) {
        	my %var;
                 my ($turnOn,$turnOff,$templateName) = @_;
	my $i18n = WebGUI::International->new($session,'Macro_AdminToggle');
              $turnOn ||= $i18n->get(516);
              $turnOff ||= $i18n->get(517);
                 if ($session->var->isAdminOn) {
                      $var{'toggle.url'} = $session->url->page('op=switchOffAdmin');
                      $var{'toggle.text'} = $turnOff;
                 } else {
                      $var{'toggle.url'} = $session->url->page('op=switchOnAdmin');
                      $var{'toggle.text'} = $turnOn;
                 }
		if ($templateName) {
         		return  WebGUI::Asset::Template->newByUrl($session,$templateName)->process(\%var);
		} else {
         		return  WebGUI::Asset::Template->new($session,"PBtmpl0000000000000036")->process(\%var);
		}
	}
       return "";
}

1;


