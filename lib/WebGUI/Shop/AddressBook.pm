package WebGUI::Shop::AddressBook;

use strict;

use Class::InsideOut qw{ :std };
use JSON;
use WebGUI::Asset::Template;
use WebGUI::Exception::Shop;
use WebGUI::Form;
use WebGUI::International;
use WebGUI::Shop::Address;

=head1 NAME

Package WebGUI::Shop::AddressBook;

=head1 DESCRIPTION

Managing addresses for commerce.

=head1 SYNOPSIS

 use WebGUI::Shop::AddressBook;

 my $book = WebGUI::Shop::AddressBook->new($session);

=head1 METHODS

These subroutines are available from this package:

=cut

readonly session => my %session;
private properties => my %properties;
private addressCache => my %addressCache;

#-------------------------------------------------------------------

=head2 addAddress ( address )

Adds an address to the address book.  Returns a reference to the WebGUI::Shop::Address
object that was created.  It does not trap exceptions, so any problems with creating
the object will be passed to the caller.

=head2 address

A hash reference containing address information.

=cut

sub addAddress {
    my ($self, $address) = @_;
    my $addressObj = WebGUI::Shop::Address->create( $self, $address);
    return $addressObj;
}

#-------------------------------------------------------------------

=head2 create ( session )

Constructor. Creates a new address book for this user or session if no user is logged in.

=head3 session

A reference to the current session.

=cut

sub create {
    my ($class, $session) = @_;
    unless (defined $session && $session->isa("WebGUI::Session")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Session", got=>(ref $session), error=>"Need a session.");
    }
    my $id = $session->db->setRow("addressBook", "addressBookId", {addressBookId=>"new", userId=>$session->user->userId, sessionId=>$session->getId}); 
    return $class->new($session, $id);
}

#-------------------------------------------------------------------

=head2 delete ()

Deletes this address book and all addresses contained in it.

=cut

sub delete {
    my ($self) = @_;
    foreach my $address (@{$self->getAddresses}) {
        $address->delete;
    } 
    $self->session->db->write("delete from addressBook where addressBookId=?",[$self->getId]);
    undef $self;
    return undef;
}

#-------------------------------------------------------------------

=head2 formatCallbackForm ( callback )

Returns an HTML hidden form field with the callback JSON block properly escaped.

=head3 callback

A JSON string that holds the callback information.

=cut

sub formatCallbackForm {
    my ($self, $callback) = @_;
    $callback =~ s/"/'/g;
    return '<input type="hidden" name="callback" value="'.$callback.'" />';
}

#-------------------------------------------------------------------

=head2 get ( [ property ] )

Returns a duplicated hash reference of this object’s data.

=head3 property

Any field − returns the value of a field rather than the hash reference.  See the 
C<update> method.

=cut

sub get {
    my ($self, $name) = @_;
    if (defined $name) {
        return $properties{id $self}{$name};
    }
    my %copyOfHashRef = %{$properties{id $self}};
    return \%copyOfHashRef;
}

#-------------------------------------------------------------------

=head2 getAddress ( id )

Returns an address object.

=head3 id

An address object's unique id.

=cut

sub getAddress {
    my ($self, $addressId) = @_;
    my $id = ref $self;
    unless (exists $addressCache{$id}{$addressId}) {
        $addressCache{$id}{$addressId} = WebGUI::Shop::Address->new($self, $addressId);
    }
    return $addressCache{$id}{$addressId};
}

#-------------------------------------------------------------------

=head2 getAddresses ( )

Returns an array reference of address objects that are in this book.

=cut

sub getAddresses {
    my ($self) = @_;
    my @addressObjects = ();
    my $addresses = $self->session->db->read("select addressId from address where addressBookId=?",[$self->getId]);
    while (my ($addressId) = $addresses->array) {
        push(@addressObjects, $self->getAddress($addressId));
    }
    return \@addressObjects;
}

#-------------------------------------------------------------------

=head2 getId ()

Returns the unique id for this cart.

