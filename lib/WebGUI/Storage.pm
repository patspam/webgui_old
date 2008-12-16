package WebGUI::Storage;

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
use warnings;
use Archive::Tar;
use Carp qw( croak );
use Cwd ();
use File::Copy ();
use File::Find ();
use File::Path ();
use File::Spec;
use Image::Magick;
use Storable ();
use WebGUI::Utility qw(isIn);


=head1 NAME

Package WebGUI::Storage

=head1 DESCRIPTION

This package provides a mechanism for storing and retrieving files that are not put into the database directly.

=head1 SYNOPSIS

 use WebGUI::Storage;
 $store = WebGUI::Storage->create($self->session);
 $store = WebGUI::Storage->createTemp($self->session);
 $store = WebGUI::Storage->get($self->session,$id);

 $filename = $store->addFileFromFilesystem($pathToFile);
 $filename = $store->addFileFromFormPost($formVarName,$attachmentLimit);
 $filename = $store->addFileFromHashref($filename,$hashref);
 $filename = $store->addFileFromScalar($filename,$content);

 $arrayref = $store->getErrors;
 $integer = $store->getErrorCount;
 $hashref = $store->getFileContentsAsHashref($filename);
 $string = $store->getFileContentsAsScalar($filename);
 $string = $store->getFileExtension($filename);
 $url = $store->getFileIconUrl($filename);
 $arrayref = $store->getFiles;
 $string = $store->getFileSize($filename);
 $guid = $store->getId;
 $string = $store->getLastError;
 $string = $store->getPath($filename);
 $string = $store->getUrl($filename);

 $newstore = $store->copy;
 $newstore = $store->tar($filename);
 $newstore = $store->untar($filename);


 $store->copyFile($filename, $newFilename);
 $store->delete;
 $store->deleteFile($filename);
 $store->renameFile($filename, $newFilename);
 $store->setPrivileges($userId, $groupIdView, $groupIdEdit);

 my $boolean = $self->generateThumbnail($filename);
 my $url = $self->getThumbnailUrl($filename);
 my $boolean = $self->isImage($filename);
 my ($captchaFile, $challenge) = $self->addFileFromCaptcha;
 $self->resize($imageFile, $width, $height);

=head1 METHODS

These methods are available from this package:

=cut


#-------------------------------------------------------------------

=head2 _addError ( errorMessage )

Adds an error message to the object.

NOTE: This is a private method and should never be called except internally to this package.

=head3 errorMessage

The error message to add to the object.

=cut

sub _addError {
	my $self = shift;
	my $errorMessage = shift;
	push(@{$self->{_errors}},$errorMessage);
	$self->session->errorHandler->error($errorMessage);
}


#-------------------------------------------------------------------

=head2 _makePath ( )

Creates the filesystem folders for a storage location.

NOTE: This is a private method and should never be called except internally to this package.

=cut

sub _makePath {
	my $self = shift;
	my $node = $self->session->config->get("uploadsPath");
	foreach my $folder (@{ $self->{_pathParts} }) {
		$node .= '/'.$folder;
		unless (-e $node) { # check to see if it already exists
			if (mkdir($node)) { # check to see if there was an error during creation
                $self->_changeOwner($node);
            }
            else {
				$self->_addError("Couldn't create storage location: $node : $!");
			}
		}
	}
}

#-------------------------------------------------------------------

=head2 _changeOwner ( )

Changes the owner to be the same as that of the uploads directory

NOTE: This is a private method and should never be called except internally to this package.

=cut

sub _changeOwner {
    my $self = shift;
    # Don't change owner if we're on windows or not the superuser
    return
        if ($^O eq 'MSWin32' || $> != 0);
    my $uploads = $self->session->config->get("uploadsPath");
    my ($uid, $gid) = (stat($uploads))[4,5];
    chown $uid, $gid, @_;
}

#-------------------------------------------------------------------

=head2 addFileFromCaptcha ( )

