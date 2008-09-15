package WebGUI::Asset::Wobject::Shelf;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use List::MoreUtils;
use Tie::IxHash;
use WebGUI::International;
use base 'WebGUI::Asset::Wobject';
use WebGUI::Text;
use WebGUI::Storage;
use WebGUI::Exception::Shop;
use WebGUI::Asset::Sku::Product;

#-------------------------------------------------------------------

=head2 definition ( )

Add our custom properties of templateId to this asset.

=cut

sub definition {
	my ($class, $session, $definition) = @_;
	my $i18n = WebGUI::International->new($session, 'Asset_Shelf');
	my %properties;
	tie %properties, 'Tie::IxHash';
	%properties = (
		templateId =>{
			fieldType		=> "template",  
			defaultValue	=> 'nFen0xjkZn8WkpM93C9ceQ',
			tab				=> "display",
			namespace		=> "Shelf", 
			hoverHelp		=> $i18n->get('shelf template help'),
			label			=> $i18n->get('shelf template'),
		}
	);
	push(@{$definition}, {
		assetName			=> $i18n->get('assetName'),
		icon				=> 'Shelf.gif',
		autoGenerateForms	=> 1,
		tableName			=> 'Shelf',
		className			=> 'WebGUI::Asset::Wobject::Shelf',
		properties			=> \%properties
		});
        return $class->SUPER::definition($session, $definition);
}

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
    my $node = $self;
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

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
	$template->prepare($self->getMetaDataAsTemplateVariables);
	$self->{_viewTemplate} = $template;
}


#-------------------------------------------------------------------

=head2 view ( )

method called by the www_view method.  Returns a processed template
to be displayed within the page style.  

=cut

sub view {
	my $self = shift;
	my $session = $self->session;
	
	# get other shelves
	my @childShelves = ();
	foreach my $child (@{$self->getLineage(['children'],{returnObjects=>1,includeOnlyClasses=>['WebGUI::Asset::Wobject::Shelf']})}) {
		my $properties = $child->get;
		$child->{url} = $self->getUrl;
		push @childShelves, $child;
	}
	
	# get other child skus
	my @childSkus = @{$self->getLineage(['children'],{isa=>'WebGUI::Asset::Sku'})};
	
	# find products based upon keywords
	my @keywords = $self->get('keywords');
	my $keywordBasedAssetIds = WebGUI::Keyword->new($session)->getMatchingAssets({
		matchAssetKeywords	=> $self,
		isa					=> 'WebGUI::Asset::Sku',
		});

	# create paginator
	my @products = List::MoreUtils::uniq(@childSkus, @{$keywordBasedAssetIds});
	my $p = WebGUI::Paginator->new($session, $self->getUrl('func=view'));
	$p->setDataByArrayRef(\@products);

	# generate template variables
	my @skus = ();
	foreach my $id (@{$p->getPageData}) {
		my $asset = WebGUI::Asset->newByDynamicClass($session, $id);
		if (defined $asset) {
			my $sku = $asset->get;
			$sku->{url} = $asset->getUrl;
            $sku->{thumbnailUrl} = $asset->getThumbnailUrl;
            $sku->{price} = sprintf("%.2f", $asset->getPrice);
			push @skus, $sku;
		}
		else {
			$session->errorHandler->error(q|Couldn't instanciate SKU with assetId |.$id.q| on shelf with assetId |.$self->getId);
		}
	}
	my %var = (
		shelves		=> \@childShelves,
		products	=> \@skus,
		);
	$p->appendTemplateVars(\%var);
	
	# render page
	return $self->processTemplate(\%var, undef, $self->{_viewTemplate});
}


#-------------------------------------------------------------------
sub www_edit {
    my $self = shift;
	my $i18n = WebGUI::International->new($self->session, 'Asset_Shelf');
	if ($self->getId ne "new") {
		$self->getAdminConsole->addSubmenuItem($self->getUrl('func=exportProducts'),$i18n->get("export"));
		$self->getAdminConsole->addSubmenuItem($self->getUrl('func=importProducts'),$i18n->get("import"));
	}
	return $self->SUPER::www_edit();
}

#-------------------------------------------------------------------

=head2 www_exportProducts (  )

Export all product SKUs as a CSV file.  Returns a WebGUI::Storage
object containg the product file, named 'siteProductData.csv'.

=cut

sub www_exportProducts {
    my $self = shift;
    my $session = $self->session;
    return $session->privilege->insufficient
        unless $self->canEdit;
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
    return $session->privilege->insufficient unless $self->canEdit;
    my $i18n=WebGUI::International->new($session, 'Asset_Shelf');
 	my $status_message;
	if ( $session->form->get('doit')) {
		my $storage = WebGUI::Storage->create($session);
		my $productFile = $storage->addFileFromFormPost('importFile', 1);
		eval {
			$self->importProducts($storage->getPath($productFile)) if $productFile;
		};
		my $exception;
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
			$status_message = $i18n->get('import successful');
			##Copy and paste from WebGUI::Asset, www_editSave
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
	}
 
    my $output;
    if ($status_message) {
        $output = '<div id="status_message">'.$status_message.'</div>';
    }

    $output .= WebGUI::Form::formHeader($session,{action => $self->getUrl})
			. WebGUI::Form::hidden($session, {name=>"func", value=>"importProducts"})
			. WebGUI::Form::hidden($session, {name=>"doit", value=>1})
            . q{<input type="file" name="importFile" size="10" />}
            . WebGUI::Form::submit($session,{value=>$i18n->get('import'), extras=>q{style="float: left;"} })
            . WebGUI::Form::formFooter($session);
	
    return $self->getAdminConsole->render($output, $i18n->get('import'));
}


1;
