package WebGUI::FilePump::Bundle;

use base qw/WebGUI::Crud/;
use strict;
use WebGUI::International;
use WebGUI::Utility;
use URI;
use Path::Class;
use File::Basename;
use CSS::Minifier::XS;
use JavaScript::Minifier::XS;
use LWP;
use Data::Dumper;

#-------------------------------------------------------------------

=head2 addFile ( $type, $uri )

Adds a file of the requested type to the bundle.  Returns 1 if the add was successful.
Otherwise, returns 0 and an error message as to why it was not successful.

=head3 $type

If $type is JS, it adds it to the javascript part of the bundle.  If it is
CSS, it adds it to the CSS part of the bundle.  OTHER is used for all other
types of files.

=head3 $uri

A URI to the new file to add.  If the URI already exists in that part of the bundle,
it will return 0 and an error message.

=cut

sub addFile {
    my ($self, $type, $uri) = @_;
    return 0, 'Illegal type' unless WebGUI::Utility::isIn($type, 'JS', 'CSS', 'OTHER');
    return 0, 'No URI' unless $uri;
    my $collateralType = $type eq 'JS'  ? 'jsFiles'
                       : $type eq 'CSS' ? 'cssFiles'
                       : 'otherFiles';
    my $files     = $self->get($collateralType);
    my $uriExists = $self->getCollateralDataIndex($files, 'uri', $uri) != -1 ? 1 : 0;
    return 0, 'Duplicate URI' if $uriExists;
    
    if (my $msg = $self->validate($uri)) {
        return 0, $msg;
    }
    
    $self->setCollateral(
        $collateralType,
        'fileId',
        'new',
        {
            uri          =>  $uri,
            lastModified => 0,
        },
    );
    $self->update({lastModified => time()});
    return 1;
}
    

#-------------------------------------------------------------------

=head2 build ( )

build goes through and fetches all files referenced in all URIs stored for
this bundle.  It downloads them, stores their modification time for future
checks, and then does special processing, depending on the type of file.

Javascript files are concatenated together in order, and minimized.  The
resulting data is stored in the filepump area under the uploads directory
with the name bundleName.timestamp/bundleName.js

CSS files are handled likewise, except that the name is bundleName.timestamp/bundleName.css.

Other files are copied from their current location into the timestamped bundle directory.

Older timestamped build directories are removed.

If the build is successful, it will return 1.  Otherwise, if problems
occur during the build, then the old build directory is not affected and
the method returns 0, along with an error message.

=cut

sub build {
    my ($self) = @_;
    my $newBuild = time();
    my $originalBuild = $self->get('lastBuild');

    ##Whole lot of building
    my $error = undef;

    ##JavaScript first
    my $jsFiles    = $self->get('jsFiles');
    my $concatenatedJS = '';
    JSFILE: foreach my $jsFile (@{ $jsFiles }) {
        my $uri     = $jsFile->{uri};
        my $results = $self->fetch($uri);
        if (! $results->{content}) {
            $error = $uri;
            last JSFILE;
        }
        $concatenatedJS .= $results->{content};
        $jsFile->{lastModified} = $results->{lastModified};
    }
    return (0, $error) if ($error);

    ##CSS next
    my $cssFiles    = $self->get('cssFiles');
    my $concatenatedCSS = '';
    CSSFILE: foreach my $cssFile (@{ $cssFiles }) {
        my $uri     = $cssFile->{uri};
        my $results = $self->fetch($uri);
        if (! $results->{content}) {
            $error = $uri;
            last CSSFILE;
        }
        $concatenatedCSS .= $results->{content};
        $cssFile->{lastModified} = $results->{lastModified};
    }

    return (0, $error) if ($error);

    ##Create the new build directory
    my $newDir = $self->getPathClassDir($newBuild);
    my $mkpathErrors;
    my $dirsCreated = $newDir->mkpath({ errors => \$mkpathErrors });
    if (! $dirsCreated) {
        $newDir->rmtree;
        my $errorMessages = join "\n", @{ $mkpathErrors };
        return (0, $errorMessages);
    }

    ##Copy files over
    my $otherFiles = $self->get('otherFiles');
    OTHERFILE: foreach my $file (@{ $otherFiles }) {
        my $uri     = $file->{uri};
        my $results = $self->fetch($uri);
        if (! $results->{content}) {
            $error = $uri;
            last OTHERFILE;
        }
        $file->{lastModified} = $results->{lastModified};
        if ($results->{type} eq 'file') {
            $error = $self->_buildFile($newDir, $uri, $results);
        }
        elsif ($results->{type} eq 'directory') {
            $error = $self->_buildDir($newDir, $uri, $results);
        }
        last OTHERFILE if ($error);

    }

    if ($error) {
        $newDir->rmtree;
        return (0, $error);
    }

    ##Minimize files, and write them out.

    my $minimizedJS  =  JavaScript::Minifier::XS::minify($concatenatedJS);
    undef $concatenatedJS;

    my $minimizedCSS = CSS::Minifier::XS::minify($concatenatedCSS);
    undef $concatenatedCSS;

    my $flatJsFile = $newDir->file($self->bundleUrl . '.js');
    my $jsFH = $flatJsFile->open('>');
    print $jsFH $minimizedJS;
    close $jsFH;

    my $flatCssFile = $newDir->file($self->bundleUrl . '.css');
    my $cssFH = $flatCssFile->open('>');
    print $cssFH $minimizedCSS;
    close $cssFH;

    ##Delete the old build directory and update myself with the new data.
    $self->deleteBuild();
    $self->update({
        jsFiles     => $jsFiles,
        cssFiles    => $cssFiles,
        otherFiles  => $otherFiles,
        lastBuild   => $newBuild,
    });
    return 1;
}