Generates a captcha image (200x x 50px) and returns the filename and challenge string (6 random characters). For more information about captcha, consult the Wikipedia here: http://en.wikipedia.org/wiki/Captcha

=cut 

sub addFileFromCaptcha {
	my $self = shift;
    my $error = "";
	my $challenge;
	$challenge .= ('A'..'Z')[rand(26)] foreach (1..6);
	my $filename = "captcha.".$self->session->id->generate().".gif";
	my $image = Image::Magick->new();
	$error = $image->Set(size=>'200x50');
	if($error) {
        $self->session->errorHandler->warn("Error setting captcha image size: $error");
    }
    $error = $image->ReadImage('xc:white');
	if($error) {
        $self->session->errorHandler->warn("Error initializing image: $error");
    }
    $error = $image->AddNoise(noise=>"Multiplicative");
	if($error) {
        $self->session->errorHandler->warn("Error adding noise: $error");
    }
    # AddNoise generates a different average color depending on library.  This is ugly, but the best I can see for now
    $error = $image->Annotate(font=>$self->session->config->getWebguiRoot."/lib/default.ttf", pointsize=>40, skewY=>0, skewX=>0, gravity=>'center', fill=>'#ffffff', antialias=>'true', text=>$challenge);
	if($error) {
        $self->session->errorHandler->warn("Error Annotating image: $error");
    }
    $error = $image->Draw(primitive=>"line", points=>"5,5 195,45", stroke=>'#ffffff', antialias=>'true', strokewidth=>2);
	if($error) {
        $self->session->errorHandler->warn("Error drawing line: $error");
    }
    $error = $image->Blur(geometry=>"9");
	if($error) {
        $self->session->errorHandler->warn("Error blurring image: $error");
    }
    $error = $image->Set(type=>"Grayscale");
	if($error) {
        $self->session->errorHandler->warn("Error setting grayscale: $error");
    }
    $error = $image->Border(fill=>'black', width=>1, height=>1);
	if($error) {
        $self->session->errorHandler->warn("Error setting border: $error");
    }
    $error = $image->Write($self->getPath($filename));
	if($error) {
        $self->session->errorHandler->warn("Error writing image: $error");
    }
    return ($filename, $challenge);
}

#-------------------------------------------------------------------

=head2 addFileFromFilesystem( pathToFile )

Grabs a file from the server's file system and saves it to a storage location and returns a URL compliant filename.  If there are errors encountered during the add, then it will return undef instead.

=head3 pathToFile

Provide the local path to this file.

=cut

sub addFileFromFilesystem {
    my $self = shift;
    my $pathToFile = shift;
    if (! defined $pathToFile) {
        return undef;
    }
    $pathToFile = Cwd::realpath($pathToFile); # trace any symbolic links
    if (-d $pathToFile) {
        $self->session->log->error($pathToFile." is a directory, not a file.");
        return undef;
    }
    # checks the same file
    elsif (!-f _) {
        $self->session->log->error($pathToFile." is not a regular file.");
        return undef;
    }
    my $filename = (File::Spec->splitpath( $pathToFile ))[2];
    if (isIn($self->getFileExtension($filename), qw(pl perl sh cgi php asp))) {
        $filename =~ s/\./\_/g;
        $filename .= ".txt";
    }
    $filename = $self->session->url->makeCompliant($filename);
    my $source;
    my $dest;
    unless ( open $source, '<:raw', $pathToFile ) {
        $self->_addError("Couldn't open file ".$pathToFile." for reading due to error: ".$!);
        return undef;
    }
    unless ( open $dest, '>:raw', $self->getPath($filename) ) {
        $self->_addError("Couldn't open file ".$self->getPath($filename)." for writing due to error: ".$!);
        close $source;
        return undef;
    }
    File::Copy::copy($source,$dest)
        or $self->_addError("Couldn't copy $pathToFile to ".$self->getPath($filename).": $!");
    close $dest;
    close $source;
    return $filename;
}


#-------------------------------------------------------------------

