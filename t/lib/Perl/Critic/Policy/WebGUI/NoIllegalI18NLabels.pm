package Perl::Critic::Policy::WebGUI::NoIllegalI18NLabels;

use strict;
use warnings;
use Readonly;
use FindBin;

use WebGUI::Test;
use WebGUI::International;

use Perl::Critic::Utils qw{ :all };
use base 'Perl::Critic::Policy';

=head1 Perl::Critic::Policy::WebGUI::NoIllegalI18NLabels

Scan WebGUI modules for i18n calls and make sure that each call has a
corresponding i18n table entry.  It will not check i18n calls that have
variables for either the namespace or the label to look up.

Running this policy from the command line requires setting up some
environmental variables to that it can get a proper WebGUI session,
and access the test library.

env WEBGUI_CONFIG=/data/WebGUI/etc/my.conf PERL5LIB=/data/WebGUI/t/lib perlcritic -single-policy NoIllegalI18N

=head2 TODO

=over 4

=item +

Handle inline calls like International->new('','')->get('','');
like in Form/Asset.pm, line 107.

=item +

Handle scoping, like in Content/Setup.pm and other places.

=back

=cut

our $VERSION = '0.2';

Readonly::Scalar my $DESC => q{i18n calls that do not have corresponding i18n table entries};

sub supported_parameters { return ()                   }
 
sub default_severity     { return $SEVERITY_LOWEST     }

sub default_themes       { return 'WebGUI'             }

sub applies_to           { return qw/PPI::Token::Word/ }

##Set up a cache of i18n objects.  Later this will be extended to handle scoping,
##probably by having a pointer

sub initialize_if_enabled {
    my ($self, $config) = @_;
    $self->{_i18n_objects} = {};
    my $session = WebGUI::Test->session;
    $self->{i18n} = WebGUI::International->new($session);
    return $TRUE;
}

=head2 violates

Gets called on every block, and then scans it for i18n object creations
and corresponding calls.  It will then check each call to make sure
that the i18n entry that is being requested exists.

For now, do the check without handling nested scopes.  For nested scopes, I need
to find a way to detect the nesting (does PPI have a parent check?) and then
push a scope onto the object for later reference.

=cut

sub violates {
    my ($self, $elem, undef) = @_;
    ##$elem has stringification overloaded by default.
    return unless $elem eq 'new'
               or $elem eq 'get'
               or $elem eq 'setNamespace';
    return if !is_method_call($elem);
    if ($elem eq 'new') {  ##Object creation,  check for class.
        my $operator = $elem->sprevious_sibling     or return;
        my $class    = $operator->sprevious_sibling or return;
        return unless $class eq 'WebGUI::International';

        my $symbol_name = _get_symbol_name($class);
        return unless $symbol_name;

        ##It's an i18n object, see if a default namespace was passed in.
        my $arg_list = $elem->snext_sibling;
        return unless ref $arg_list eq 'PPI::Structure::List'; 
        my @arguments = _get_args($arg_list);
        my $namespace;
        if ($arguments[1]) {
            $namespace = $arguments[1]->[0]->string;
        }
        else {
            $namespace = 'WebGUI';
        }
        $self->{_i18n_objects}->{$symbol_name} = $namespace;
        return;
    }
    elsif ($elem eq 'get') {  ##i18n fetch?  Check symbol
        my $symbol_name = _get_symbol_name($elem);
        return unless $symbol_name && exists $self->{_i18n_objects}->{$symbol_name};
        my $arg_list = $elem->snext_sibling;
        return unless ref $arg_list eq 'PPI::Structure::List'; 
        my @arguments = _get_args($arg_list);
        use Data::Dumper;
        print Dumper \@arguments;
        ##First argument should be a quote, and there shouldn't be any operators when
        ##constructing arguments for the get call.
        return if exists $arguments[0]->[1] and $arguments[0]->[1]->isa('PPI::Token::Operator');
        return unless $arguments[0]->[0]->isa('PPI::Token::Quote');
        my $label = $arguments[0]->[0]->string;
        my $namespace = $self->{_i18n_objects}->{$symbol_name};
        if ($arguments[1]) {
            $namespace = $arguments[1]->[0]->string;
        }
        print "object    : $symbol_name\n";
        print "label     : $label\n";
        print "namespace : $namespace\n";
        if (! $self->{i18n}->get($label, $namespace)) {
            return $self->violation(
                $DESC,
                sprintf('label=%s, namespace=%s', $label, $namespace),
                $elem
            );
        }
        return;
    }
    elsif ($elem eq 'setNamespace') {  ##Set the object's default namespace
        my $symbol_name = _get_symbol_name($elem);
        return unless $symbol_name && exists $self->{_i18n_objects}->{$symbol_name};
        my $arg_list = $elem->snext_sibling;
        return unless ref $arg_list eq 'PPI::Structure::List'; 
        my @arguments = _get_args($arg_list);
        ##Many assumptions being made here
        return unless $arguments[0]->[0]->isa('PPI::Token::Quote');
        my $new_namespace = $arguments[0]->[0]->string;
        $self->{_i18n_objects}->{$symbol_name} = $new_namespace;
        return;
    }
    return;
}

sub _get_args {
    my ($list) = @_;
    ##Borrowed from Subroutines/ProhibitManyArgs
    my @inner = $list->schildren;
    if (1 == @inner and $inner[0]->isa('PPI::Statement::Expression')) {
        @inner = $inner[0]->schildren;
    }
    my @arguments = split_nodes_on_comma(@inner);
    return @arguments;
}

sub _get_symbol_name {
    my ($class) = @_;

    my $assignment = $class->sprevious_sibling  or return;
    my $symbol     = $assignment->sprevious_sibling or return;
    return unless ref($symbol) eq 'PPI::Token::Symbol';
    my $symbol_name = $symbol.'';  ##Is there a better way to stringify?
    return $symbol_name;
}

1;
