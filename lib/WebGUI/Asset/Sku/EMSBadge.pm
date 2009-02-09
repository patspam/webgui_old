package WebGUI::Asset::Sku::EMSBadge;

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
use Tie::IxHash;
use base 'WebGUI::Asset::Sku';
use JSON;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Shop::AddressBook;
use WebGUI::Utility;

=head1 NAME

Package WebGUI::Asset::Sku::EMSBadge

=head1 DESCRIPTION

A badge for the Event Manager. Badges allow you into the convention.

=head1 SYNOPSIS

use WebGUI::Asset::Sku::EMSBadge;

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 addToCart ( badgeInfo )

Adds this badge as configured for an individual to the cart.

=cut

sub addToCart {
	my ($self, $badgeInfo) = @_;
    if($self->getQuantityAvailable() < 1){ 
        return WebGUI::International->new($self->session, "Asset_EventManagementSystem")->get('no more available');
    }
	$badgeInfo->{badgeId} = "new";
	$badgeInfo->{badgeAssetId} = $self->getId;
	$badgeInfo->{emsAssetId} = $self->getParent->getId;
	my $badgeId = $self->session->db->setRow("EMSRegistrant","badgeId", $badgeInfo);
	$self->SUPER::addToCart({badgeId=>$badgeId});
}

#-------------------------------------------------------------------

=head2 definition

Adds price, seatsAvailable fields.

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	my $i18n = WebGUI::International->new($session, "Asset_EventManagementSystem");
	%properties = (
		price => {
			tab             => "shop",
			fieldType       => "float",
			defaultValue    => 0.00,
			label           => $i18n->get("price"),
			hoverHelp       => $i18n->get("price help"),
			},
		earlyBirdPrice => {
			tab             => "shop",
			fieldType       => "float",
			defaultValue    => 0.00,
			label           => $i18n->get("early bird price"),
			hoverHelp       => $i18n->get("early bird price help"),
			},
		earlyBirdPriceEndDate => {
			tab             => "shop",
			fieldType       => "date",
			defaultValue    => undef,
			label           => $i18n->get("early bird price end date"),
			hoverHelp       => $i18n->get("early bird price end date help"),
			},
		preRegistrationPrice => {
			tab             => "shop",
			fieldType       => "float",
			defaultValue    => 0.00,
			label           => $i18n->get("pre registration price"),
			hoverHelp       => $i18n->get("pre registration price help"),
			},
		preRegistrationPriceEndDate => {
			tab             => "shop",
			fieldType       => "date",
			defaultValue    => undef,
			label           => $i18n->get("pre registration price end date"),
			hoverHelp       => $i18n->get("pre registration price end date help"),
			},
		seatsAvailable => {
			tab             => "shop",
			fieldType       => "integer",
			defaultValue    => 100,
			label           => $i18n->get("seats available"),
			hoverHelp       => $i18n->get("seats available help"),
			},
		relatedBadgeGroups => {
			tab             => "properties",
			fieldType		=> "checkList",
			customDrawMethod=> 'drawRelatedBadgeGroupsField',
			label           => $i18n->get("related badge groups"),
			hoverHelp       => $i18n->get("related badge groups badge help"),
			},
		templateId => {
			tab             => "display",
			fieldType		=> "template",
			label           => $i18n->get("view badge template"),
			hoverHelp       => $i18n->get("view badge template help"),
            defaultValue    => 'PBEmsBadgeTemplate0000',
            namespace       => 'EMSBadge',
			},
	    );
	push(@{$definition}, {
		assetName           => $i18n->get('ems badge'),
		icon                => 'EMSBadge.gif',
		autoGenerateForms   => 1,
		tableName           => 'EMSBadge',
		className           => 'WebGUI::Asset::Sku::EMSBadge',
		properties          => \%properties
	    });
	return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------

=head2 drawRelatedBadgeGroupsField ()

Draws the field for the relatedBadgeGroups property.

=cut