=head2 addFileFromFormPost ( formVariableName, attachmentLimit )

Grabs an attachment from a form POST and saves it to this storage location.

=head3 formVariableName

Provide the form variable name to which the file being uploaded is assigned. Note that if multiple files are uploaded with the same formVariableName then they'll all be stored in the storage location, but only the last filename will be returned. Use the getFiles() method on the storage location to get all the filenames stored.

=head3 attachmentLimit

Limit the number of files that will be uploaded.  If null, undef or 0, 99999 will be used as a default.

=cut

sub addFileFromFormPost {
	my $self = shift;
	my $formVariableName = shift;
	my $attachmentLimit = shift || 99999;
    my $session = $self->session;
    return ""
        if ($self->session->http->getStatus eq '413');
    require Apache2::Request;
    require Apache2::Upload;
    my $filename;
    my $attachmentCount = 1;
    foreach my $upload ($session->request->upload($formVariableName)) {
        $session->errorHandler->info("Trying to get " . $upload->filename);
        return $filename
            if $attachmentCount > $attachmentLimit;
        my $clientFilename = $upload->filename;
        next
            unless $clientFilename;
        next
            unless $upload->size > 0;
        next
            if ($upload->size > 1024 * $self->session->setting->get("maxAttachmentSize"));
        $clientFilename =~ s/.*[\/\\]//;
        my $type = $self->getFileExtension($clientFilename);
        if (isIn($type, qw(pl perl sh cgi php asp html htm))) { # make us safe from malicious uploads
            $clientFilename =~ s/\./\_/g;
            $clientFilename .= ".txt";
        }
        $filename = $session->url->makeCompliant($clientFilename);
        my $filePath = $self->getPath($filename);
        $attachmentCount++;
        if ($upload->link($filePath)) {
            $self->_changeOwner($filePath);
            $self->session->errorHandler->info("Got ".$upload->filename);
        }
        else {
            $self->_addError("Couldn't open file ".$self->getPath($filename)." for writing due to error: ".$!);
            return undef;
        }
    }
    return $filename;
}


#-------------------------------------------------------------------

=head2 addFileFromHashref ( filename, hashref )

Stores a hash reference as a file and returns a URL compliant filename. Retrieve the data with getFileContentsAsHashref.

=head3 filename

The name of the file to create.

=head3 hashref

A hash reference containing the data you wish to persist to the filesystem.

=cut

sub addFileFromHashref {
	my $self = shift;
	my $filename = $self->session->url->makeCompliant(shift);
	my $hashref = shift;
    Storable::nstore($hashref, $self->getPath($filename))
        or $self->_addError("Couldn't create file ".$self->getPath($filename)." because ".$!);
    $self->_changeOwner($self->getPath($filename));
	return $filename;
}

#-------------------------------------------------------------------

=head2 addFileFromScalar ( filename, content )

Adds a file to this storage location and returns a URL compliant filename.

=head3 filename

The filename to create.

=head3 content

The content to write to the file.

=cut

sub addFileFromScalar {
	my ($self, $filename, $content) = @_;
    if (isIn($self->getFileExtension($filename), qw(pl perl sh cgi php asp html htm))) { # make us safe from malicious uploads
        $filename =~ s/\./\_/g;
        $filename .= ".txt";
    }
    $filename = $self->session->url->makeCompliant($filename);
	if (open(my $FILE, ">", $self->getPath($filename))) {
		print $FILE $content;
		close($FILE);
        $self->_changeOwner($self->getPath($filename));
	}
    else {
        $self->_addError("Couldn't create file ".$self->getPath($filename)." because ".$!);
	}
	return $filename;
}

#-------------------------------------------------------------------

=head2 adjustMaxImageSize ( $file )

Adjust the size of an image according to the C<maxImageSize> setting in the Admin
Console.

=head3 $file

The name of the file to check for a maximum file size violation.

=cut 

