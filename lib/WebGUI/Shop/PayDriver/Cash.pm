package WebGUI::Shop::PayDriver::Cash;

use strict;

use WebGUI::Shop::PayDriver;
use WebGUI::Exception;

use base qw/WebGUI::Shop::PayDriver/;

#-------------------------------------------------------------------
sub canCheckoutCart {
    my $self    = shift;
    my $cart    = $self->getCart;

    return 0 unless $cart->readyForCheckout;
    return 0 if $cart->requiresRecurringPayment;

    return 1;
}

#-------------------------------------------------------------------

sub definition {
    my $class       = shift;
    my $session     = shift;
    my $definition  = shift;

    my $i18n = WebGUI::International->new($session, 'PayDriver_Cash');

    tie my %fields, 'Tie::IxHash';
    %fields = (
        sendReceipt         => {
            fieldType       => 'yesNo',
            label           => $i18n->echo('send receipt'),
            hoverHelp       => $i18n->echo('send receipt help'),
            defaultValue    => 0,
        },
        receiptFromAddress  => {
            fieldType       => 'email',
            label           => $i18n->echo('receipt from address'),
            hoverHelp       => $i18n->echo('receipt from address help'),
            defaultValue    => $session->setting->get('companyEmail'),
        },
        receiptSubject      => {
            fieldType       => 'text',
            label           => $i18n->echo('receipt subject'),
            hoverHelp       => $i18n->echo('receipt subject help'),
        },
        receiptTemplate     => {
            fieldType       => 'template',
            label           => $i18n->echo('receipt template'),
            hoverHelp       => $i18n->echo('receipt template help'),
            namespace       => 'PayDriver/Cash/Receipt',
            defaultValue    => undef,
        },
    );

    push @{ $definition }, {
        name        => $i18n->echo('Cash'),
        properties  => \%fields,
    };

    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------
sub getAddress {
    my ($self, $addressId)    = @_;
    if ($addressId) {
        return $self->getCart->getAddressBook->getAddress( $addressId );
    }
    # No billing address selected yet so return undef.
    return undef;
}

#-------------------------------------------------------------------

sub getButton {
    my $self    = shift;
    my $session = $self->session;
    my $i18n    = WebGUI::International->new($session, 'PayDriver_Cash');

    my $payForm = WebGUI::Form::formHeader($session)
        . $self->getDoFormTags('getCredentials')
        . WebGUI::Form::submit($session, {value => $i18n->echo('Cash') })
        . WebGUI::Form::formFooter($session);

    return $payForm;
}

#-------------------------------------------------------------------
sub getCartTemplateVariables {
    my $self    = shift;
    my $cart    = $self->getCart;
    my @itemLoop;

    # Process items in cart
    foreach my $item (@{ $cart->getItems }) {
        my $sku = $item->getSku;
        $sku->applyOptions( $item->get('options') );

        # Item properties
        my $itemProperties = $item->get;
        $itemProperties->{ itemName             } = $sku->get('title');
        $itemProperties->{ itemUrl              } = $sku->getUrl;
        $itemProperties->{ itemPrice            } = $cart->formatCurrency( $sku->getPrice );
        $itemProperties->{ totalItemPrice       } = $cart->formatCurrency( $sku->getPrice * $item->get('quantity') );

        # Custom item shipping address
        my $address = eval { $item->getShippingAddress };
        $itemProperties->{ itemShippingAddres   } = $address->getHtmlFormatted unless (WebGUI::Error->caught);

        push @itemLoop, $itemProperties;
    }

    my $cartProperties = $cart->get;
    $cartProperties->{ totalPrice       } = $cart->calculateSubtotal;
    $cartProperties->{ tax              } = $cart->calculateTaxes;

    # Include shipping address
    my $address = eval { $cart->getShippingAddress };
    $cartProperties->{ shippingAddress  } = $address->getHtmlFormatted unless (WebGUI::Error->caught);
#    $cartProperties->{ shippingPrice    } = 

    $cartProperties->{ item_loop        } = \@itemLoop;

    return $cartProperties;
}

#-------------------------------------------------------------------

sub processPayment {
    return (1, undef, 1, 'Success');
}

#-------------------------------------------------------------------

sub www_displayStatus {

}

#-------------------------------------------------------------------
sub www_getCredentials {
    my ($self, $addressId)    = @_;
    my $session = $self->session;
    $addressId = $session->form->process('addressId') if ($addressId eq "");
    # Generate the json string that defines where the address book posts the selected address
    my $callbackParams = {
        url     => $session->url->page,
        params  => [
            { name => 'shop',               value => 'pay' },
            { name => 'method',             value => 'do' },
            { name => 'do',                 value => 'setBillingAddress' },
            { name => 'paymentGatewayId',   value => $self->getId },
        ],
    };
    my $callbackJson = JSON::to_json( $callbackParams );

    # Generate 'Choose billing address' button
    my $addressButton = WebGUI::Form::formHeader( $session )
        . WebGUI::Form::hidden( $session, { name => 'shop',     value => 'address' } )
        . WebGUI::Form::hidden( $session, { name => 'method',   value => 'view' } )
        . WebGUI::Form::hidden( $session, { name => 'callback', value => $callbackJson } )
        . WebGUI::Form::submit( $session, { value => 'Choose billing address' } )
        . WebGUI::Form::formFooter( $session);

    # Get billing address
    my $billingAddress = eval { $self->getAddress($addressId) };
   
    my $billingAddressHtml;
    if ($billingAddress) {
        $billingAddressHtml = $billingAddress->getHtmlFormatted;
    }

    # Generate 'Proceed' button
    my $proceedButton = WebGUI::Form::formHeader( $session )
        . $self->getDoFormTags('pay')
        . WebGUI::Form::hidden($session, {name=>"addressId", value=>$addressId})
        . WebGUI::Form::submit( $session, { value => 'Pay' } )
        . WebGUI::Form::formFooter( $session);

    return $session->style->userStyle($addressButton.'<br />'.$billingAddressHtml.'<br />'.$proceedButton);
}

#-------------------------------------------------------------------

sub www_pay {
    my $self    = shift;
    my $session = $self->session;
    my $cart    = $self->getCart;
    my $i18n    = WebGUI::International->new($session, 'PayDriver_Cash');
    my $var;

    # Make sure we can checkout the cart
    return "" unless $self->canCheckoutCart;

    # Make sure all required credentials have been supplied
    my $billingAddress = $self->getAddress( $session->form->process('addressId') );
    return $self->www_getCredentials unless $billingAddress;

    # Generate a receipt and send it if enabled.
    if ( $self->get('sendReceipt') ) {
        # Setup receipt tmpl_vars
        my $var = $self->getCartTemplateVariables;
 
        # Instanciate receipt template
        my $template = WebGUI::Asset::Template->new( $session, $self->get('receiptTemplate') );
        WebGUI::Error::ObjectNotFound->throw( id => $self->get('receiptTemplate') )
            unless $template;

        # Send receipt
        my $receipt = WebGUI::Mail::Send->create( $session, {
            to          => $session->user->profileField('email'),
            from        => $self->get('receiptFromAddress'),
            subject     => $self->get('receiptSubject'),
        });
        $receipt->addText( $template->process( $var ) );
        $receipt->queue;
    }


    # Complete the transaction
    my $transaction = $self->processTransaction( $billingAddress );

    return $transaction->thankYou();
}

#-------------------------------------------------------------------

sub www_setBillingAddress {
    my $self    = shift;
    my $session = $self->session;
    return $self->www_getCredentials($session->form->process('addressId'));
}

1;

