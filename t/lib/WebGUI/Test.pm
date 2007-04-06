package WebGUI::Test;

use strict;
use warnings;

our ( $SESSION, $WEBGUI_ROOT, $CONFIG_FILE, $WEBGUI_LIB, $WEBGUI_TEST_COLLATERAL );

use Config     qw[];
use IO::Handle qw[];
use File::Spec qw[];
use Test::MockObject::Extends;

our $logger_warns;
our $logger_debug;
our $logger_info;
our $logger_error;

BEGIN {

    STDERR->autoflush(1);

    $CONFIG_FILE = $ENV{ WEBGUI_CONFIG };

    unless ( defined $CONFIG_FILE ) {
        warn qq/Enviroment variable WEBGUI_CONFIG must be set.\n/;
        exit(1);
    }
   
    unless ( $CONFIG_FILE ) {
        warn qq/Enviroment variable WEBGUI_CONFIG must not be empty.\n/;
        exit(1);
    }

    unless ( -e $CONFIG_FILE ) {
        warn qq/WEBGUI_CONFIG path '$CONFIG_FILE' does not exist.\n/;
        exit(1);
    }

    unless ( -f _ ) {
        warn qq/WEBGUI_CONFIG path '$CONFIG_FILE' is not a file.\n/;
        exit(1);
    }

    unless ( -r _ ) {
        warn qq/WEBGUI_CONFIG path '$CONFIG_FILE' is not readable by effective uid '$>'.\n/;
        exit(1);
    }

    $WEBGUI_ROOT = $CONFIG_FILE;
    
    # convert to absolute path
    unless ( File::Spec->file_name_is_absolute($WEBGUI_ROOT) ) {
        $WEBGUI_ROOT = File::Spec->rel2abs($WEBGUI_ROOT);
    }

    $CONFIG_FILE = ( File::Spec->splitpath( $WEBGUI_ROOT ) )[2];
    $WEBGUI_ROOT = substr( $WEBGUI_ROOT, 0, index( $WEBGUI_ROOT, File::Spec->catdir( 'etc', $CONFIG_FILE ) ) );
    $WEBGUI_ROOT = File::Spec->canonpath($WEBGUI_ROOT);
    $WEBGUI_TEST_COLLATERAL = File::Spec->catdir($WEBGUI_ROOT, 't', 'supporting_collateral');

    $WEBGUI_LIB  ||= File::Spec->catpath( (File::Spec->splitpath($WEBGUI_ROOT))[0], $WEBGUI_ROOT, 'lib' );

    push (@INC,$WEBGUI_LIB);

    # http://thread.gmane.org/gmane.comp.apache.apreq/3378
    # http://article.gmane.org/gmane.comp.apache.apreq/3388
    if ( $^O eq 'darwin' && $Config::Config{osvers} lt '8.0.0' ) {

        require Class::Null;
        require IO::File;

        unshift @INC, sub {
            return undef unless $_[1] =~ m/^Apache2|APR/;
            return IO::File->new( $INC{'Class/Null.pm'}, &IO::File::O_RDONLY );
        };

        no strict 'refs';

        *Apache2::Const::OK        = sub {   0 };
        *Apache2::Const::DECLINED  = sub {  -1 };
        *Apache2::Const::NOT_FOUND = sub { 404 };
    }

    unless ( eval "require WebGUI::Session;" ) {
        warn qq/Failed to require package 'WebGUI::Session'. Reason: '$@'.\n/;
        exit(1);
    }

    $SESSION = WebGUI::Session->open( $WEBGUI_ROOT, $CONFIG_FILE );

    my $logger = $SESSION->errorHandler->getLogger;
    $logger = Test::MockObject::Extends->new( $logger );

    $logger->mock( 'warn',  sub { $WebGUI::Test::logger_warns = $_[1]} );
    $logger->mock( 'debug', sub { $WebGUI::Test::logger_debug = $_[1]} );
    $logger->mock( 'info',  sub { $WebGUI::Test::logger_info  = $_[1]} );
    $logger->mock( 'error', sub { $WebGUI::Test::logger_error = $_[1]} );
}

END {
    $SESSION->close if defined $SESSION;
}

sub file {
    return $CONFIG_FILE;
}

sub config {
    return undef unless defined $SESSION;
    return $SESSION->config;
}

sub lib {
    return $WEBGUI_LIB;
}

sub session {
    return $SESSION;
}

sub root {
    return $WEBGUI_ROOT;
}

sub getTestCollateralPath {
    return $WEBGUI_TEST_COLLATERAL;
}

1;