sub adjustMaxImageSize {
    my $self = shift;
    my $file = shift;
    my $max_size = shift || $self->session->setting->get("maxImageSize");
    my ($w, $h) = $self->getSizeInPixels($file);
    if($w > $max_size || $h > $max_size) {
        if($w > $h) {
            $self->resize($file, $max_size);
        }
        else {
            $self->resize($file, 0, $max_size);
        }
        return 1;
    }
    return 0;
}

#-------------------------------------------------------------------

=head2 clear ( )

Clears a storage locations of all files except the .wgaccess file

=cut

sub clear {
	my $self = shift;
	my $filelist = $self->getFiles(1);
	foreach my $file (@{$filelist}) {
       $self->deleteFile($file);
    }
}


#-------------------------------------------------------------------

=head2 copy ( [ storage, filelist ] )

Copies a storage location and it's contents. Returns a new storage location object. Note that this does not copy privileges or other special filesystem properties.

=head3 storage

Optionally pass in a storage object to copy the data to.

=head3 filelist

Optionally pass in the list of filenames to copy from the specified storage location

=cut

sub copy {
    my $self = shift;
    my $newStorage = shift || WebGUI::Storage->create($self->session);
    my $filelist = shift || $self->getFiles(1);
    foreach my $file (@{$filelist}) {
        open my $source, '<:raw', $self->getPath($file) or next;
        open my $dest, '>:raw', $newStorage->getPath($file) or next;
        File::Copy::copy($source, $dest) or $self->_addError("Couldn't copy file ".$self->getPath($file)." to ".$newStorage->getPath($file)." because ".$!);
        close $dest;
        close $source;
        $newStorage->_changeOwner($newStorage->getPath($file));
    }
    return $newStorage;
}

#-------------------------------------------------------------------

=head2 copyFile ( filename, newFilename )

Copy a file in this storage location. C<filename> is the file to copy. 
C<newFilename> is the new file to create.

=cut

sub copyFile {
    my $self        = shift;
    my $filename    = shift;
    my $newFilename = shift;

    croak "Can't find '$filename' in storage location " . $self->getId
        unless -e $self->getPath($filename);
    croak "Second argument must be a filename"
        unless $newFilename;

    File::Copy::copy( $self->getPath($filename), $self->getPath($newFilename) )
        || croak "Couldn't copy '$filename' to '$newFilename': $!";
    $self->_changeOwner($self->getPath($filename));

    return undef;
}

#-------------------------------------------------------------------

=head2 create ( session )

Creates a new storage location on the file system.

=head3 session

A reference to the current session;

=cut

sub create {
    my $class   = shift;
    my $session = shift;
    my $id      = $session->id->generate;

    my $self = $class->get($session,$id);
    $self->_makePath;

    $session->errorHandler->info("Created storage location $id as a $class");
    return $self;
}


#-------------------------------------------------------------------

=head2 createTemp ( session )

Creates a temporary storage location on the file system.

=head3 session

A reference to the current session.

=cut

sub createTemp {
	my $class   = shift;
	my $session = shift;
	my $id      = $session->id->generate;
	my $path    = $session->id->toHex($id);

	$path =~ m/^(.{2})/;
	my $self = {_session=>$session, _id => $id, _pathParts => ['temp', $1, $path], _errors => []};
	bless $self, ref($class)||$class;
	$self->_makePath;
	return $self;
}

#-------------------------------------------------------------------

=head2 delete ( )

Deletes this storage location and its contents (if any) from the filesystem.

=cut

sub delete {
	my $self = shift;

    my $path = $self->getPath || return undef;
    File::Path::rmtree($path)
        if (-d $path);
    foreach my $subDir (join('/', @{$self->{_pathParts}}[0,1]), $self->{_pathParts}[0]) {
        my $fullPath = $self->session->config->get('uploadsPath') . '/' . $subDir;

        # can only remove empty directories, will fail silently otherwise
        rmdir $fullPath;
    }
    $self->session->errorHandler->info("Deleted storage ".$self->getId);
    return undef;
}

#-------------------------------------------------------------------