=cut

sub getId {
    my ($self) = @_;
    return $self->get("addressBookId");
}

#-------------------------------------------------------------------

=head2 new ( session, addressBookId )

Constructor.  Instanciates a cart based upon a addressBookId.

=head3 session

A reference to the current session.

=head3 addressBookId

The unique id of an address book to instanciate.

=cut

sub new {
    my ($class, $session, $addressBookId) = @_;
    unless (defined $session && $session->isa("WebGUI::Session")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Session", got=>(ref $session), error=>"Need a session.");
    }
    unless (defined $addressBookId) {
        WebGUI::Error::InvalidParam->throw(error=>"Need an addressBookId.");
    }
    my $addressBook = $session->db->quickHashRef('select * from addressBook where addressBookId=?', [$addressBookId]);
    if ($addressBook->{addressBookId} eq "") {
        WebGUI::Error::ObjectNotFound->throw(error=>"No such address book.", id=>$addressBookId);
    }
    my $self = register $class;
    my $id        = id $self;
    $session{ $id }   = $session;
    $properties{ $id } = $addressBook;
    return $self;
}

#-------------------------------------------------------------------

=head2 newBySession ( session )

Constructor. Creates a new address book for this user if they don't have one. If the user is not logged in creates an address book attached to the session if there isn't one for the session. In any case returns a reference to the address book.

=head3 session

A reference to the current session.

=cut

sub newBySession {
    my ($class, $session) = @_;
    unless (defined $session && $session->isa("WebGUI::Session")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Session", got=>(ref $session), error=>"Need a session.");
    }
    my $userId = $session->user->userId;
    
    # check to see if this user or his session already has an address book
    my @ids = $session->db->buildArray("select addressBookId from addressBook where (userId<>'1' and userId=?) or sessionId=?",[$session->user->userId, $session->getId]);
    if (scalar(@ids) > 0) {
        my $book = $class->new($session, $ids[0]);
        
        # convert it to a specific user if we can
        if ($userId ne '1') {
            $book->update({userId => $userId, sessionId => ''});
        }
        
        # merge others if needed
        if (scalar(@ids) > 1) {
            # it's attached to the session or we have too many so lets merge them
            shift @ids;
            foreach my $id (@ids) {
                my $oldbook = $class->new($session, $id);
                foreach my $address (@{$oldbook->getAddresses}) {
                    $address->update({addressBookId=>$book->getId});
                }
                $oldbook->delete;
            }
        }
        return $book;
    }
    else {
        # nope create one for the user
        return $class->create($session);
    }
}


#-------------------------------------------------------------------

=head2 update ( properties )

Sets properties in the addressBook

=head3 properties

A hash reference that contains one of the following:

=head4 userId

Assign the user that owns this address book.

=head4 sessionId

Assign the session, by id, that owns this address book. Will automatically be set to "" if a user owns it.

=cut

sub update {
    my ($self, $newProperties) = @_;
    my $id = id $self;
    foreach my $field (qw(userId sessionId)) {
        $properties{$id}{$field} = (exists $newProperties->{$field}) ? $newProperties->{$field} : $properties{$id}{$field};
    }
    ##Having both a userId and sessionId will confuse create.
    if ($properties{$id}{userId} ne "") {
        $properties{$id}{sessionId} = "";
    }
    $self->session->db->setRow("addressBook","addressBookId",$properties{$id});
}

#-------------------------------------------------------------------

=head2 www_deleteAddress ( )

Deletes an address from the book.

=cut

sub www_deleteAddress {
    my $self = shift;
    $self->getAddress($self->session->form->get("addressId"))->delete;
    return $self->www_view;
}

#-------------------------------------------------------------------

=head2 www_editAddress ()

Allows a user to edit an address in their address book.

=cut