#-------------------------------------------------------------------

=head2 _buildDir ( $newDir, $uri, $results )

Copy over a directory and all its files from the filesystem into the build directory.  It does
not copy deeply.

=head3 $newDir

A Path::Class::Dir object pointing to the new build directory.

=head3 $uri

A URI to the original directory.

=head3 $results

The returned results from fetchDir, with the file contents to
install into the build directory.

=cut

sub _buildDir {
    my ($self, $newDir, $uri, $results) = @_;
    my $uriPath   =  URI->new($uri)->opaque;
    $uriPath      =~ tr{/}{/}s;
    my $uriDir    =  Path::Class::Dir->new($uriPath);
    my $dirname   =  $uriDir->dir_list(-1, 1);
    my $newSubDir =  $newDir->subdir($dirname);
    if (-e $newSubDir->stringify) {
        my $i18n = WebGUI::International->new($self->session, 'FilePump');
        return join ' ', $uri, $i18n->get('duplicate directory');
    }
    my $mkpathErrors;
    my $dirsCreated = $newSubDir->mkpath({ errors => \$mkpathErrors });
    if (! $dirsCreated) {
        $newSubDir->rmtree;
        my $errorMessages = join "\n", @{ $mkpathErrors };
        return $errorMessages;
    }
    ##Note, we built the directory, so there should be no problems with
    ##file permissions.  Likewise, since you can't have files with the same
    ##name in the source directory, there's no need to check for filename collisions.
    foreach my $subFile (@{ $results->{content} }) {
        my $inFH    = $subFile->open('<');
        my $newFile = $newSubDir->file($subFile->basename);
        my $outFH   = $newFile->open('>');
        $inFH->binmode;
        $outFH->binmode;
        local $/;
        my $inFile = <$inFH>;
        print $outFH $inFile;
        $inFH->close;
        $outFH->close;
    }
    return 0;
}

#-------------------------------------------------------------------

=head2 _buildFile ( $newDir, $uri, $results )

Copy over a file from the filesystem into the build directory.

=head3 $newDir

A Path::Class::Dir object pointing to the new build directory.

=head3 $uri

A URI to the original file.

=head3 $results

The returned results from fetchFile, with the file contents to
install into the build directory.

=cut

sub _buildFile {
    my ($self, $newDir, $uri, $results) = @_;
    my $uriPath  =  URI->new($uri)->opaque;
    $uriPath     =~ tr{/}{/}s;
    my $filename =  basename($uriPath);
    my $newFile  =  $newDir->file($filename);
    if (-e $newFile->stringify) {
        my $i18n = WebGUI::International->new($self->session, 'FilePump');
        return join ' ', $uri, $i18n->get('duplicate file');
    }
    my $fh = $newFile->open('>');
    $fh->binmode;
    print $fh $results->{content};
    close $fh;
    return 0;
}

