package WebGUI::URL::Content;

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
use WebGUI::Affiliate;
use WebGUI::Exception;
use WebGUI::Pluggable;
use WebGUI::Session;

=head1 NAME

Package WebGUI::URL::Content

=head1 DESCRIPTION

A URL handler that does whatever I tell it to do.

=head1 SYNOPSIS

 use WebGUI::URL::Content;
 my $status = WebGUI::URL::Content::handler($r, $s, $config);

=head1 SUBROUTINES

These subroutines are available from this package:

=cut

#-------------------------------------------------------------------

=head2 handler ( request, server, config ) 

The Apache request handler for this package.

=cut

sub handler {
    my ($request, $server, $config) = @_;
    $request->push_handlers(PerlResponseHandler => sub {
        my $session = WebGUI::Session->open($server->dir_config('WebguiRoot'), $config->getFilename, $request, $server);
        foreach my $handler (@{$config->get("contentHandlers")}) {
            my $output = WebGUI::Pluggable::run($handler, "handler", [ $session ] );
            if ( my $e = WebGUI::Error->caught ) {
                $session->errorHandler->error($e->package.":".$e->line." - ".$e->error);
                $session->errorHandler->debug($e->package.":".$e->line." - ".$e->trace);
            }
            elsif ( $@ ) {
                $session->errorHandler->error( $@ );
            }
            else {
                if ($output eq "chunked") {
                    if ($session->errorHandler->canShowDebug()) {
                        $session->output->print($session->errorHandler->showDebug(),1);
                    }
                    last;
                }
                elsif (defined $output && $output ne "") {
                    $session->http->sendHeader;
                    $session->output->print($output);
                    if ($session->errorHandler->canShowDebug()) {
                        $session->output->print($session->errorHandler->showDebug(),1);
                    }
                    last;
                }
                # Keep processing for success codes
                elsif ($session->http->getStatus < 200 || $session->http->getStatus > 299) {
                    $session->http->sendHeader;
                    last;
                } 
            }
        }
        $session->close;
        return Apache2::Const::OK;
    });
    $request->push_handlers(PerlTransHandler => sub { return Apache2::Const::OK });
    return Apache2::Const::OK;
}

1;

