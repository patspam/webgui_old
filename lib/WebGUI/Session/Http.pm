package WebGUI::Session::HTTP;

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
use Apache2::Cookie;
use APR::Request::Apache2;

=head1 NAME

Package WebGUI::Session::Http

=head1 DESCRIPTION

This package allows the manipulation of HTTP protocol information.

=head1 SYNOPSIS

 use WebGUI::Session::Http;

 my $http = WebGUI::Session::Http->new($session);

 $cookies = $http->getCookies();
 $header = $http->getHeader();
 $mimetype = $http->getMimeType();
 $code = $http->getStatus();
 $boolean = $http->isRedirect();
 
 $http->setCookie($name,$value);
 $http->setFilename($filename,$mimetype);
 $http->setMimeType($mimetype);
 $http->setNoHeader($bool);
 $http->setRedirect($url);

=head1 METHODS

These methods are available from this package:

=cut



#-------------------------------------------------------------------

=head2 getCookies ( )

Retrieves the cookies from the HTTP header and returns a hash reference containing them.

=cut

sub getCookies {
	my $self = shift;
	return APR::Request::Apache2->handle($self->session->request)->jar();
}


#-------------------------------------------------------------------

=head2 getHeader ( ) 

Generates an HTTP header.

=cut

sub getHeader {
	my $self = shift;
	return undef if ($self->{_http}{noHeader});
	my %params;
	if ($self->isRedirect()) {
		$self->session->request->headers_out->set(Location => $self->{_http}{location});
		$self->session->request->status(301);
	} else {
		$self->session->request->content_type($self->{_http}{mimetype} || "text/html");
		if ($self->session->setting->get("preventProxyCache")) {
			$params{"-expires"} = "-1d";
		}
		if ($session{http}{filename}) {
			$params{"-attachment"} = $self->{_http}{filename};
		}
	}
	$params{"-cookie"} = $self->{_http}{cookie};
	$self->session->request->status_line($self->getStatus().' '.$self->{_http}{statusDescription}) if $self->session->request;
	return;
}


#-------------------------------------------------------------------

=head2 getMimeType ( ) 

Returns the current mime type of the document to be returned.

=cut

sub getMimeType {
	my $self = shift;
	return $self->{_http}{mimetype} || "text/html";
}


#-------------------------------------------------------------------

=head2 getStatus ( ) {

Returns the current HTTP status code, if one has been set.

=cut

sub getStatus {
	my $self = shift;
	$self->{_http}{statusDescription} = $self->{_http}{statusDescription} || "OK";
	return $self->{_http}{status} || "200";
}


#-------------------------------------------------------------------

=head2 isRedirect ( )

Returns a boolean value indicating whether the current page will redirect to some other location.

=cut

sub isRedirect {
	my $self = shift;
	return ($self->getStatus() eq "302");
}


#-------------------------------------------------------------------

=head2 new ( session )

Constructor. 

=head3 session

A reference to the current session.

=cut

sub new {
	my $class = shift;
	my $session = shift;
	bless {_session=>$session}, $class;
}


#-------------------------------------------------------------------

=head2 session ( )

Returns the reference to the current session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}

#-------------------------------------------------------------------

=head2 setCookie ( name, value [ , timeToLive ] ) 

Sends a cookie to the browser.

=head3 name

The name of the cookie to set. Must be unique from all other cookies from this domain or it will overwrite that cookie.

=head3 value

The value to set.

=head3 timeToLive

The time that the cookie should remain in the browser. Defaults to "+10y" (10 years from now).

=cut

sub setCookie {
	my $self = shift;
	my $name = shift;
	my $value = shift;
	my $ttl = shift;
	$ttl = (defined $ttl ? $ttl : '+10y');
	if (exists $self->session->request) {
		my $cookie = Apache2::Cookie->new($self->session->request,
			-name=>$name,
			-value=>$value,
	#		-domain=>'.'.$session{env}{HTTP_HOST},
			-expires=>$ttl,
			-path=>'/'
		);
		$cookie->bake($self->session->request);
	}
}


#-------------------------------------------------------------------

=head2 setFilename ( filename [, mimetype] )

Override the default filename for the document, which is usually the page url. Usually used with setMimeType().

=head3 filename

The filename to set.

=head3 mimetype

The mimetype for this file. Defaults to "application/octet-stream".

=cut

sub setFilename {
	my $self = shift;
	$self->{_http}{filename} = shift;
	my $mimetype = shift || "application/octet-stream";
	$self->setMimeType($mimetype);
}



#-------------------------------------------------------------------

=head2 setMimeType ( mimetype )

Override mime type for the document, which is defaultly "text/html". Also see setFilename().

B<NOTE:> By setting the mime type to something other than "text/html" WebGUI will automatically not process the normal page contents. Instead it will return only the content of your Wobject function or Operation.

=head3 mimetype

The mime type for the document.

=cut

sub setMimeType {
	my $self = shift;
	$self->{_http}{mimetype} = shift;
}

#-------------------------------------------------------------------

=head2 setNoHeader ( boolean )

Disables the printing of a HTTP header. Useful in situations when content is not
returned to a browser (export to disk for example).

=head3 boolean 

Any value other than 0 will disable header printing.

=cut

sub setNoHeader {
	my $self = shift;
        $self->{_http}{noHeader} = shift;
}

#-------------------------------------------------------------------

=head2 setRedirect ( url )

Sets the necessary information in the HTTP header to redirect to another URL.

=head3 url

The URL to redirect to.

=cut

sub setRedirect {
	my $self = shift;
	$self->{_http}{location} = shift;
	$self->setStatus("302", "Redirect");
	$self->session->style->setMeta({"http-equiv"=>"refresh",content=>"0; URL=".$self->{_http}{location}});
}


#-------------------------------------------------------------------

=head2 setStatus ( code, description )

Sets the HTTP status code.

=head3 code

An HTTP status code. It is a 3 digit status number.

=head3 description

An HTTP status code description. It is a little one line of text that describes the status code.

=cut

sub setStatus {
	my $self = shift;
	$self->{_http}{status} = shift;
	$self->{_http}{statusDescription} = shift;
}

1;

