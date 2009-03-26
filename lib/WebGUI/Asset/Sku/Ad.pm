package WebGUI::Asset::Sku::Ad;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use Tie::IxHash;
use base 'WebGUI::Asset::Sku';
use WebGUI::Asset::Template;
use WebGUI::Form;
use WebGUI::Shop::Pay;
use WebGUI::AssetCollateral::Sku::Ad::Ad;
use WebGUI::AdSpace::Ad;

=head1 NAME

Package WebGUI::Asset::Sku::Ad	

=head1 DESCRIPTION

This Asset allows ads to be purchased via WebGUI shopping

=head1 SYNOPSIS

use WebGUI::Asset::Sku::Ad;

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 definition

Adds purchaseTemplate, manageTemplate, adSpace, priority, pricePerClick, pricePerImpression, clickDiscounts, impresisonDiscounts

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	my $i18n = WebGUI::International->new($session, "Asset_AdSku");
	%properties = (
		purchaseTemplate      => {
			tab             => "display",
			fieldType       => "template",
                        namespace       => "AdSku/Purchase",
			defaultValue    => 'R5zzB-ElsYbbiaS7aS3Uxw',
			label           => $i18n->get("property purchase template"),
			hoverHelp       => $i18n->get("property purchase template help"),
		},
		manageTemplate      => {
			tab             => "display",
			fieldType       => "template",
                        namespace       => "AdSku/Manage",
			defaultValue    => 'xZyizWwkApUyvpHL9mI-FQ',
			label           => $i18n->get("property manage template"),
			hoverHelp       => $i18n->get("property manage template help"),
		},
        adSpace => {
            tab             => "properties",
            fieldType       => "AdSpace",
            namespace       => "AdSku",
            label           => $i18n->get("property ad space"),
            hoverHelp       => $i18n->get("property ad Space help"),
        },
        priority => {
            tab             => "properties",
            defaultValue    => '1',
		fieldType       => "integer",
		label           => $i18n->get("property priority"),
		hoverHelp       => $i18n->get("property priority help"),
            },
        pricePerClick => {
            tab             => "properties",
            defaultValue    => '0.00',
		fieldType       => "float",
		label           => $i18n->get("property price per click"),
		hoverHelp       => $i18n->get("property price per click help"),
            },
        pricePerImpression => {
            tab             => "properties",
            defaultValue    => '0.00',
		fieldType       => "float",
		label           => $i18n->get("property price per impression"),
		hoverHelp       => $i18n->get("property price per impression help"),
            },
        clickDiscounts   => {
            fieldType       => 'textarea',
            label	    => $i18n->get('property click discounts'),
            hoverHelp	    => $i18n->get('property click discounts help'),
            defaultValue    => '',
        },
        impressionDiscounts => {
            fieldType       => 'textarea',
            label	    => $i18n->get('property impression discounts'),
            hoverHelp	    => $i18n->get('property impression discounts help'),
            defaultValue    => '',
        },
    );

    # Show the karma field only if karma is enabled
    if ($session->setting->get("useKarma")) {
        $properties{ karma    } = {
            type            => 'integer',
            label           => $i18n->get('property adsku karma'),
            hoverHelp       => $i18n->get('property adsku karma description'),
            defaultvalue	=> 0,
        };
    }

	push(@{$definition}, {
		assetName           => $i18n->get('assetName'),
		icon                => 'adsku.gif',
		autoGenerateForms   => 1,
		tableName           => 'AdSku',
		className           => 'WebGUI::Asset::Sku::AdSku',
		properties          => \%properties,
	    });
	return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2 getClickDiscountText

returns the text to display the number of clicks purchasaed where discounts apply

=cut

sub getClickDiscountText {
     my $self = shift;
     return getDiscountText($self->i18n->get('click discount'),
                             $self->get('clickDiscounts'));
}

#-------------------------------------------------------------------

=head2 getConfiguredTitle

combines the adSKu title with the customers ad title

=cut

sub getConfiguredTitle {
     my $self = shift;
     return $self->get('title') . ' (' . $self->getOptions->{'adtitle'} . ')';
}