#-------------------------------------------------------------------

=head2 crud_definition

WebGUI::Crud definition for this class.

=head3 tableName

filePumpBundle

=head3 tableKey

bundleId

=head3 sequenceKey

None.  Bundles have no sequence amongst themselves.

=head3 properties

=head4 bundleName

The name of a bundle

=head4 lastBuild

The date the bundle was last built.  This is used to generate the name of the bundled files
for this bundle.

=head4 lastModified

The date the bundle was last modified.  With this, and the lastBuild date, you can determine
which bundles need to be rebuilt.

=head4 jsFiles, cssFiles, otherFiles

JSON blobs with files attached to the bundle. js = javascript, css = Cascading Style Sheets, other
means anything else.

=cut

sub crud_definition {
    my ($class, $session) = @_;
    my $definition = $class->SUPER::crud_definition($session);
    my $i18n = WebGUI::International->new($session, 'FilePump');
    $definition->{tableName}   = 'filePumpBundle';
    $definition->{tableKey}    = 'bundleId';
    $definition->{sequenceKey} = '';
    my $properties = $definition->{properties};
    $properties->{bundleName} = {
        fieldType    => 'text',
        defaultValue => $i18n->get('new bundle'),
    };
    $properties->{lastModified} = {
        fieldType    => 'integer',
        defaultValue => 0,
    };
    $properties->{lastBuild} = {
        fieldType    => 'integer',
        defaultValue => 0,
    };
    $properties->{jsFiles} = {
        fieldType    => 'textarea',
        defaultValue => [],
        serialize    => 1,
    };
    $properties->{cssFiles} = {
        fieldType    => 'textarea',
        defaultValue => [],
        serialize    => 1,
    };
    $properties->{otherFiles} = {
        fieldType    => 'textarea',
        defaultValue => [],
        serialize    => 1,
    };
    return $definition;
}

#-------------------------------------------------------------------

=head2 delete ( )

Extend the method from WebGUI::Crud to handle deleting the locally stored
files.

=cut

sub delete {
    my ($self) = @_;
    $self->deleteBuild;
    return $self->SUPER::delete;
}

#-------------------------------------------------------------------

=head2 deleteBuild ( )

Delete the build as specified by the Bundle's current lastBuild timestamp;

=cut

sub deleteBuild {
    my ($self) = @_;
    my $bundleDir = $self->getPathClassDir();
    $bundleDir->rmtree();
}

#-------------------------------------------------------------------

=head2 deleteCollateral ( tableName, keyName, keyValue )

Deletes a row of collateral data.

=head3 tableName

The name of the table you wish to delete the data from.

=head3 keyName

The name of a key in the collateral hash.  Typically a unique identifier for a given
"row" of collateral data.

=head3 keyValue

Along with keyName, determines which "row" of collateral data to delete.

=cut

sub deleteCollateral {
    my $self      = shift;
    my $tableName = shift;
    my $keyName   = shift;
    my $keyValue  = shift;
    my $table = $self->get($tableName);
    my $index = $self->getCollateralDataIndex($table, $keyName, $keyValue);
    return if $index == -1;
    splice @{ $table }, $index, 1;
    $self->update({ $tableName => $table });
}

#-------------------------------------------------------------------

=head2 deleteFiles ( $type )

Deletes all files of the requested type.

=head3 $type

If $type is JS, it deletes it from the javascript part of the bundle.  If it is
CSS, it deletes it from the CSS part of the bundle.  OTHER is used for all other
types of files.

=cut

sub deleteFiles {
    my ($self, $type) = @_;
    return 0, 'Illegal type' unless WebGUI::Utility::isIn($type, 'JS', 'CSS', 'OTHER');
    my $collateralType = $type eq 'JS'  ? 'jsFiles'
                       : $type eq 'CSS' ? 'cssFiles'
                       : 'otherFiles';
    $self->update({$collateralType => []});
    return 1;
}

#-------------------------------------------------------------------