sub drawRelatedBadgeGroupsField {
	my ($self, $params) = @_;
	return WebGUI::Form::checkList($self->session, {
		name		=> $params->{name},
		value		=> $self->get($params->{name}),
		vertical	=> 1,
		options		=> $self->getParent->getBadgeGroups,
		});
}


#-------------------------------------------------------------------

=head2 getConfiguredTitle

Returns title + badgeholder name

=cut

sub getConfiguredTitle {
    my $self = shift;
	my $name = $self->session->db->quickScalar("select name from EMSRegistrant where badgeId=?",[$self->getOptions->{badgeId}]);
    return $self->getTitle." (".$name.")";
}


#-------------------------------------------------------------------

=head2 getMaxAllowedInCart

Returns 1

=cut

sub getMaxAllowedInCart {
	return 1;
}

#-------------------------------------------------------------------

=head2 getPrice

Returns the price field value.

=cut

sub getPrice {
    my $self = shift;
	if ($self->get('earlyBirdPriceEndDate') < time) {
		return $self->get('price');
	}
	elsif ($self->get('preRegistrationPriceEndDate') < time) {
		return $self->get('earlyBirdPrice');
	}
	return $self->get('preRegistrationPrice');
}

#-------------------------------------------------------------------

=head2 getQuantityAvailable

Returns seatsAvailable - the count from the EMSRegistrant table.

=cut

sub getQuantityAvailable {
	my $self = shift;
	my $seatsTaken = $self->session->db->quickScalar("select count(*) from EMSRegistrant where badgeAssetId=?",[$self->getId]);
    return $self->get("seatsAvailable") - $seatsTaken;
}

#-------------------------------------------------------------------

=head2 onCompletePurchase (item)

Marks badge order as paid.

=cut

sub onCompletePurchase {
	my ($self, $item) = @_;
	my $badgeInfo = $self->getOptions;
	$badgeInfo->{purchaseComplete} = 1;
	$badgeInfo->{userId} = $self->session->user->userId; # they have to be logged in at this point
	$badgeInfo->{transactionItemId} = $item->getId;
	$self->session->db->setRow("EMSRegistrant","badgeId", $badgeInfo);
	return undef;
}

#-------------------------------------------------------------------

=head2 onRefund ( item)

Destroys the badge so that it can be resold.

=cut

sub onRefund {
	my ($self, $item) = @_;
	my $db = $self->session->db;
	my $badgeId = $self->getOptions->{badgeId};

	# refund any purchased tickets related to the badge 
	foreach my $id ($db->buildArray("select transactionItemId from EMSRegistrantTicket where badgeId=?",[$badgeId])) {		
		my $item = WebGUI::Shop::TransactionItem->newByDynamicTransaction($self->session, $id);
		if (defined $item) {
			$item->issueCredit;
		}
	}
	
	# refund any purchased ribbons related to the badge
	foreach my $id ($db->buildArray("select transactionItemId from EMSRegistrantRibbon where badgeId=?",[$badgeId])) {		
		my $item = WebGUI::Shop::TransactionItem->newByDynamicTransaction($self->session, $id);
		if (defined $item) {
			$item->issueCredit;
		}
	}
	
	# refund any purchased tokens related to this badge
	foreach my $ids ($db->buildArray("select transactionItemIds from EMSRegistrantToken where badgeId=?",[$badgeId])) {
		foreach my $id (split(',', $ids)) {
			my $item = WebGUI::Shop::TransactionItem->newByDynamicTransaction($self->session, $id);
			if (defined $item) {
				$item->issueCredit;
			}
		}
	}
	
	# get rid of any items in the cart related to this badge
	foreach my $cartitem (@{$self->getCart->getItems()}) {
		my $sku = $cartitem->getSku;
		if (isIn((ref $sku), qw(WebGUI::Asset::Sku::EMSTicket WebGUI::Asset::Sku::EMSRibbon WebGUI::Asset::Sku::EMSToken))) {
			if ($sku->getOptions->{badgeId} eq $badgeId) {
				$cartitem->remove;
			}
		}
	}
	
	# get rid ofthe badge itself 
	$db->write("delete from EMSRegistrant where transactionItemId=?",[$item->getId]);
	return undef;
}

