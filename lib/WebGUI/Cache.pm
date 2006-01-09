package WebGUI::Cache;

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

use File::Path;
use HTTP::Headers;
use HTTP::Request;
use LWP::UserAgent;

=head1 NAME

Package WebGUI::Cache

=head1 DESCRIPTION

A base class for all Cache modules to extend.

=head1 SYNOPSIS

 use WebGUI::Cache;

=head1 METHODS

These methods are available from this class:

=cut


#-------------------------------------------------------------------

=head2 delete ( )

Delete a key from the cache. Must be overridden.

=cut

sub delete {

}

#-------------------------------------------------------------------

=head2 deleteChunk ( key )

Deletes a bunch of keys from the cache based upon a partial composite key. Unless overridden by the cache subclass this will just flush the whole cache.

=head3 key

An array reference representing the portion of the key to delete. So if you have a key like ["asset","abc","def"] and you want to delete all items that match abc, you'd specify ["asset","abc"].

=cut

sub deleteChunk {
	$self = shift;
	$self->flush;
}

#-------------------------------------------------------------------

=head2 flush ( )

Flushes the caching system. Must be overridden.

=cut

sub flush {
	my $self = shift;
	rmtree($self->session->config->get("uploadsPath")."/temp");
}

#-------------------------------------------------------------------

=head2 get ( )

Retrieves a key value from the cache. Must be overridden.

=cut

sub get {

}


#-------------------------------------------------------------------

=head2 new ( session, key, [ namepsace ] )

The new method will return a handler for the configured caching mechanism.  Defaults to WebGUI::Cache::FileCache. You must override this method when building your own cache plug-in.

=head3 session

A reference to the current session.

=head3 key

A key to store the value under or retrieve it from.

=head3 namespace

A subdivider to store this cache under. When building your own cache plug-in default this to the WebGUI config file.

=cut

sub new {
	my $cache;
	my $class = shift;
	my $session = shift;
	if($session->config->get("memcached_servers")) {
		require WebGUI::Cache::Memcached;
		return WebGUI::Cache::Memcached->new($session,@_);
	} else {
		require WebGUI::Cache::FileCache;
		return WebGUI::Cache::FileCache->new($session,@_);
	}
}

#-------------------------------------------------------------------

=head2 parseKey ( key ) 

Returns a formatted string version of the key. A class method.

=head3 key

Can either be a text key, or a composite key. If it's a composite key, it will be an array reference of strings that can be joined together to create a key. You might want to use a composite key in order to be able to delete large portions of cache all at once. For instance, if you have a key of ["asset","abc","def"] you can delete all cache matching ["asset","abc"].

=cut

sub parseKey {
	my $class = shift;
	my $key = shift;
	if (ref $key eq "ARRAY") {
		my @parts = @{$key};
		my @fixed;
		foreach my $part (@parts) {
			$part = Digest::MD5::md5_base64($part);
        		$part =~ s/\//-/g;
			push(@fixed,$part);
		}
		return join('/',@fixed);
	} else {
		$key = Digest::MD5::md5_base64($key);
                $key =~ s/\//-/g;
		return $key;
	}
}

#-------------------------------------------------------------------

=head2 session ( ) 

Returns a reference session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}

#-------------------------------------------------------------------

=head2 set ( value [, ttl] )

Sets a key value to the cache. Must be overridden.

=head3 value

A scalar value to store.

=head3 ttl

A time in seconds for the cache to exist. When you override default it to 60 seconds.

=cut

sub set {

}


#-------------------------------------------------------------------

=head2 setByHTTP ( url [, ttl ] )

Retrieves a document via HTTP and stores it in the cache and returns the content as a string. No need to override.

=head3 url

The URL of the document to retrieve. It must begin with the standard "http://".

=head3 ttl

The time to live for this content. This is the amount of time (in seconds) that the content will remain in the cache. Defaults to "60".

=cut

sub setByHTTP {
	my $self = shift;
	my $url = shift;
	my $ttl = shift;
        my $userAgent = new LWP::UserAgent;
        $userAgent->agent("WebGUI/".$WebGUI::VERSION);
        $userAgent->timeout(30);
        my $header = new HTTP::Headers;
        my $referer = "http://webgui.http.request/".$self->session->env->get("SERVER_NAME").$self->session->env->get("REQUEST_URI");
        chomp $referer;
        $header->referer($referer);
        my $request = new HTTP::Request (GET => $url, $header);
        my $response = $userAgent->request($request);
        if ($response->is_error) {
                $self->session->errorHandler->error($url." could not be retrieved.");
        } else {
                $self->set($response->content,$ttl);
        }
        return $response->content;
}

#-------------------------------------------------------------------

=head2 stats ( )

Return a formatted text string describing cache usage. Must be overridden.

=cut

sub stats {

}


1;