=head2 deleteFile ( $type, $fileId )

Deletes a file of the requested type from the bundle.

=head3 $type

If $type is JS, it deletes it from the javascript part of the bundle.  If it is
CSS, it deletes it from the CSS part of the bundle.  OTHER is used for all other
types of files.

=head3 $fileId

The unique collateral GUID to delete from the bundle.

=cut

sub deleteFile {
    my ($self, $type, $fileId) = @_;
    return 0, 'Illegal type' unless WebGUI::Utility::isIn($type, 'JS', 'CSS', 'OTHER');
    return 0, 'No fileId' unless $fileId;
    my $collateralType = $type eq 'JS'  ? 'jsFiles'
                       : $type eq 'CSS' ? 'cssFiles'
                       : 'otherFiles';
    $self->deleteCollateral(
        $collateralType,
        'fileId',
        $fileId,
    );
    $self->update({lastModified => time()});
    return 1;
}

#-------------------------------------------------------------------

=head2 fetch ( $uri )

Based on the scheme of the URI, dispatch the URI to the correct method
to handle it.  Returns the results of the method.

=head3 $uri

A uri, of the form accepted by URI.

=cut

sub fetch {
    my ($self, $uri ) = @_;
    my $guts   = {};
    my $urio   = URI->new($uri);
    my $scheme = $urio->scheme;
    if ($scheme eq 'http' or $scheme eq 'https') {
        $guts = $self->fetchHttp($urio);
    }
    elsif ($scheme eq 'asset') {
        $guts = $self->fetchAsset($urio);
    }
    elsif ($scheme eq 'file') {
        $guts = $self->fetchFile($urio);
    }
    return $guts;
}

#-------------------------------------------------------------------

=head2 fetchAsset ( $uri )

Fetches a bundle file from a WebGUI Asset (probably a snippet) in this site.
If the Asset cannot be found with that URL, it returns an empty hashref.
Depending on the type of Asset fetched, there will be different fields.  Every
kind of asset will have the lastModified field.

Snippet assets will have a content field with the contents of the Snippet inside
of it.

File assets will have a content field with the contents of the file.

Any other kind of asset will return an empty content field.

=head3 $uri

A URI object.

=cut

sub fetchAsset {
    my ($self, $uri ) = @_;

    my $url = $uri->opaque;
    $url =~ s{^/+}{};
    my $asset = WebGUI::Asset->newByUrl($self->session, $url);
    return {} unless $asset;
    ##Check for a snippet, or snippet subclass?
    my $guts = {
        lastModified => $asset->get('lastModified'),
        content      => '',
    };
    if ($asset->isa('WebGUI::Asset::Snippet')) {
        $guts->{content} = $asset->view(1);
    }
    elsif ($asset->isa('WebGUI::Asset::File')) {
        $guts->{content} = $asset->getStorageLocation->getFileContentsAsScalar($asset->get('filename'));
    }
    return $guts;
}

#-------------------------------------------------------------------

=head2 fetchDir ( $uri )

Fetches all files from a filesystem directory.  Returns a hashref
with the date that the directory was last updated, a contents entry
which is an arrayref of Path::Class objects from the directory. '.', and '../'
are always ommitted, and a type entry which is the string 'directory'.

If there is any problem with getting files, it returns an empty hashref.

=head3 $uri

A URI object.

=cut

sub fetchDir {
    my ($self, $uri ) = @_;
    my $filepath = $self->resolveFilePath($uri->path);
    return {} unless (-e $filepath && -r _ && -d _);
    my @stats = stat(_);
    my $dir   = Path::Class::Dir->new($filepath);
    my $guts  = {
        lastModified => $stats[9],
        content      => [ $dir->children ],
        type         => 'directory',
    };
    return $guts;
}

#-------------------------------------------------------------------

=head2 fetchFile ( $uri )

Fetches a bundle file from the local filesystem.  Returns a hashref with the
content, date that it was last updated, and a type entry which is the string
'file'.  If there is any problem with getting the file, it returns an
empty hashref.

If fetchFile is passed a URI which is a directory, it will call fetchDir on
that URI and return the results.

=head3 $uri

A URI object.

=cut

