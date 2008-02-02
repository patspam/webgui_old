package WebGUI::PseudoRequest;

use strict;

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

=head1 NAME

Package WebGUI::PseudoRequest

=head1 DESCRIPTION

This is an almost complete imitation of Apache2::Request.  You can use this package to
create a request object that will work with WebGUI, without actually being inside
the mod_perl environment.

Why in the world would you want to do this?  Well, when doing API testing sometimes
you run across things that require a request object, but you don't really want to
fire up Apache in order to do it.  This will let you bypass that.

=cut

package WebGUI::PseudoRequest::Headers;

#----------------------------------------------------------------------------

=head1 NAME

Package WebGUI::PseudoRequest::Headers

=head2 new

Construct a new PseudoRequest::Headers object.  This is just for holding headers.
It doesn't do any magic.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = { headers => {} };
	bless $self, $class;
	return $self;
}

#----------------------------------------------------------------------------

=head2 set( $key, $value )

Set a key, value pair in the header object.

=cut

sub set {
	my $self = shift;
	my $key = shift;
	my $value = shift;
	$self->{headers}->{$key} = $value;
}

#----------------------------------------------------------------------------

=head2 fetch

Returns the entire internal hashref of headers.

=cut

sub fetch {
	my $self = shift;
	return $self->{headers};
}

package WebGUI::PseudoRequest::Upload;

#----------------------------------------------------------------------------

=head1 NAME

Package WebGUI::PseudoRequest::Upload

=head2 new ( [$file] )

Construct a new PseudoRequest::Upload object.  This is just for holding headers.
It doesn't do any magic.

=head3 $file

The complete path to a file.  If this is sent to new, it will go ahead and open
a filehandle to that file for you, saving you the need to call the fh, filename
and filesize methods.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {
        fh       => undef,
        size     => 0,
        filename => '',
    };
    my $file = shift;
    if ($file and -e $file) {
        $self->{filename} = $file;
        $self->{size} = (stat $file)[7];
        open my $fh, '<' . $file or
            die "Unable to open $file for reading and creating a filehandle: $!\n";
        $self->{fh} = $fh;
    }
	bless $self, $class;
	return $self;
}

#----------------------------------------------------------------------------

=head2 fh ( [$value] )

Getter and setter for fh.  If $value is passed in, it will set the internal filehandle in
the object to that.  Returns the filehandle stored in the object.

=cut

sub fh {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{fh} = $value;
	}
	return $self->{fh};
}

#----------------------------------------------------------------------------

=head2 filaname ( [$value] )

Getter and setter for filename.  If $value is passed in, it will set the filename in
the object to that.  Returns the filename in the object.

=cut

sub filename {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{filename} = $value;
	}
	return $self->{filename};
}

#----------------------------------------------------------------------------

=head2 size ( [$value] )

Getter and setter for size.  If $value is passed in, it will set the internal size in
the object to that.  Returns the size stored in the object.

=cut

sub size {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{size} = $value;
	}
	return $self->{size};
}

package WebGUI::PseudoRequest;

#----------------------------------------------------------------------------

=head1 NAME

Package WebGUI::PseudoRequest

=head2 new

Construct a new PseudoRequest object.  Creates a new Headers object as well and places
it inside the PseudoRequest object.

=cut

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $headers = WebGUI::PseudoRequest::Headers->new();
	my $self = {headers_out => $headers};
	bless $self, $class;
	return $self;
}

#----------------------------------------------------------------------------

=head2 body ( [$value])

Compatibility method.  Returns the requested form value, $value.  If $value isn't passed in, returns
all form variables.

=cut


sub body {
	my $self = shift;
	my $value = shift;
	return keys %{ $self->{body} } unless defined $value;
	if ($self->{body}->{$value}) {
        if (wantarray && ref $self->{body}->{$value} eq "ARRAY") {
            return @{$self->{body}->{$value}};
        }
        elsif (ref $self->{body}->{$value} eq "ARRAY") {
            return $self->{body}->{$value}->[0];
        }
        else {
            return $self->{body}->{$value};
        }
    }
    else {
        if (wantarray) {
            return ();
        }
        else {
            return undef;
        }
    }
}

#----------------------------------------------------------------------------

=head2 setup_body ( $value )

Setup the object's body method so that it can be used.  $value should be a hash ref of named
form variables and values.

=cut

sub setup_body {
	my $self = shift;
	my $value = shift;
	$self->{body} = $value;
}

#----------------------------------------------------------------------------

=head2 content_type ( [$value] )

Getter and setter for content_type.  If $value is passed in, it will set the content_type of
the object to that.  Returns the content_type stored in the object.