sub www_editAddress {
    my ($self, $error) = @_;
    my $session = $self->session;
    my $form = $session->form;
    my $address = eval{$self->getAddress($form->get("addressId"))};
    if (WebGUI::Error->caught) {
        $address = undef;
    }
    my %base = ();
    if (defined $address) {
        %base = %{$address->get};
    }
    my %var = (
        %base,
        error               => $error,
        formHeader          => WebGUI::Form::formHeader($session)
                                .WebGUI::Form::hidden($session, {name=>"shop", value=>"address"})
                                .$self->formatCallbackForm($form->get('callback'))
                                .WebGUI::Form::hidden($session, {name=>"method", value=>"editAddressSave"})
                                .WebGUI::Form::hidden($session, {name=>"addressId", value=>$form->get("addressId")}),
        saveButton          => WebGUI::Form::submit($session),
        formFooter          => WebGUI::Form::formFooter($session),
        address1Field       => WebGUI::Form::text($session, 
                {name=>"address1", maxlength=>35, defaultValue=>($form->get("address1") || ((defined $address) ? $address->get('address1') : undef))}),
        address2Field       => WebGUI::Form::text($session, 
                {name=>"address2", maxlength=>35, defaultValue=>($form->get("address2") || ((defined $address) ? $address->get('address2') : undef))}),
        address3Field       => WebGUI::Form::text($session, 
                {name=>"address3", maxlength=>35, defaultValue=>($form->get("address3") || ((defined $address) ? $address->get('address3') : undef))}),
        labelField          => WebGUI::Form::text($session, 
                {name=>"label", maxlength=>35, defaultValue=>($form->get("label") || ((defined $address) ? $address->get('label') : undef))}),
        firstNameField      => WebGUI::Form::text($session, 
                {name=>"firstName", maxlength=>35, defaultValue=>($form->get("firstName") || ((defined $address) ? $address->get('firstName') : undef))}),
        lastNameField       => WebGUI::Form::text($session, 
                {name=>"lastName", maxlength=>35, defaultValue=>($form->get("lastName") || ((defined $address) ? $address->get('lastName') : undef))}),
        cityField           => WebGUI::Form::text($session, 
                {name=>"city", maxlength=>35, defaultValue=>($form->get("city") || ((defined $address) ? $address->get('city') : undef))}),
        stateField          => WebGUI::Form::text($session, 
                {name=>"state", maxlength=>35, defaultValue=>($form->get("state") || ((defined $address) ? $address->get('state') : undef))}),
        countryField        => WebGUI::Form::country($session, 
                {name=>"country", defaultValue=>($form->get("country") || ((defined $address) ? $address->get('country') : undef))}),
        codeField           => WebGUI::Form::zipcode($session, 
                {name=>"code", defaultValue=>($form->get("code") || ((defined $address) ? $address->get('code') : undef))}),
        phoneNumberField    => WebGUI::Form::phone($session, 
                {name=>"phoneNumber", defaultValue=>($form->get("phoneNumber") || ((defined $address) ? $address->get('phoneNumber') : undef))}),
        emailField          => WebGUI::Form::email($session, 
                {name=>"email", defaultValue=>($form->get("email") || ((defined $address) ? $address->get('email') : undef))}),
        organizationField    => WebGUI::Form::text($session, 
                {name=>"organization", defaultValue=>($form->get("organization") || ((defined $address) ? $address->get('organization') : undef))}),
    );
    my $template = WebGUI::Asset::Template->new($session, $session->setting->get("shopAddressTemplateId"));
    $template->prepare;
    return $session->style->userStyle($template->process(\%var));
}



#-------------------------------------------------------------------

=head2 www_editAddressSave ()

Saves the address. If there is a problem generates www_editAddress() with an error message. Otherwise returns www_view().

=cut