sub fetchFile {
    my ($self, $uri ) = @_;
    my $filepath = $self->resolveFilePath($uri->path);
    return {} unless (-e $filepath && -r _);
    return $self->fetchDir($uri) if -d _;
    my @stats = stat(_); # recycle stat data from file tests.
    open my $file, '<', $filepath or return {};
    local $/;
    my $guts = {
        lastModified => $stats[9],
        content      => <$file>,
        type         => 'file',
    };
    close $file;
    return $guts;
}

#-------------------------------------------------------------------

=head2 fetchHttp ( $uri )

Fetches a bundle file from the web.  Returns a hashref with the content
and date that it was last updated.  If there is any problem with making
the request, it returns an empty hashref.

=head3 $uri

A URI object.

=cut

sub fetchHttp {
    my ($self, $uri ) = @_;

    # Set up LWP
    my $userAgent = LWP::UserAgent->new;
    $userAgent->env_proxy;
    $userAgent->agent("WebGUI");
    
    # Create a request and stuff the uri in it
    my $request  = HTTP::Request->new( GET => $uri );
    my $response = $userAgent->request($request);

    if (! $response->is_success) {
        return {};
    }
    my $guts = {
        content      => $response->content,
        lastModified => $response->header('last-modified'),
    };
    return $guts;
}

#-------------------------------------------------------------------

=head2 bundleUrl ( )

Returns a urlized version of the bundle name, safe for URLs and filenames.

=cut

sub bundleUrl {
    my ($self) = @_;
    return $self->session->url->urlize($self->get('bundleName'));
}

#-------------------------------------------------------------------

=head2 getCollateral ( tableName, keyName, keyValue )

Returns a hash reference containing one row of collateral data from a particular
table.

=head3 tableName

The name of the table you wish to retrieve the data from.

=head3 keyName

The name of a key in the collateral hash.  Typically a unique identifier for a given
"row" of collateral data.

=head3 keyValue

Along with keyName, determines which "row" of collateral data to get.
If this is equal to "new", then an empty hashRef will be returned to avoid
strict errors in the caller.  If the requested data does not exist in the
collateral array, it also returns an empty hashRef.

=cut

sub getCollateral {
    my $self      = shift;
    my $tableName = shift;
    my $keyName   = shift;
    my $keyValue  = shift;
    if ($keyValue eq "new" || $keyValue eq "") {
        return {};
    }
    my $table = $self->get($tableName);
    my $index = $self->getCollateralDataIndex($table, $keyName, $keyValue);
    return {} if $index == -1;
    my %copy = %{ $table->[$index] };
    return \%copy;
}


#-------------------------------------------------------------------

=head2 getCollateralDataIndex ( table, keyName, keyValue )

Returns the index in a set of collateral where an element of the
data (keyName) has a certain value (keyValue).  If the criteria
are not found, returns -1.

=head3 table

The collateral data to search

=head3 keyName

The name of a key in the collateral hash.

=head3 keyValue

The value that keyName should have to meet the criteria.

=cut

sub getCollateralDataIndex {
    my $self     = shift;
    my $table    = shift;
    my $keyName  = shift;
    my $keyValue = shift;
    for (my $index=0; $index <= $#{ $table }; $index++) {
        return $index
            if (exists($table->[$index]->{$keyName}) && ($table->[$index]->{$keyName} eq $keyValue ));
    }
    return -1;
}

#-------------------------------------------------------------------

=head2 getPathClassDir ( $otherBuild )

Returns a Path::Class::Dir object to the last build directory
for this bundle.

=head3 $otherBuild

Another time stamp to use instead of the lastModified timestamp.

=cut

sub getPathClassDir {
    my ($self, $lastBuild) = @_;
    $lastBuild ||= $self->get('lastBuild');
    return Path::Class::Dir->new(
        $self->session->config->get('uploadsPath'),
        'filepump',
        $self->bundleUrl . '.' . $lastBuild
    );
}

#-------------------------------------------------------------------

=head2 getOutOfDateBundles ( $session )

This is a class method.  It returns an array reference of WebGUI::FilePump::Bundle
objects that need to be rebuilt.

=head3 $session

A WebGUI::Session object.

=cut