#-------------------------------------------------------------------

=head2 getDiscountAmount  -- class level function

returns the amount of discount to apply to this purchase

=cut

sub getDiscountAmount {
    my($discounts,$count) = @_;
    my @discounts = parseDiscountText( $discounts );
    my $previousDiscount = 0;
    foreach my $discountSet ( @discounts ) {
        last if $count < $discountSet->[1];
	$previousDiscount = $discountSet->[0];
    }
    return $previousDiscount;
}

#-------------------------------------------------------------------

=head2 getDiscountText  -- class level function

returns a string with a coma seperated list of counts from the discount text

=cut

sub getDiscountText {
    my($format,$discounts) = @_;
    return sprintf( $format, join( ',', (map { $_->[1] } ( parseDiscountText( $discounts ) ) ) ) );
}

#-------------------------------------------------------------------

=head2 getImpressionDiscountText

returns the text to display the number of impressions purchased where discounts apply

=cut

sub getImpressionDiscountText {
    my $self = shift;
    return getDiscountText($self->i18n->get('impression discount'),
                              $self->get('impressionDiscounts'));
}

#-------------------------------------------------------------------

=head2 getPrice

get the price for this purchase

=cut

sub getPrice {
    my $self = shift;
    my $options = $self->getOptions;
    my $impressionCount = $options->{impressions} || $self->{formImpressions};
    my $clickCount = $options->{clicks};
    my $impressionDiscount = getDiscountAmount($self->get('impressionDiscounts'),$impressionCount );
    my $clickDiscount = getDiscountAmount($self->get('clickDiscounts'),$clickCount );
    my $impressionPrice = $self->get('pricePerImpression') * ( 100 - $impressionDiscount ) / 100 ;
    my $clickPrice = $self->get('pricePerClick') * ( 100 - $clickDiscount ) / 100 ;
    return sprintf "%.2f", $impressionPrice * $impressionCount + $clickPrice * $clickCount;
}

#-------------------------------------------------------------------

=head2  i18n  

returns an internationalization object for this class

=cut

sub i18n {
    my $self = shift;
    return WebGUI::International->new($self->session, "Asset_AdSku");
}

#-------------------------------------------------------------------

=head2 manage

generate template vars for manage page

=cut

sub manage {
    my ($self) = @_;
    my $session = $self->session;

    my $i18n = WebGUI::International->new($session, "Asset_AdSku");
    my %var;
    $var{purchaseLink} = $self->getUrl;
    my $iterator = WebGUI::AssetCollateral::Sku::Ad::Ad->getAllIterator($session,{
	     constraints => [ { "adSkuPurchase.userId = ?" => $self->session->user->userId } ],
	     orderBy => 'dateOfPurchase',
             });
    my %ads;
    while( my $object = $iterator->() ) {
	next if $object->get('isDeleted');
        next if exists $ads{$object->get('adId')};
	my $ad = $ads{$object->get('adId')} = WebGUI::AdSpace::Ad->new($session,$object->get('adId'));
        push @{$var{myAds}}, {
	      rowTitle => $ad->get('title'),
	      rowClicks => $ad->get('clicks') . '/' . $ad->get('clicksBought'),
	      rowImpressions => $ad->get('impressions') . '/' . $ad->get('impressionsBought'),
	      rowRenewLink => $self->getUrl('func=renew;Id=' . $object->get('adSkuPurchaseId') ),
	};
    }
    return $self->processTemplate(\%var,undef,$self->{_viewTemplate});
}

#-------------------------------------------------------------------

=head2 onCompletePurchase

inserts the ad into the adspace...

=cut