=head2 deleteFile ( filename )

Deletes a file from it's storage location.

=head3 filename

The name of the file to delete.  Returns a 1 if the file was successfully deleted, or 0 if
it doesn't.

=cut

sub deleteFile {
    my $self = shift;
    my $filename = shift;
    return undef
        if $filename =~ m{\.\./};  ##prevent deleting files outside of this object
    unlink($self->getPath('thumb-'.$filename));
    unlink($self->getPath($filename));
}


#-------------------------------------------------------------------

=head2 get ( session, id )

Returns a WebGUI::Storage object.

=head3 session

A reference to the current sesion.

=head3 id

The unique identifier for this file system storage location.

=cut

sub get {
    my $class   = shift;
    $class = ref($class) || $class;
    my $session = shift;
    my $id      = shift;
    return undef
        unless $id;
    my $self = bless {_session=>$session, _id => $id, _errors => []}, $class;

    my $uploadsRoot = $session->config->get('uploadsPath');
    my @parts = ($id =~ m/^((.{2})(.{2}).+)/)[1,2,0];
    unless (@parts) {
        $self->_addError("Illegal ID: $id");
        return $self;
    }
    if (!-e join('/', $uploadsRoot, @parts)) {
        my $hexId = $session->id->toHex($id);
        @parts = ($hexId =~ m/^((.{2})(.{2}).+)/)[1,2,0];
    }
    $self->{_pathParts} = \@parts;
    # create the folder in case it got deleted somehow
    $self->_makePath
        unless (-e $self->getPath);
    return $self;
}

#-------------------------------------------------------------------

=head2 generateThumbnail ( filename, [ thumbnailSize ] ) 

Generates a thumbnail for this image.

=head3 filename

The file to generate a thumbnail for.

=head3 thumbnailSize

The size in pixels of the thumbnail to be generated. If not specified the thumbnail size in the global settings will be used.

=cut

sub generateThumbnail {
	my $self = shift;
	my $filename = shift;
	my $thumbnailSize = shift || $self->session->setting->get("thumbnailSize") || 100;
	unless (defined $filename) {
		$self->session->errorHandler->error("Can't generate a thumbnail when you haven't specified a file.");
		return 0;
	}
	unless ($self->isImage($filename)) {
		$self->session->errorHandler->warn("Can't generate a thumbnail for something that's not an image.");
		return 0;
	}
        my $image = Image::Magick->new;
        my $error = $image->Read($self->getPath($filename));
	if ($error) {
		$self->session->errorHandler->error("Couldn't read image for thumbnail creation: ".$error);
		return 0;
	}
        my ($x, $y) = $image->Get('width','height');
        my $n = $thumbnailSize;
        if ($x > $n || $y > $n) {
                my $r = $x>$y ? $x / $n : $y / $n;
                $x /= $r;
                $y /= $r;
                if($x < 1) { $x = 1 } # Dimentions < 1 cause Scale to fail
                if($y < 1) { $y = 1 }
                $image->Scale(width=>$x,height=>$y);
		$image->Sharpen('0.0x1.0');
        }
        $error = $image->Write($self->getPath.'/'.'thumb-'.$filename);
	if ($error) {
		$self->session->errorHandler->error("Couldn't create thumbnail: ".$error);
		return 0;
	}
	return 1;
}

#-------------------------------------------------------------------

=head2 getErrorCount ( )

Returns the number of errors that have been generated on this object instance.

=cut

sub getErrorCount {
	my $self = shift;
	my $count = scalar(@{$self->{_errors}});
	return $count;
}


#-------------------------------------------------------------------

=head2 getErrors ( )

Returns an arrayref with all errors for this object

=cut

sub getErrors {
	my $self = shift;
	return $self->{_errors};
}


#-------------------------------------------------------------------

=head2 getFileContentsAsHashref ( filename )

Returns a hash reference from the file. Must be used in conjunction with a file that was saved using the addFileFromHashref method.

=head3 filename