sub www_editAddressSave {
    my $self = shift;
    my $form = $self->session->form;
    my $i18n = WebGUI::International->new($self->session,"Shop");
    if ($form->get("label") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('label')));
    }    
    if ($form->get("firstName") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('firstName')));
    }    
    if ($form->get("lastName") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('lastName')));
    }    
    if ($form->get("address1") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('address')));
    }    
    if ($form->get("city") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('city')));
    }    
    if ($form->get("code") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('code')));
    }    
    if ($form->get("country") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('country')));
    }    
    if ($form->get("phoneNumber") eq "") {
        return $self->www_editAddress(sprintf($i18n->get('is a required field'), $i18n->get('phone number')));
    }    
    my %addressData = (
        label           => $form->get("label"),
        firstName       => $form->get("firstName"),
        lastName        => $form->get("lastName"),
        address1        => $form->get("address1"),
        address2        => $form->get("address2"),
        address3        => $form->get("address3"),
        city            => $form->get("city"),
        state           => $form->get("state"),
        code            => $form->get("code","zipcode"),
        country         => $form->get("country","country"),
        phoneNumber     => $form->get("phoneNumber","phone"),
        email           => $form->get("email","email"),
        organization    => $form->get("organization"),
        );
    if ($form->get('addressId') eq '') {
        $self->addAddress(\%addressData);
    }
    else {
        $self->getAddress($form->get('addressId'))->update(\%addressData);
    }
    return $self->www_view;
}


#-------------------------------------------------------------------

=head2 www_view

Displays the current user's address book.

=cut

sub www_view {
    my $self = shift;
    my $session = $self->session;
    my $form = $session->form;
    my $callback = $form->get('callback');
    $callback =~ s/'/"/g;
    $callback = JSON->new->utf8->decode($callback);
    my $callbackForm = '';
    foreach my $param (@{$callback->{params}}) {
        $callbackForm .= WebGUI::Form::hidden($session, {name=>$param->{name}, value=>$param->{value}});
    }
    my $i18n = WebGUI::International->new($session, "Shop");
    my @addresses = ();
    foreach my $address (@{$self->getAddresses}) {
        push(@addresses, {
            %{$address->get},
            address         => $address->getHtmlFormatted,
            deleteButton    => WebGUI::Form::formHeader($session)
                                .WebGUI::Form::hidden($session, {name=>"shop", value=>"address"})
                                .WebGUI::Form::hidden($session, {name=>"method", value=>"deleteAddress"})
                                .WebGUI::Form::hidden($session, {name=>"addressId", value=>$address->getId})
                                .$self->formatCallbackForm($form->get('callback'))
                                .WebGUI::Form::submit($session, {value=>$i18n->get("delete")})
                                .WebGUI::Form::formFooter($session),
            editButton      => WebGUI::Form::formHeader($session)
                                .WebGUI::Form::hidden($session, {name=>"shop", value=>"address"})
                                .WebGUI::Form::hidden($session, {name=>"method", value=>"editAddress"})
                                .WebGUI::Form::hidden($session, {name=>"addressId", value=>$address->getId})
                                .$self->formatCallbackForm($form->get('callback'))
                                .WebGUI::Form::submit($session, {value=>$i18n->get("edit")})
                                .WebGUI::Form::formFooter($session),
            useButton       => WebGUI::Form::formHeader($session,{action=>$callback->{url}})
                                .$callbackForm
                                .WebGUI::Form::hidden($session, {name=>"addressId", value=>$address->getId})
                                .WebGUI::Form::submit($session, {value=>$i18n->get("use this address")})
                                .WebGUI::Form::formFooter($session),
            });
    }
    my %var = (
        addresses => \@addresses,
        addButton => WebGUI::Form::formHeader($session)
                    .WebGUI::Form::hidden($session, {name=>"shop", value=>"address"})
                    .WebGUI::Form::hidden($session, {name=>"method", value=>"editAddress"})
                    .$self->formatCallbackForm($form->get('callback'))
                    .WebGUI::Form::submit($session, {value=>$i18n->get("add a new address")})
                    .WebGUI::Form::formFooter($session),
        );
    my $template = WebGUI::Asset::Template->new($session, $session->setting->get("shopAddressBookTemplateId"));
    $template->prepare;
    return $session->style->userStyle($template->process(\%var));
}

1;