sub onCompletePurchase {
    my $self = shift;
    my $item = shift;
    my $options = $self->getOptions;
    my $ad;

# LATER: if we use Temp Storage for the image we need to move it to perm storage

    if( $options->{adId} ne '' ) {
	$ad = WebGUI::AdSpace::Ad->new($self->session,$options->{adId});
	my $clicks = $options->{clicks} + $ad->get('clicksBought');
	my $impressions = $options->{impressions} + $ad->get('impressionsBought');
	$ad->set({
            title =>  $options->{'adtitle'},
	    clicksBought => $clicks,
	    impressionsBought => $impressions,
	    url =>   $options->{'link'},
	    storageId =>  $options->{'image'},
	});
    } else {
        $ad = WebGUI::AdSpace::Ad->create($self->session,$self->get('adSpace'),{
            title =>  $options->{'adtitle'},
	    clicksBought => $options->{'clicks'},
	    impressionsBought => $options->{'impressions'},
	    url =>   $options->{'link'},
	    storageId =>  $options->{'image'},
	    ownerUserId =>  $self->session->user->userId,
	    isActive => 1,
	    type =>  'image',
	    priority => $self->get('priority'),
	    adSpace => $self->get('adSpace'),
        });
    }

    WebGUI::AssetCollateral::Sku::Ad::Ad->create($self->session,{
           userId => $item->transaction->get('userId'),
	   transactionItemId => $item->getId,
	   adId => $ad->getId,
	   clicksPurchased => $options->{'clicks'},
	   impressionsPurchased => $options->{'impressions'},
	   dateOfPurchase => $item->transaction->get('dateOfPurchase'),
	   storedImage =>  $options->{'image'},
	   isDeleted => 0,
        });

}

#-------------------------------------------------------------------

=head2 onRemoveFromCart

deletes the image if it gets removed from the cart

LATER: if we switch to using Temp Storage we do not need to do this.

=cut

sub  onRemoveFromCart {
    my $self = shift;
    my $item = shift;
    my $options = $self->getOptions;
    WebGUI::Storage->new($self->session,$options->{'image'})->delete; 
}

#-------------------------------------------------------------------

=head2 onRefund

delete the add if it gets refunded

=cut

sub  onRefund {
    my $self = shift;
    my $item = shift;

    my $iterator = WebGUI::AssetCollateral::Sku::Ad::Ad->getAllIterator($self->session,{
	     constraints => [ { "transactionItemId = ?" => $item->getId } ],
             });
    my $crud = $iterator->();

    my $ad = WebGUI::AdSpace::Ad->new($self->session,$crud->get('adId'));
    my $clicks = $ad->get('clicksBought') - $crud->get('clicksPurchased');
    my $impressions = $ad->get('impressionsBought') - $crud->get('impressionsPurchased') ;
    $ad->set({
	clicksBought => $clicks,
	impressionsBought => $impressions,
    });

    $crud->delete;
}

#-------------------------------------------------------------------

=head2 parseDiscountText  -- class level function

returns an array of array ref's that are extracted from the discount description text

=cut

sub  parseDiscountText {
    my $discountDescription = shift;
    my @lines = split "\n", $discountDescription;
    my @discounts;
    foreach my $line ( @lines ) {
	if( $line =~ /^(\d+)\@(\d+)/ ) {
            push @discounts, [ $1, $2 ];
	}
    }
    return sort { $a->[1] <=> $b->[1] } @discounts;
}

#-------------------------------------------------------------------

=head2 prepareManage

Prepares the template.

=cut