The file to retrieve the data from.

=cut

sub getFileContentsAsHashref {
	my $self = shift;
	my $filename = shift;
    return Storable::retrieve($self->getPath($filename));
}


#-------------------------------------------------------------------

=head2 getFileContentsAsScalar ( filename )

Reads the contents of a file into a scalar variable and returns the scalar.

=head3 filename

The name of the file to read from.

=cut

sub getFileContentsAsScalar {
	my $self = shift;
	my $filename = shift;
    open my $FILE, '<', $self->getPath($filename) or return undef;
    local $/;
    my $content = <$FILE>;
    close $FILE;
	return $content;
}


#-------------------------------------------------------------------

=head2 getFileExtension ( filename )

Returns the extension or type of this file.  If there's no extension, will either return
undef or the empty string, dependent on the absence or presence of a dot.

=head3 filename

The filename of the file you wish to find out the type for.

=cut

sub getFileExtension {
	my $self = shift;
	my $filename = shift;
	$filename = lc $filename;
    my ($extension) = $filename =~ /\.([^.]*)$/;
    return $extension;
}


#-------------------------------------------------------------------

=head2 getFileIconUrl ( filename )

Returns the icon associated with this type of file.

=head3 filename

The name of the file to get the icon for.

=cut

sub getFileIconUrl {
    my $self = shift;
    my $filename = shift;
    my $extension = $self->getFileExtension($filename);
    if ($extension) {
        my $path = $self->session->config->get("extrasPath").'/fileIcons/'.$extension.".gif";
        if (-e $path) {
            return $self->session->url->extras("fileIcons/".$extension.".gif");
        }
    }
    return $self->session->url->extras("fileIcons/unknown.gif");
}


#-------------------------------------------------------------------

=head2 getFileSize ( filename )

Returns the size of this file.

=cut

sub getFileSize {
	my $self = shift;
	my $filename = shift;
    return (stat($self->getPath($filename)))[7];
}


#-------------------------------------------------------------------

=head2 getFiles ( showAll )

Returns an array reference of the files in this storage location.

=head3 showAll

Whether or not to return all files, including ones with initial periods.

=cut

sub getFiles {
    my $self = shift;
    my $showAll = shift;
    my @list;
    if ( opendir my $dir, $self->getPath ) {
        @list = readdir $dir;
        closedir $dir;
        if (!$showAll) {
            # if not showing all, filter out files beginning with a period
            @list = grep { $_ !~ /^\./ } @list;
            # filter out thumbnails
            @list = grep { $_ !~ /^thumb-/ } @list;
        }
    }
    return \@list;
}

#-------------------------------------------------------------------

=head2 getFileId ( )

Returns the file id for this storage location.

=cut

sub getFileId {
	my $self    = shift;
	return $self->getId;
}

#-------------------------------------------------------------------

=head2 getId ( )

Returns the unique identifier of this storage location.

=cut

sub getId {
	my $self = shift;
	return $self->{_id};
}

#-------------------------------------------------------------------

=head2 getLastError ( )

Returns the most recently generated error message.

=cut

sub getLastError {
	my $self = shift;
	my $count = $self->getErrorCount;
	return $self->{_errors}[$count-1];
}


#-------------------------------------------------------------------

=head2 getPath ( [ file ] )

Returns a full path to this storage location.

=head3 file

If specified, we'll return a path to the file rather than the storage location.

NOTE: Does not check if the file exists. This is a feature.

=cut

sub getPath {
	my $self = shift;
	my $file = shift;

    unless ($self->session->config->get("uploadsPath") && $self->{_pathParts} && @{ $self->{_pathParts} }) {
		$self->_addError("storage object malformed");
		return undef;
    }
    my $path = join('/', $self->session->config->get("uploadsPath"), @{ $self->{_pathParts} });
    if (defined $file) {
        return join('/', $path, $file);
    }
    return $path;
}


#-------------------------------------------------------------------

=head2 getPathFrag (  )

Returns the internal, upload dir specific part of the path.