#-------------------------------------------------------------------

=head2 onRemoveFromCart ( item )

Destroys badge.

=cut

sub onRemoveFromCart {
	my ($self, $item) = @_;
	my $badgeId = $self->getOptions->{badgeId};
	foreach my $cartitem (@{$item->cart->getItems()}) {
		my $sku = $cartitem->getSku;
		if (isIn((ref $sku), qw(WebGUI::Asset::Sku::EMSTicket WebGUI::Asset::Sku::EMSRibbon WebGUI::Asset::Sku::EMSToken))) {
			if ($sku->getOptions->{badgeId} eq $badgeId) {
				$cartitem->remove;
			}
		}
	}
	$self->session->db->deleteRow('EMSRegistrant','badgeId',$badgeId);
}

#-------------------------------------------------------------------

=head2 prepareView

See WebGUI::Asset, prepareView for details.

=cut

sub prepareView {
	my $self = shift;
    $self->SUPER::prepareView();
    my $templateId = $self->get('templateId');
    my $template = WebGUI::Asset::Template->new($self->session, $templateId);
    $self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------

=head2 purge

Deletes all badges and things attached to the badges. No refunds are given.

=cut

sub purge {
	my $self = shift;
	my $db = $self->session->db;
	$db->write("delete from EMSRegistrantTicket where badgeId=?",[$self->getId]);
	$db->write("delete from EMSRegistrantToken where badgeId=?",[$self->getId]);
	$db->write("delete from EMSRegistrantRibbon where badgeId=?",[$self->getId]);
	$db->write("delete from EMSRegistrant where badgeId=?",[$self->getId]);
	$self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 view

Displays badge description using a template.

=cut

sub view {
    my ($self) = @_;

    my $i18n    = WebGUI::International->new($self->session, "Asset_EventManagementSystem");
    my $form    = $self->session->form;
    my %vars    = ();
    my $session = $self->session;

    # build the form to allow the user to choose from their address book
    $vars{error} = $self->{_errorMessage};
    $vars{addressBook}  = WebGUI::Form::formHeader($session, {action => $self->getUrl})
                        . WebGUI::Form::hidden($session, {name=>"shop",   value =>'address'})
                        . WebGUI::Form::hidden($session, {name=>"method", value =>'view'})
                        . WebGUI::Form::hidden($session,
                            {
                                name  => "callback",
                                value => JSON->new->utf8->encode({ url => $self->getUrl})
                            })
                        . WebGUI::Form::submit($session, {value => $i18n->get("populate from address book")})
                        . WebGUI::Form::formFooter($session)
                        ;
	
    # instanciate address
    my $address = WebGUI::Shop::AddressBook->newBySession($self->session)->getAddress($form->get("addressId")) if ($form->get("addressId"));

    # build the form that the user needs to fill out with badge holder information
    $vars{formHeader} = WebGUI::Form::formHeader($session, {action => $self->getUrl})
                      . WebGUI::Form::hidden($session, {name=>"func", value =>'addToCart'});
    $vars{formFooter} = WebGUI::Form::formFooter($session);
    $vars{name}       = WebGUI::Form::text($session, {
                            name         => 'name',
                            defaultValue => (defined $address) ? $address->get("firstName")." ".$address->get('lastName') : $form->get('name'),
                        });
    $vars{organization} = WebGUI::Form::text($session, {
                            name         => 'organization',
                            defaultValue => (defined $address) ? $address->get("organization") : $form->get('organization'),
                        });
    $vars{address1} = WebGUI::Form::text($session, {
                            name         => 'address1',
                            defaultValue => (defined $address) ? $address->get("address1") : $form->get('address1'),
                        });
    $vars{address2} = WebGUI::Form::text($session, {
                            name         => 'address2',
                            defaultValue => (defined $address) ? $address->get("address2") : $form->get('address2'),
                        });
    $vars{address3} = WebGUI::Form::text($session, {
                            name         => 'address3',
                            defaultValue => (defined $address) ? $address->get("address3") : $form->get('address3'),
                        });
    $vars{city}     = WebGUI::Form::text($session, {
                            name         => 'city',
                            defaultValue => (defined $address) ? $address->get("city") : $form->get('city'),
                        });
    $vars{state}    = WebGUI::Form::text($session, {
                            name         => 'state',
                            defaultValue => (defined $address) ? $address->get("state") : $form->get('state'),
                        });
    $vars{zipcode}  = WebGUI::Form::text($session, {
                            name         => 'zipcode',
                            defaultValue => (defined $address) ? $address->get("code") : $form->get('zipcode','zipcode'),
                        });
    $vars{country}  = WebGUI::Form::text($session, {
                            name         => 'country',
                            defaultValue => (defined $address) ? $address->get("country") : ($form->get('country') || 'United States'),
                        });
    $vars{phone}  = WebGUI::Form::text($session, {
                            name         => 'phone',
                            defaultValue => (defined $address) ? $address->get('phoneNumber') : $form->get('phone','phone'),
                        });
    $vars{email}  = WebGUI::Form::text($session, {
                            name         => 'email',
                            defaultValue => (defined $address) ? $address->get('email') : $form->get('email','email'),
                        });
    if($self->getQuantityAvailable() > 0){ 
        $vars{submitAddress} = WebGUI::Form::submit($session, {value => $i18n->get('add to cart'),});
    }
    $vars{title}       = $self->getTitle;
    $vars{description} = $self->get('description');
	
    # render the page;
    return $self->processTemplate(\%vars, undef, $self->{_viewTemplate});
}


#-------------------------------------------------------------------

=head2 www_addToCart

Processes form from view() and then adds to cart.

=cut

sub www_addToCart {
	my ($self) = @_;
	return $self->session->privilege->noAccess() unless $self->getParent->canView;
	
	# gather badge info
	my $form = $self->session->form;
	my %badgeInfo = ();
	foreach my $field (qw(name address1 address2 address3 city state organization)) {
		$badgeInfo{$field} = $form->get($field, "text");
	}
	$badgeInfo{'phoneNumber'} = $form->get('phone',   'phone');
	$badgeInfo{'email'}       = $form->get('email',   'email');
	$badgeInfo{'country'}     = $form->get('country', 'country');
	$badgeInfo{'zipcode'}     = $form->get('zipcode', 'zipcode');
	

	# check for required fields
	my $error = "";
	my $i18n = WebGUI::International->new($self->session, 'Asset_EventManagementSystem');
	if ($badgeInfo{name} eq "") {
		$error =  sprintf $i18n->get('is required'), $i18n->get('name','Shop');
	}
	
	# return them back to the previous screen if they messed up
	if ($error) {
		$self->{_errorMessage} = $error;
		return $self->www_view($error);
	}
	
	# add it to the cart
	$self->addToCart(\%badgeInfo);
	return $self->getParent->www_buildBadge($self->getOptions->{badgeId});
}


#-------------------------------------------------------------------

=head2 www_edit ()

Displays the edit form.

=cut

sub www_edit {
	my ($self) = @_;
	return $self->session->privilege->insufficient() unless $self->canEdit;
	return $self->session->privilege->locked() unless $self->canEditIfLocked;
	$self->session->style->setRawHeadTags(q|
		<style type="text/css">
		.forwardButton {
			background-color: green;
			color: white;
			font-weight: bold;
			padding: 3px;
		}
		.backwardButton {
			background-color: red;
			color: white;
			font-weight: bold;
			padding: 3px;
		}
		</style>
						   |);	
	my $i18n = WebGUI::International->new($self->session, "Asset_EventManagementSystem");
	return $self->processStyle('<h1>'.$i18n->get('ems badge').'</h1>'.$self->getEditForm->print);
}

1;
