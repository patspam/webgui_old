package WebGUI::Shop::Products;

use strict;

use Class::InsideOut qw{ :std };

use WebGUI::Text;
use WebGUI::Storage;
use WebGUI::Exception::Shop;
use WebGUI::Shop::Admin;
use WebGUI::Asset::Sku::Product;

=head1 NAME

Package WebGUI::Shop::Products

=head1 DESCRIPTION

This package handles importing and exporting products into the Shop system, mainly
to be compatible with third-party systems, such as inventory control.  If you want to
export your Products into another WebGUI site, please use the Asset Export system
instead.

=head1 METHODS

These subroutines are available from this package:

=cut

readonly session => my %session;

#-------------------------------------------------------------------

=head2 exportProducts ( )

Export all products from the WebGUI system in a CSV file.  For details
about the file format, see importProducts.

Returns a temporary WebGUI::Storage object containing the file.  The
file will be named siteProductData.csv.

=cut

sub exportProducts {
    my $self    = shift;
    my $session = $self->session;
    my @columns = qw{sku shortdescription price weight quantity};
    my $productData = WebGUI::Text::joinCSV(qw{mastersku title}, @columns) . "\n";
    @columns = map { $_ eq 'shortdescription' ? 'shortdesc' : $_ } @columns;
    my $getAProduct = WebGUI::Asset::Sku::Product->getIsa($session);
    while (my $product = $getAProduct->()) {
        my $mastersku = $product->get('sku');
        my $title     = $product->getTitle;
        my $collateri = $product->getAllCollateral('variantsJSON');
        foreach my $collateral (@{ $collateri }) {
            my @productFields = @{ $collateral }{ @columns };
            $productData .= WebGUI::Text::joinCSV($mastersku, $title, @productFields);
            $productData .= "\n";
        }
    }
    my $storage = WebGUI::Storage->createTemp($session);
    $storage->addFileFromScalar('siteProductData.csv', $productData);
    return $storage;
}

#-------------------------------------------------------------------

=head2 importProducts ( $filePath )

Import products into the WebGUI system.  If the master sku of a product
exists in the system, it will be updated.  If master skus do not exist,
they will be added.

The first line of the file should contain only the name of the columns,
in any order.  It may not contain comments.

These are the column names, each is required:

=over 4

=item *

mastersku

=item *

sku

=item *

title

=item *

shortdescription

=item *

price

=item *

weight

=item *

quantity

=back

The following lines will contain product information.  Blank
lines and anything following a '#' sign will be ignored from
the second line of the file, on to the end.

Returns 1 if the import has taken place.  This is to help you know
if old data has been deleted and new has been inserted.

=cut

sub importProducts {
    my $self     = shift;
    my $filePath = shift;
    my $session  = $self->session;
    WebGUI::Error::InvalidParam->throw(error => q{Must provide the path to a file})
        unless $filePath;
    WebGUI::Error::InvalidFile->throw(error => qq{File could not be found}, brokenFile => $filePath)
        unless -e $filePath;
    WebGUI::Error::InvalidFile->throw(error => qq{File is not readable}, brokenFile => $filePath)
        unless -r $filePath;
    open my $table, '<', $filePath or
        WebGUI::Error->throw(error => qq{Unable to open $filePath for reading: $!\n});

    my $headers;
    $headers = <$table>;
    chomp $headers;
    my @headers = WebGUI::Text::splitCSV($headers);
    WebGUI::Error::InvalidFile->throw(error => qq{Bad header found in the CSV file}, brokenFile => $filePath)
        unless (join(q{-}, sort @headers) eq 'mastersku-price-quantity-shortdescription-sku-title-weight')
           and (scalar @headers == 7);

    my @productData = ();
    my $line = 1;
    while (my $productRow = <$table>) {
        chomp $productRow;
        $productRow =~ s/\s*#.+$//;
        next unless $productRow;
        local $_;
        my @productRow = WebGUI::Text::splitCSV($productRow);
        WebGUI::Error::InvalidFile->throw(error => qq{Error found in the CSV file}, brokenFile => $filePath, brokenLine => $line)
            unless scalar @productRow == 7;
        push @productData, [ @productRow ];
    }

    return unless scalar @productData;

    ##Okay, if we got this far, then the data looks fine.
    my $fetchProductId = $session->db->prepare('select p.assetId from Product as p join sku as s on p.assetId=s.assetId and p.revisionDate=s.revisionDate where s.sku=? order by p.revisionDate DESC limit 1');
    my $node = WebGUI::Asset::Sku::Product->getProductImportNode($session);
    @headers = map { $_ eq 'shortdescription' ? 'shortdesc' : $_ } @headers;
    my @collateralFields = grep { $_ ne 'title' and $_ ne 'mastersku' } @headers;
    PRODUCT: foreach my $productRow (@productData) {
        my %productRow;
        ##Order the data according to the headers, in whatever order they exist.
        @productRow{ @headers } = @{ $productRow };
        ##Isolate just the collateral from the other product information
        my %productCollateral;
        @productCollateral{ @collateralFields } = @productRow{ @collateralFields };

        $fetchProductId->execute([$productRow{mastersku}]);
        my $asset = $fetchProductId->hashRef;

        ##If the assetId exists, we update data for it
        if ($asset->{assetId}) {
            $session->log->warn("Modifying an existing product: $productRow{sku} = $asset->{assetId}\n");
            my $assetId = $asset->{assetId};
            my $product = WebGUI::Asset->newPending($session, $assetId);

            ##Error handling for locked assets
            if ($product->isLocked) {
                $session->log->warn("Product is locked");
                next PRODUCT if $product->isLocked;
            }

            if ($productRow{title} ne $product->getTitle) {
                $product->update({ title => $product->fixTitle($productRow{title}) });
            }

            my $collaterals = $product->getAllCollateral('variantsJSON');
            my $collateralSet = 0;
            ROW: foreach my $collateral (@{ $collaterals }) {
                next ROW unless $collateral->{sku} eq $productRow{sku};
                @{ $collateral}{ @collateralFields } = @productCollateral{ @collateralFields };  ##preserve the variant Id field, assign all others
                $product->setCollateral('variantsJSON', 'variantId', $collateral->{variantId}, $collateral);
                $collateralSet=1;
            }
            if (!$collateralSet) {
                ##It must be a new variant
                $product->setCollateral('variantsJSON', 'variantId', 'new', \%productCollateral);
            }
        }
        else {
            ##Insert a new product;
            $session->log->warn("Making a new product: $productRow{sku}\n");
            my $newProduct = $node->addChild({className => 'WebGUI::Asset::Sku::Product'});
            $newProduct->update({
                title => $newProduct->fixTitle($productRow{title}),
                sku   => $productRow{mastersku},
            });
            $newProduct->setCollateral('variantsJSON', 'variantId', 'new', \%productCollateral);
            $newProduct->commit;
        }
    }
    return 1;
}