sub prepareManage {
	my $self = shift;
	$self->SUPER::prepareView();
	my $templateId = $self->get("manageTemplate");
	my $template = WebGUI::Asset::Template->new($self->session, $templateId);
	$template->prepare($self->getMetaDataAsTemplateVariables);
	$self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------

=head2 prepareView

Prepares the template.

=cut

sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $templateId = $self->get("purchaseTemplate");
	my $template = WebGUI::Asset::Template->new($self->session, $templateId);
	$template->prepare($self->getMetaDataAsTemplateVariables);
	$self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------

=head2 view

Displays the purchase adspace form

=cut

sub view {
    my ($self) = @_;
    my $session = $self->session;
    my $options = $self->getOptions();

	my $i18n = WebGUI::International->new($session, "Asset_AdSku");
    my %var = (
        formHeader          => WebGUI::Form::formHeader($session, { action=>$self->getUrl })
            . WebGUI::Form::hidden( $session, { name=>"func", value=>"addToCart" }),
        formFooter          => WebGUI::Form::formFooter($session),
        formSubmit          => WebGUI::Form::submit( $session,  { value => $i18n->get("form purchase button") }),
        hasAddedToCart      => $self->{_hasAddedToCart},
        continueShoppingUrl => $self->getUrl,
        manageLink         => $self->getUrl("func=manage"),
        adSkuTitle         => $self->get('title'),
        adSkuDescription   => $self->get('description'),
        formTitle          => WebGUI::Form::text($session, {
                                 -name=>"formTitle",
                                 -value=>$options->{adtitle},
                                 -size=>40
				 -default=>'untitled',
                                }),
        formLink           => WebGUI::Form::Url($session, {
                                 -name=>"formLink",
                                 -value=>$options->{link},
                                 -size=>40
				 -required=>1,
                                }),
        formImage          => WebGUI::Form::File($session, {
                                 -name=>"formImage",
                                 -value=>$options->{image},
                                 -size=>40
				 -forceImageOnly=>1,
                                }),
        formClicks          => WebGUI::Form::Integer($session, {
                                 -name=>"formClicks",
                                 -value=>$options->{clicks},
                                 -size=>40
				 -required=>1,
                                }),
        formImpressions          => WebGUI::Form::Integer($session, {
                                 -name=>"formImpressions",
                                 -value=>$options->{impressions},
                                 -size=>40
				 -required=>1,
                                }),
        formAdId          => WebGUI::Form::Hidden($session, {
                                 -name=>"formAdId",
                                 -value=>$options->{adId} || '',
                                }),
        clickPrice   => $self->get('pricePerClick'),
        impressionPrice   => $self->get('pricePerImpression'),
        clickDiscount   => $self->getClickDiscountText,
        impressionDiscount   => $self->getImpressionDiscountText,
    );
    return $self->processTemplate(\%var,undef,$self->{_viewTemplate});
}

#-------------------------------------------------------------------

=head2 www_addToCart

Add this subscription to the cart.

=cut

sub www_addToCart {
    my $self = shift;
    if ($self->canView) {
        $self->{_hasAddedToCart} = 1;
	my $form = $self->session->form;
	my $imageStorage = $self->getOptions->{image} || WebGUI::Storage->create($self->session);  # LATER should be createTemp
        my $imageStorageId = $form->process('formImage', 'image', $imageStorage->getId);
        my $cartInfo = {
              adtitle => $form->process('formTitle'),
	      link => $form->process('formLink','url'),
	      clicks => $form->process('formClicks','integer'),
	      impressions => $form->process('formImpressions','integer'),
	      adId => $form->process('formAdId'),
	      image => $imageStorageId,
	             };
        $self->addToCart($cartInfo);
    }
    return $self->www_view;
}

#-------------------------------------------------------------------

=head2 www_manage

manage previously purchased ads

=cut

sub www_manage {
        my $self = shift;
        my $check = $self->checkView;
        return $check if (defined $check);
        $self->session->http->setLastModified($self->getContentLastModified);
        $self->session->http->sendHeader;
        $self->prepareManage;
        my $style = $self->processStyle($self->getSeparator);
        my ($head, $foot) = split($self->getSeparator,$style);
        $self->session->output->print($head, 1);
        $self->session->output->print($self->manage);
        $self->session->output->print($foot, 1);
        return "chunked";
}

#-------------------------------------------------------------------

=head2 www_renew

renew an ad

=cut

sub www_renew {
        my $self = shift;
	my $session = $self->session;
	my $id = $session->form->get('Id');
        my $crud = WebGUI::AssetCollateral::Sku::Ad::Ad->new($session,$id);
	my $ad = WebGUI::AdSpace::Ad->new($session,$crud->get('adId'));
	$self->applyOptions({
                  adtitle =>  $ad->get('title'),
		  clicks => $crud->get('clicksPurchased'),
		  impressions => $crud->get('impressionsPurchased'),
		  link => $ad->get('url'),
		  image => $ad->get('storageId'),
		  adId => $crud->get('adId'),
             });
	return $self->www_view;
}

1;