=cut

sub getPathFrag {
    my $self = shift;
    return join '/', @{ $self->{_pathParts} };
}

#-------------------------------------------------------------------

=head2 getSizeInPixels ( filename )

Returns the width and height in pixels of the specified file.

=head3 filename

The name of the file to get the size of.

=cut

sub getSizeInPixels {
	my $self = shift;
	my $filename = shift;
	unless (defined $filename) {
		$self->session->errorHandler->error("Can't check the size when you haven't specified a file.");
		return 0;
	}
	unless ($self->isImage($filename)) {
		$self->session->errorHandler->error("Can't check the size of something that's not an image.");
		return 0;
	}
        my $image = Image::Magick->new;
        my $error = $image->Read($self->getPath($filename));
	if ($error) {
		$self->session->errorHandler->error("Couldn't read image to check the size of it: ".$error);
		return 0;
	}
        return $image->Get('width','height');
}


#-------------------------------------------------------------------

=head2 getThumbnailUrl ( filename ) 

Returns the URL to a thumbnail for a given image.

=head3 filename

The file to retrieve the thumbnail for.

=cut

sub getThumbnailUrl {
	my $self = shift;
	my $filename = shift;
	if (! defined $filename) {
		$self->session->errorHandler->error("Can't make a thumbnail url without a filename.");
		return '';
	}
    if (! isIn($filename, @{ $self->getFiles() })) {
        $self->session->errorHandler->error("Can't make a thumbnail for a file named '$filename' that is not in my storage location.");
        return '';
    }
	return $self->getUrl("thumb-".$filename);
}

#-------------------------------------------------------------------

=head2 getUrl ( [ file ] )

Returns a URL to this storage location.

=head3 file

If specified, we'll return a URL to the file rather than the storage location.

=cut

sub getUrl {
	my $self = shift;
	my $file = shift;
	my $url = $self->session->config->get("uploadsURL")
            . '/'
            . $self->getPathFrag;
	if (defined $file) {
		$url .= '/'.$file;
	}
	return $url;
}



#-------------------------------------------------------------------

=head2 isImage ( filename ) 

Checks to see that the file specified is an image. Returns a 1 or 0 depending upon the result.

=head3 filename

The file to check.

=cut

sub isImage {
	my $self = shift;
	my $filename = shift;
	return isIn($self->getFileExtension($filename), qw(jpeg jpg gif png))
}



#-------------------------------------------------------------------

=head2 renameFile ( filename, newFilename )

Renames a file's filename.  Returns true if the rename succeeded and false
if it didn't.

=head3 filename

The name of the file you wish to rename.

=head3 newFilename

Define the new filename a specified file.

=cut

sub renameFile {
	my $self = shift;
	my $filename = shift;
	my $newFilename = shift;
    rename $self->getPath($filename), $self->getPath($newFilename);
}

#-------------------------------------------------------------------

=head2 resize ( filename [, width, height ] )

Resizes the specified image by the specified height and width. If either is omitted the iamge will be scaleed proportionately to the non-omitted one.

=head3 filename

The name of the file to resize.

=head3 width

The new width of the image in pixels.

=head3 height

The new height of the image in pixels.

=head3 density

The new image density in pixels per inch. 

=cut

# TODO: Make this take a hash reference with width, height, and density keys.