=cut

sub content_type {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{content_type} = $value;
	}
	return $self->{content_type};
}

#----------------------------------------------------------------------------

=head2 headers_out ( )

Returns the PseudoRequst::Headers object stored in $self for access to the headers.

=cut

sub headers_out {
	my $self = shift;
	return $self->{headers_out}; ##return object for method chaining
}

#----------------------------------------------------------------------------

=head2 no_cache ( [$value] )

Getter and setter for no_cache.  If $value is passed in, it will set no_cache of
the object to that.  Returns the no_cache value stored in the object.

=cut

sub no_cache {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{no_cache} = $value;
	}
	return $self->{no_cache};
}

#----------------------------------------------------------------------------

=head2 param ( [$value])

Compatibility method.  Works exactly like the body method.

=cut

sub param {
	my $self = shift;
	my $value = shift;
	return keys %{ $self->{param} } unless defined $value;
	if ($self->{param}->{$value}) {
        if (wantarray && ref $self->{param}->{$value} eq "ARRAY") {
            return @{$self->{param}->{$value}};
        }
        elsif (ref $self->{param}->{$value} eq "ARRAY") {
            return $self->{param}->{$value}->[0];
        }
        else {
            return $self->{param}->{$value};
        }
    }
    else {
        if (wantarray) {
            return ();
        }
        else {
            return undef;
        }
    }
}

#----------------------------------------------------------------------------

=head2 setup_param ( $value )

Setup the object's param method so that it can be used.  $value should be a hash ref of named
form variables and values.

=cut

sub setup_param {
	my $self = shift;
	my $value = shift;
	$self->{param} = $value;
}

#----------------------------------------------------------------------------

=head2 protocol ( $value )

Getter and setter for protocol.  If $value is passed in, it will set the protocol of
the object to that.  Returns the protocol value stored in the object.

=cut

sub protocol {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{protocol} = $value;
	}
	return $self->{protocol};
}

#----------------------------------------------------------------------------

=head2 status ( $value )

Getter and setter for status.  If $value is passed in, it will set the status of
the object to that.  Returns the status value stored in the object.

=cut

sub status {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{status} = $value;
	}
	return $self->{status};
}

#----------------------------------------------------------------------------

=head2 status_line ( $value )

Getter and setter for status_line.  If $value is passed in, it will set the status_line of
the object to that.  Returns the status_line value stored in the object.

=cut

sub status_line {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{status_line} = $value;
	}
	return $self->{status_line};
}

#----------------------------------------------------------------------------

=head2 upload ( $formName, [ $uploadFileHandler ] )

Getter and setter for upload objects, which are indexed in this object by $formName.
Returns what was stored in the slot referred to as $formName.  If $formName is false,
it returns undef.

=head3 $uploadFileHandle.

$uploadFileHandle should be an array ref of WebGUI::PseudoRequest::Upload objects.  If you
pass it $uploadFileHandle, it will set store the object under the name, $formName.

=cut

sub upload {
	my $self = shift;
    my $formName = shift;
    my $uploadFileHandles = shift;
    return unless $formName;
	if (defined $uploadFileHandles) {
		$self->{uploads}->{$formName} = $uploadFileHandles;
	}
	return @{ $self->{uploads}->{$formName} };
}

#----------------------------------------------------------------------------

=head2 uploadFiles ( $formName, $filesToUpload )

Convenience method for uploading several files at once into the PseudoRequest object,
all to be referenced off of $formName.  If $formName is false, it returns undef.

=head3 $fileToUpload

$uploadFileHandle should be an array ref of complete paths to files.  The method will
create one PseudoRequest::Upload object per file, then store the array ref
using the upload method.

=cut

sub uploadFiles {
	my $self = shift;
    my $formName = shift;
    my $filesToUpload = shift;
    return unless $formName;
    return unless scalar $filesToUpload;
    my @uploadObjects = ();
    foreach my $file (@{ $filesToUpload }) {
        my $upload = WebGUI::PseudoRequest::Upload->new($file);
        push @uploadObjects, $upload;
    }
    $self->upload($formName, \@uploadObjects);
}

#----------------------------------------------------------------------------

=head2 uri ( $value )

Getter and setter for uri.  If $value is passed in, it will set the uri of
the object to that.  Returns the uri value stored in the object.

=cut

sub uri {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{uri} = $value;
	}
	return $self->{uri};
}

#----------------------------------------------------------------------------

=head2 user ( $value )

Getter and setter for user.  If $value is passed in, it will set the user of
the object to that.  Returns the user value stored in the object.

=cut

sub user {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{user} = $value;
	}
	return $self->{user};
}

1;
