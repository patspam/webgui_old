package WebGUI::Shop::Credit;

use strict;
use Class::InsideOut qw{ :std };
use WebGUI::Shop::Admin;
use WebGUI::Exception::Shop;
use WebGUI::International;
use WebGUI::HTMLForm;
use WebGUI::User;

=head1 NAME

Package WebGUI::Shop::Credit

=head1 DESCRIPTION

Keeps track of what in-store credit is owed a customer. All refunds are issued as in-store credit.

=head1 SYNOPSIS

 use WebGUI::Shop::Credit;

 my $credit = WebGUI::Shop::Credit->new($session, $userId);

=head1 METHODS

These subroutines are available from this package:

=cut

readonly session => my %session;
readonly userId => my %userId;

#-------------------------------------------------------------------

=head2 adjust ( amount, [ comment ] )

Adjusts the amount of credit this user has by a specified amount.

=head3 amount

The amount to adjust the credit by.  A positive number adds credit, and a negative number removes credit.

=head3 comment

The reason for this adjustment. 

=cut

sub adjust {
    my ($self, $amount, $comment) = @_;
    $self->session->db->write("insert into shopCredit (creditId, userId, amount, comment, dateOfAdjustment) values (?,?,?,?,now())",
        [$self->session->id->generate, $self->userId, $amount, $comment]);
}

#-------------------------------------------------------------------

=head2 calculateDeduction ( amount )

Returns the amount that a user's in-store credit could reduce a sale. Useful in calculating checkout prices.

=head3 amount

The amount of the sale before in-store credit is applied.

=cut

sub calculateDeduction {
    my ($self, $amount) = @_;
    my $credit = $self->getSum;
    my $deduction = ($credit > $amount) ? $amount : $credit;
    $deduction *= -1;
    return sprintf("%.2f", $deduction);
}


#-------------------------------------------------------------------

=head2 getGeneralLedger ( session )

A class method. Returns a WebGUI::SQL::ResultSet containing the data from the shopCredit table for all users.

=head3 session

A reference to the current session.

=cut

sub getGeneralLedger {
    my ($class, $session) = @_;
    return $session->db->read("select * from shopCredit order by dateOfAdjustment");
}

#-------------------------------------------------------------------

=head2 getLedger ()

Returns a WebGUI::SQL::ResultSet containing the data from the shopCredit table for this user.

=cut

sub getLedger {
    my $self = shift;
    return $self->session->db->read("select * from shopCredit where userId=?",[$self->userId]);
}

#-------------------------------------------------------------------

=head2 getSum ()

Returns the amount of credit that is owed to this user.

=cut

sub getSum {
    my $self = shift;
    my $credit = $self->session->db->quickScalar("select sum(amount) from shopCredit where userId=?",[$self->userId]);
    return sprintf("%.2f", $credit);
}

#-------------------------------------------------------------------

=head2 new ( session, [ userId ] )

Constructor. 

=head3 session

A reference to the current session.

=head3 userId

A unique id for a user that you want to adjust the credit of. Defaults to the current user.

=cut

sub new {
    my ($class, $session, $userId) = @_;
    unless (defined $session && $session->isa("WebGUI::Session")) {
        WebGUI::Error::InvalidObject->throw(expected=>"WebGUI::Session", got=>(ref $session), error=>"Need a session.");
    }
    unless (defined $userId) {
        $userId = $session->user->userId;
    }
    my $self = register $class;
    my $id        = id $self;
    $session{ $id } = $session;
    $userId{ $id } = $userId;
    return $self;
}

#-------------------------------------------------------------------

=head2 session () 

Returns a reference to the current session.

=cut

#-------------------------------------------------------------------

=head2 userId () 

Returns a reference to the userId.

=cut



#-------------------------------------------------------------------

=head2 www_adjust

Adjust credit for a user.

=cut

sub www_adjust {
    my ($class, $session) = @_;
    my $admin = WebGUI::Shop::Admin->new($session);
    return $session->privilege->insufficient() unless $admin->canManage;
    my $form = $session->form;
    my $credit = $class->new($session, $form->get('userId'));
    $credit->adjust($form->get('amount'), $form->get('comment'));
    my $i18n = WebGUI::International->new($session, "Shop");
    my $message = sprintf $i18n->get('add credit message'), $form->get('amount'), WebGUI::User->new($session, $form->get('userId'))->username, $credit->getSum;
    return $class->www_manage($session, $message);
}

#-------------------------------------------------------------------

=head2 www_manage

Displays a credit management interface.

=cut

sub www_manage {
    my ($class, $session, $message) = @_;
    my $admin = WebGUI::Shop::Admin->new($session);
    return $session->privilege->insufficient() unless $admin->canManage;
    my $i18n = WebGUI::International->new($session, "Shop");
    my $f = WebGUI::HTMLForm->new($session);
    $f->hidden(name=>'shop',value=>'credit');
    $f->hidden(name=>'method',value=>'adjust');
    $f->user(
        name    => 'userId',
        label   => $i18n->get('username'),
        value   => $session->user->userId,
        );
    $f->float(
        name    => 'amount',
        label   => $i18n->get('amount'),
        );
    $f->text(
        name    => 'comment',
        label   => $i18n->get('notes'),
        );
    $f->submit;
    return $admin->getAdminConsole->render($message.$f->print, $i18n->get('in shop credit'));
}



1;