sub resize { 
    my $self        = shift;
    my $filename    = shift;
    my $width       = shift;
    my $height      = shift;
    my $density     = shift;
    unless (defined $filename) {
        $self->session->errorHandler->error("Can't resize when you haven't specified a file.");
        return 0;
    }
    unless ($self->isImage($filename)) {
        $self->session->errorHandler->error("Can't resize something that's not an image.");
        return 0;
    }
    unless ($width || $height || $density) {
        $self->session->errorHandler->error("Can't resize with no resizing parameters.");
        return 0;
    }
    my $image = Image::Magick->new;
    my $error = $image->Read($self->getPath($filename));
    if ($error) {
        $self->session->errorHandler->error("Couldn't read image for resizing: ".$error);
        return 0;
    }

    # First, change image density
    if ( $density ) {
        $self->session->errorHandler->info( "Setting $filename to $density" );
        $image->Set( density => "${density}x${density}" );
    }

    # Next, resize dimensions
    if ( $width || $height ) {
        if (!$height && $width =~ /^(\d+)x(\d+)$/) {
            $width = $1;
            $height = $2;
        }
        my ($x, $y) = $image->Get('width','height');
        if (!$height) { # proportional scale by width
            $height = $width / $x * $y;
        }
        elsif (!$width) { # proportional scale by height
            $width = $height * $x / $y;
        }
        $self->session->errorHandler->info( "Resizing $filename to w:$width h:$height" );
        $image->Resize( height => $height, width => $width );
    }

    # Write our changes to disk
    $error = $image->Write($self->getPath($filename));
    if ($error) {
        $self->session->errorHandler->error("Couldn't resize image: ".$error);
        return 0;
    }

    return 1;
}

#-------------------------------------------------------------------

=head2 session ( )

Returns a reference to the current session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}


#-------------------------------------------------------------------

=head2 setPrivileges ( ownerUserId, groupIdView, groupIdEdit )

Set filesystem level privileges for this file. Used with the uploads access handler.

=head3 ownerUserId

The userId of the owner of this storage location.

=head3 groupIdView

The groupId that is allowed to view the files in this storage location.

=head3 groupIdEdit

The groupId that is allowed to edit the files in this storage location.

=cut

sub setPrivileges {
	my $self = shift;
	my $owner = shift;
	my $viewGroup = shift;
	my $editGroup = shift;
	
    if ($owner eq '1' || $viewGroup eq '1' || $viewGroup eq '7' || $editGroup eq '1' || $editGroup eq '7') {
        $self->deleteFile('.wgaccess');
    }
    else {
        $self->addFileFromScalar(".wgaccess",$owner."\n".$viewGroup."\n".$editGroup);
    }
}



#-------------------------------------------------------------------

=head2 tar ( filename [, storage ] )

Archives this storage location into a tar file and then compresses it with a zlib algorithm. It then returns a new WebGUI::Storage object for the archive.

=head3 filename

The name of the tar file to be created. Should ideally end with ".tar.gz".

=head3 storage

Pass in a storage location object to create the tar file in, instead of having a temporary one be created. Note that it cannot be the same location that's being tarred.

=cut

sub tar {
    my $self = shift;
    my $filename = shift;
    my $temp = shift || WebGUI::Storage->createTemp($self->session);
    my $originalDir = Cwd::cwd();
    chdir $self->getPath
        or croak 'Unable to chdir to ' . $self->getPath . ": $!";
    my @files;
    File::Find::find(sub { push(@files, $File::Find::name)}, ".");
    Archive::Tar->create_archive($temp->getPath($filename),1,@files);
    chdir $originalDir;
    return $temp;
}

#-------------------------------------------------------------------

=head2 untar ( filename [, storage ] )

Unarchives a file into a new storage location. Returns the new WebGUI::Storage object.

=head3 filename

The name of the tar file to be untarred.

=head3 storage

Pass in a storage location object to extract the contents to, instead of having a temporary one be created.

=cut

sub untar {
    my $self        = shift;
    my $filename    = shift;
    my $temp        = shift || WebGUI::Storage->createTemp($self->session);

    my $originalDir = Cwd::cwd();
    chdir $temp->getPath;
    local $Archive::Tar::CHOWN = 0;
    local $Archive::Tar::CHMOD = 0;
    Archive::Tar->extract_archive($self->getPath($filename),1);
    $self->_addError(Archive::Tar->error)
        if (Archive::Tar->error);
    my @files;
    File::Find::find(sub {
        push(@files, $File::Find::name);
    }, ".");
    $self->_changeOwner(@files);

    chdir $originalDir;
    return $temp;
}

1;