sub getOutOfDateBundles {
    my ($class, $session) = @_;
    my $oldBundles = [];
    my $oldBundleIterator = $class->getAllIterator({
        constraints => [
            'lastBuild < lastModified' => [],
        ],
    });
    while (my $bundle = $oldBundleIterator->()) {
        push @{ $oldBundles }, $bundle;
    }
    return $oldBundles;
}

#-------------------------------------------------------------------

=head2 moveCollateralDown ( tableName, keyName, keyValue )

Moves a collateral data item down one position.  If called on the last element of the
collateral array then it does nothing.  Returns 1 if the move is successful.  Returns
undef or the empty array otherwise.

=head3 tableName

A string indicating the table that contains the collateral data.

=head3 keyName

The name of a key in the collateral hash.  Typically a unique identifier for a given
"row" of collateral data.

=head3 keyValue

Along with keyName, determines which "row" of collateral data to move.

=cut

sub moveCollateralDown {
    my $self      = shift;
    my $tableName = shift;
    my $keyName   = shift;
    my $keyValue  = shift;

    my $table = $self->get($tableName);
    my $index = $self->getCollateralDataIndex($table, $keyName, $keyValue);
    return if $index == -1;
    return unless (abs($index) < $#{$table});
    @{ $table }[$index,$index+1] = @{ $table }[$index+1,$index];
    $self->update({ $tableName => $table });
    return 1;
}


#-------------------------------------------------------------------

=head2 moveCollateralUp ( tableName, keyName, keyValue )

Moves a collateral data item up one position.  If called on the first element of the
collateral array then it does nothing.  Returns 1 if the move is successful.  Returns
undef or the empty array otherwise.


=head3 tableName

A string indicating the table that contains the collateral data.

=head3 keyName

The name of a key in the collateral hash.  Typically a unique identifier for a given
"row" of collateral data.

=head3 keyValue

Along with keyName, determines which "row" of collateral data to move.

=cut

sub moveCollateralUp {
    my $self      = shift;
    my $tableName = shift;
    my $keyName   = shift;
    my $keyValue  = shift;

    my $table = $self->get($tableName);
    my $index = $self->getCollateralDataIndex($table, $keyName, $keyValue);
    return if $index == -1;
    return unless $index && (abs($index) <= $#{$table});
    @{ $table }[$index-1,$index] = @{ $table }[$index,$index-1];
    $self->update({ $tableName => $table });
    return 1;
}

#-------------------------------------------------------------------

=head2 moveFileDown ( $type, $fileId )

Moves the requested file down in the ordered collateral.

=head3 $type

If $type is JS, it moves a file in the javascript part of the bundle.  If it is
CSS, it moves a file in the CSS part of the bundle.  OTHER is used for all other
types of files.

=head3 $fileId

The unique collateral GUID to move in the bundle.

=cut

sub moveFileDown {
    my ($self, $type, $fileId) = @_;
    return 0, 'Illegal type' unless WebGUI::Utility::isIn($type, 'JS', 'CSS', 'OTHER');
    return 0, 'No fileId' unless $fileId;
    my $collateralType = $type eq 'JS'  ? 'jsFiles'
                       : $type eq 'CSS' ? 'cssFiles'
                       : 'otherFiles';
    $self->moveCollateralDown(
        $collateralType,
        'fileId',
        $fileId,
    );
    $self->update({lastModified => time()});
    return 1;
}

#-------------------------------------------------------------------

=head2 moveFileUp ( $type, $fileId )

Moves the requested file up in the ordered collateral.

=head3 $type

If $type is JS, it moves a file in the javascript part of the bundle.  If it is
CSS, it moves a file in the CSS part of the bundle.  OTHER is used for all other
types of files.

=head3 $fileId

The unique collateral GUID to move in the bundle.

=cut

sub moveFileUp {
    my ($self, $type, $fileId) = @_;
    return 0, 'Illegal type' unless WebGUI::Utility::isIn($type, 'JS', 'CSS', 'OTHER');
    return 0, 'No fileId' unless $fileId;
    my $collateralType = $type eq 'JS'  ? 'jsFiles'
                       : $type eq 'CSS' ? 'cssFiles'
                       : 'otherFiles';
    $self->moveCollateralUp(
        $collateralType,
        'fileId',
        $fileId,
    );
    $self->update({lastModified => time()});
    return 1;
}


#-----------------------------------------------------------------

=head2 setCollateral ( tableName, keyName, keyValue, properties )

Performs and insert/update of collateral data for any wobject's collateral data.
Returns the id of the data that was set, even if a new row was added to the
data.

=head3 tableName

The name of the table to insert the data.

=head3 keyName

The name of a key in the collateral hash.  Typically a unique identifier for a given
"row" of collateral data.

=head3 keyValue

Along with keyName, determines which "row" of collateral data to set.
The index of the collateral data to set.  If the keyValue = "new", then a
new entry will be appended to the end of the collateral array.  Otherwise,
the appropriate entry will be overwritten with the new data.

=head3 properties

A hash reference containing the name/value pairs to be inserted into the collateral, using
the criteria mentioned above.

=cut

sub setCollateral {
    my $self       = shift;
    my $tableName  = shift;
    my $keyName    = shift;
    my $keyValue   = shift;
    my $properties = shift;
    ##Note, since this returns a reference, it is actually updating
    ##the object cache directly.
    my $table = $self->get($tableName);
    if ($keyValue eq 'new' || $keyValue eq '') {
        if (! exists $properties->{$keyName}
           or $properties->{$keyName} eq 'new'
           or $properties->{$keyName} eq '') {
            $properties->{$keyName} = $self->session->id->generate;
        }
        push @{ $table }, $properties;
        $self->update({$tableName => $table});
        return $properties->{$keyName};
    }
    my $index = $self->getCollateralDataIndex($table, $keyName, $keyValue);
    return if $index == -1;
    $table->[$index] = $properties;
    $self->update({ $tableName => $table });
    return $keyValue;
}

#-------------------------------------------------------------------

=head2 validate ( $uri )

Check a uri for validation errors. Returns a validation error message (if problems found).

=head3 $uri

The URI to validate

=cut

sub validate {
    my $self = shift;
    my $uri = shift;
    
    my $urio   = URI->new($uri) or return "Invalid URI: $uri";
    my $scheme = $urio->scheme;
    my $path = $urio->path;
    
    # File validation
    if ($scheme eq 'file') {
        if ($path !~ m{^uploads/|^extras/}) {
            return q{File uri must begin with file:uploads/.. or file:extras/..};
        }
        
        # N.B. Once we have Path::Class >= 0.17 we can use resolve() for a better solution to this canonicalisation problem
        if ($path =~ m{\.\./}) {
            return q{Directory traversal not permitted};
        }
        
        my $uploadsDir = Path::Class::Dir->new($self->session->config->get('uploadsPath'));
        my $extrasDir  = Path::Class::Dir->new($self->session->config->get('extrasPath'));
        
        my $file = $self->resolveFilePath($path);
        
        return q{File not found} unless -e $file;
        
        if (!$uploadsDir->contains($file) && !$extrasDir->contains($file)) {
            return q{File uri must correspond to files inside your uploads dir or your extras dir};
        }
    }
    
    return;
}

#-------------------------------------------------------------------

=head2 resolveFilePath ( $path )

Resolves a relative path into a L<Path::Class::File> object. The path,
which must being with either C<uploads> or C<extras>, is resolved into
an absolute path with C<uploads> or C<extras> replaced with the value
of C<uploadsPath> or c<extrasPath> from the site config file.

For example, the following path

 file:extras/path/to/my/file

Resolves to something like:

 /data/WebGUI/www/extras/path/to/my/file

=head3 $path

A relative file path that must begine with either C<uploads> or C<extras>.

=cut

sub resolveFilePath {
    my $self = shift;
    my $path = shift;
    
    if ($path =~ s{^uploads/}{}) {
        my $uploadsDir = Path::Class::Dir->new($self->session->config->get('uploadsPath'));
        return Path::Class::File->new($uploadsDir, $path);
    } elsif ($path =~ s{^extras/}{}) {
        my $extrasDir  = Path::Class::Dir->new($self->session->config->get('extrasPath'));
        return Path::Class::File->new($extrasDir, $path);
    }
}

1;