#-------------------------------------------------------------------

=head2 new ( $session )

Constructor for the WebGUI::Shop::Products.  Returns a WebGUI::Shop::Products object.

=cut

sub new {
    my $class   = shift;
    my $session = shift;
    my $self    = {};
    bless $self, $class;
    register $self;
    $session{ id $self } = $session;
    return $self;
}

#-------------------------------------------------------------------

=head2 www_exportProducts (  )

Export all product SKUs as a CSV file.  Returns a WebGUI::Storage
object containg the product file, named 'siteProductData.csv'.

=cut

sub www_exportProducts {
    my $self = shift;
    my $session = $self->session;
    my $admin = WebGUI::Shop::Admin->new($session);
    return $session->privilege->insufficient
        unless $admin->canManage;
    my $storage = $self->exportProducts();
    $session->http->setRedirect($storage->getUrl($storage->getFiles->[0]));
    return "redirect";
}

#-------------------------------------------------------------------

=head2 www_importProducts (  )

Import new product data from a file provided by the user.  This will create new products
or alter existing products.

=cut

sub www_importProducts {
    my $self    = shift;
    my $session = $self->session;
    my $admin = WebGUI::Shop::Admin->new($session);
    return $session->privilege->insufficient
        unless $admin->canManage;
    my $storage = WebGUI::Storage->create($session);
    my $productFile = $storage->addFileFromFormPost('importFile', 1);
    eval {
        $self->importProducts($storage->getPath($productFile)) if $productFile;
    };
    my ($exception, $status_message);
    if ($exception = Exception::Class->caught('WebGUI::Error::InvalidFile')) {
        $status_message = sprintf 'A problem was found with your file: %s',
            $exception->error;
        if ($exception->brokenLine) {
            $status_message .= sprintf ' on line %d', $exception->brokenLine;
        }
    }
    elsif ($exception = Exception::Class->caught()) {
        $status_message = sprintf 'A problem happened during the import: %s', $exception->error;
    }
    else {
        my $i18n = WebGUI::International->new($session, 'Shop');
        $status_message = $i18n->get('import successful');
        ##Copy and paste from Asset.pm, www_editSave
        if ($self->session->setting->get("autoRequestCommit")) {
            # Make sure version tag hasn't already been committed by another process
            my $versionTag = WebGUI::VersionTag->getWorking($self->session, "nocreate");

            if ($versionTag && $self->session->setting->get("skipCommitComments")) {
                $versionTag->requestCommit;
            }
            elsif ($versionTag) {
                $self->session->http->setRedirect(  
                    $self->getUrl("op=commitVersionTag;tagId=".WebGUI::VersionTag->getWorking($self->session)->getId)
                );
                return undef;
            }
        }
    }
    return $self->www_manage($status_message);
}

#-------------------------------------------------------------------

=head2 www_manage ( $status_message )

User interface to synchronize product data.  Provides an interface for
exporting all products on the site, and importing sets of products.

=head3 $status_message

An status message generated when import or export is called that needs to be
displayed back to the user.

=cut

sub www_manage {
    my $self          = shift;
    my $status_message = shift;
    my $session       = $self->session;
    my $admin = WebGUI::Shop::Admin->new($session);
    return $session->privilege->insufficient
        unless $admin->canManage;
    ##YUI specific datatable CSS
    my ($style, $url) = $session->quick(qw(style url));
    ##Default CSS
    $style->setRawHeadTags('<style type="text/css"> #paging a { color: #0000de; } #search, #export form { display: inline; } </style>');
    my $i18n=WebGUI::International->new($session, 'Shop');

    my $exportForm = WebGUI::Form::formHeader($session,{action => $url->page('shop=products;method=exportProducts')})
                   . WebGUI::Form::submit($session,{value=>$i18n->get('export'), extras=>q{style="float: left;"} })
                   . WebGUI::Form::formFooter($session);
    my $importForm = WebGUI::Form::formHeader($session,{action => $url->page('shop=products;method=importProducts')})
                   . WebGUI::Form::submit($session,{value=>$i18n->get('import'), extras=>q{style="float: left;"} })
                   . q{<input type="file" name="importFile" size="10" />}
                   . WebGUI::Form::formFooter($session);

    my $output;
    if ($status_message) {
        $output = sprintf <<EODIV,  $status_message; 
<div id="status_message">%s</div>
EODIV
    }

    $output .= sprintf <<EODIV,  $exportForm, $importForm;
    <div id="importExport">%s%s</div>
EODIV

    return $admin->getAdminConsole->render($output, $i18n->get('products'));
}

1;
