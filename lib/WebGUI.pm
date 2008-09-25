package WebGUI;


our $VERSION = '7.5.24';
our $STATUS = "stable";


=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2008 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use Apache2::Const -compile => qw(OK DECLINED);
use Apache2::Request;
use Apache2::RequestIO;
use Apache2::ServerUtil ();
use WebGUI::Config;
use WebGUI::Pluggable;

=head1 NAME

Package WebGUI

=head1 DESCRIPTION

An Apache mod_perl handler for WebGUI.

=head1 SYNOPSIS

 use WebGUI;

=head1 SUBROUTINES

These subroutines are available from this package:

=cut

#-------------------------------------------------------------------

=head2 handler ( requestObject )

Primary http init/response handler for WebGUI.  This method decides whether to hand off the request to contentHandler() or uploadsHandler()

=head3 requestObject

The Apache2::RequestRec object passed in by Apache's mod_perl.

=cut

sub handler {
	my $request = shift;	#start with apache request object
    $request = Apache2::Request->new($request);
	my $configFile = shift || $request->dir_config('WebguiConfig'); #either we got a config file, or we'll build it from the request object's settings
	my $server = Apache2::ServerUtil->server;	#instantiate the server api
	my $config = WebGUI::Config->new($server->dir_config('WebguiRoot'), $configFile); #instantiate the config object
    my $error = "";
    my $matchUri = $request->uri;
    my $gateway = $config->get("gateway");
    $matchUri =~ s{^$gateway}{/};
	my $gotMatch = 0;
    WEBGUI_FATAL: foreach my $handler (@{$config->get("urlHandlers")}) {
        my ($regex) = keys %{$handler};
        if ($matchUri =~ m{$regex}i) {
            my $output = eval { WebGUI::Pluggable::run($handler->{$regex}, "handler", [$request, $server, $config]) };
            if ($@) {
				$error = $@;
                last;
            }
            else {
				$gotMatch = 1;
				if ($output ne Apache2::Const::DECLINED) {
					return $output;
				}
            }
        }
	}
	return Apache2::Const::DECLINED if ($gotMatch);
	
	# can't handle the url due to error or misconfiguration
    $request->push_handlers(PerlResponseHandler => sub { 
        print "This server is unable to handle the url '".$request->uri."' that you requested. ".$error;
        return Apache2::Const::OK;
    } );
	$request->push_handlers(PerlTransHandler => sub { return Apache2::Const::OK });
	return Apache2::Const::DECLINED; 
}




1;

