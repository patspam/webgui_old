#!/usr/bin/env perl

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------


our $webguiRoot;

BEGIN {
        $webguiRoot = "..";
        unshift (@INC, $webguiRoot."/lib");
}

use strict;
use CPAN;
use Getopt::Long;
use Pod::Usage;
use Cwd ();


my ($os, $prereq, $dbi, $dbDrivers, $simpleReport, $help);

GetOptions(
	'simpleReport'=>\$simpleReport,
	'help'=>\$help
);

pod2usage( verbose => 2 ) if $help;

print "\nWebGUI is checking your system environment:\n\n";

$prereq = 1;

printTest("Operating System");
printResult(getOs());

printTest("WebGUI Root");
printResult($webguiRoot);


###################################
# Checking Perl
###################################

printTest("Perl Interpreter");
if ($] >= 5.008) {
	printResult("OK");
} else {
	failAndExit("Please upgrade to 5.8 or later! Cannot continue without Perl 5.8 or higher.");
}

##Doing this as a global is not nice, but it works
my $missingModule = 0;

checkModule("LWP",                          5.80         );
checkModule("HTTP::Request",                1.40         );
checkModule("HTTP::Headers",                1.61         );
checkModule("Test::More",                   0.61,      1 );
checkModule("Test::MockObject",             1.02,      1 );
checkModule("Test::Deep",                   0.095,     1 );
checkModule("Test::Exception",              0.27,      1 );
checkModule("Test::Class",                  0.30,      1 );
checkModule("Pod::Coverage",                0.17,      2 );
checkModule("Text::Balanced",               1.95,      1 );
checkModule("Digest::MD5",                  2.20         );
checkModule("DBI",                          1.40         );
checkModule("DBD::mysql",                   3.0002       );
checkModule("HTML::Parser",                 3.36         );
checkModule("Archive::Tar",                 1.05         );
checkModule("Archive::Zip",                 1.16         );
checkModule("IO::Zlib",                     1.01         );
checkModule("Compress::Zlib",               1.34         );
checkModule("Net::SMTP",                    2.24         );
checkModule("MIME::Tools",                  5.419        );
checkModule("Net::POP3",                    2.28         );
checkModule("Tie::IxHash",                  1.21         );
checkModule("Tie::CPHash",                  1.001        );
checkModule("XML::Simple",                  2.09         );
checkModule("DateTime",                     0.2901       );
checkModule("Time::HiRes",                  1.38         );
checkModule("DateTime::Format::Strptime",   1.0601       );
checkModule("DateTime::Format::Mail",       0.2901       );
checkModule("Image::Magick",                "6.0"        );
checkModule("Log::Log4perl",                0.51         );
checkModule("Net::LDAP",                    0.25         );
checkModule("HTML::Highlight",              0.20         );
checkModule("HTML::TagFilter",              0.07         );
checkModule("HTML::Template",               2.9          );
checkModule("HTML::Template::Expr",         0.05,      2 );
checkModule("XML::FeedPP",                  0.40         );
checkModule("JSON",                         2.04         );
checkModule("Config::JSON",                 "1.1.2"      );
checkModule("Text::CSV_XS",                 "0.52"       );
checkModule("Net::Subnets",                 0.21         );
checkModule("Finance::Quote",               1.08         );
checkModule("POE",                          0.3202       );
checkModule("POE::Component::IKC::Server",  0.18         );
checkModule("POE::Component::Client::HTTP", 0.77         );
checkModule("Data::Structure::Util",        0.11         );
checkModule("Apache2::Request",             2.06         );
checkModule("URI::Escape",                  "3.28"       );
checkModule("POSIX"                                      );
checkModule("List::Util"                                 );
checkModule("Color::Calc"                                );
checkModule("Text::Aspell",                 0.01,2       );
checkModule("Weather::Com::Finder",         "0.5.1"      );
checkModule("Class::InsideOut",             "1.06"       );
checkModule("HTML::TagCloud",               "0.34"       );
checkModule("Image::ExifTool",              "7.00"       );
checkModule("Archive::Any",                 "0.093"      );
checkModule("Path::Class",                  '0.16'       );
checkModule("Exception::Class",             "1.23"       );
checkModule("List::MoreUtils",              "0.22"       );
checkModule("File::Path",                   "2.04"       );
checkModule("Module::Find",                 "0.06"       );
checkModule("Class::C3",                    "0.19"       );
checkModule("Params::Validate",             "0.81"       );
checkModule("Clone",                        "0.31"       );
checkModule('HTML::Packer',                 "0.4"        );
checkModule('JavaScript::Packer',           '0.02'       );
checkModule('CSS::Packer',                  '0.2'        );
checkModule('Business::Tax::VAT::Validation', '0.20'     );
checkModule('Crypt::SSLeay',                '0.57'       );

failAndExit("Required modules are missing, running no more checks.") if $missingModule;

###################################
# Checking WebGUI
###################################

printTest("WebGUI modules");
if (eval { require WebGUI } && eval { require WebGUI::SQL } && eval { require WebGUI::Config }) {
        printResult("OK");
} else {
        failAndExit("Not Found. Perhaps you're running this script from the wrong place.");
}

###################################
# Checking Version
###################################
my $version = getLatestWebguiVersion();
printTest("Your version");
if ($version eq $WebGUI::VERSION."-".$WebGUI::STATUS) {
	printResult("You are using the latest version - $WebGUI::VERSION-$WebGUI::STATUS");
} else {
	printResult("You are using ".$WebGUI::VERSION."-".$WebGUI::STATUS." and ".$version." is available.");
}

printTest("Locating WebGUI configs");
my $configs = WebGUI::Config->readAllConfigs($webguiRoot);
printResult("OK");
foreach my $filename (keys %{$configs}) {
	print "\n";	
	###################################
	# Checking Config File
	###################################
	printTest("Checking config file");
	printResult($filename);

	###################################
	# Checking uploads folder
	###################################
	printTest("Verifying uploads folder");
        if (opendir(DIR,$configs->{$filename}->get("uploadsPath"))) {
		printResult("OK");
		closedir(DIR);
	} else {
		printResult("Appears to be missing!");
	}
	printTest("Verifying DSN");
	my $dsnok = 0;
	if ($configs->{$filename}->get("dsn") !~ /\DBI\:\w+\:\w+/) {
		printResult("DSN is improperly formatted.");
	} else {
		printResult("OK");
		$dsnok = 1;
	}

	###################################
	# Checking database
	###################################
	if ($dsnok) {
		printTest("Verifying database connection");
		my ($dbh, $test);
		unless (eval {$dbh = DBI->connect($configs->{$filename}->get("dsn"),$configs->{$filename}->get("dbuser"),$configs->{$filename}->get("dbpass"))}) {
			printResult("Can't connect with info provided!");
		} else {
			printResult("OK");
			$dbh->disconnect();
		}
	}
}



print "\nTesting complete!\n\n";



#----------------------------------------
sub checkModule {
    my $module = shift;
    my $version = shift || 0;
    my $skipInstall = shift;
    my $afterinstall = shift;	
    unless (defined $afterinstall) { $afterinstall = 0; }
    printTest("Checking for module $module");
    my $statement = "require ".$module.";";

    # we tried installing, now what?
    if ($afterinstall == 1) {
        failAndExit("Install of $module failed!") unless eval($statement);
        # //todo: maybe need to check new install module version 
		printResult("OK");
		return;
    } 

    # let's see if the module is installed
    elsif (eval($statement)) {
		$statement = '$'.$module."::VERSION";
		my $currentVersion = eval($statement);

        # is it the correct version
		if ($currentVersion >= $version) {
			printResult("OK");
	    } 

        # not the correct version, now what?
        else {

            # do nothing we're just reporting the modules.
		    if ($simpleReport) {
                printResult("Outdated - Current: ".$currentVersion." / Required: ".$version);
            }

            # do nothing, this module isn't required 
	        elsif ( $skipInstall == 2 ) {
                printResult("Outdated - Current: ".$currentVersion." / Required: ".$version.", but it's optional anyway");
            } 

            # if we're an admin let's offer to install it
            elsif (isRootRequirementMet()) {
                my $installThisModule = prompt ("$currentVersion is installed, but we need at least "
                    ."$version, do you want to upgrade it now?", "y", "y", "n");

                # does the user wish to install it
                if ($installThisModule eq "y") {
                    installModule($module);
                    checkModule($module,$version,$skipInstall,1);
                } 

                # user doesn't wish to install it
                else {
                    printResult("Upgrade aborted by user input.");
                }
            } 

            # we're not root so lets skip it
            else {
                printResult("Outdated - Current: ".$currentVersion." / Required: ".$version
                    .", but you're not root, so you need to ask your administrator to upgrade it.");
		    }
        }

    # module isn't installed, now what?
    } else {

        # skip optional module
        if ($skipInstall == 2) {
            printResult("Not Installed, but it's optional anyway");
		} 

        # skip  
        elsif ($simpleReport) {
           	printResult("Not Installed");
            $missingModule = 1;
		}

        # if we're root lets try and install it
		elsif (  isRootRequirementMet()) {
            my $installThisModule = prompt ("Not installed, do you want to install it now?", "y", "y", "n");

            # user wishes to upgrade
            if ($installThisModule eq "y") {
                installModule($module);
                checkModule($module,$version,$skipInstall,1);
            } 

            # install aborted by user
            else {
                printResult("Install aborted by user input.");
                $missingModule = 1;
            }
		} 

        # can't install, not root        
        else {
			printResult("Not installed, but you're not root, so you need to ask your administrator to install it.");
            $missingModule = 1;
		}
    }
}

#----------------------------------------
sub failAndExit {
        my $exitmessage = shift;
        print $exitmessage."\n\n";
        exit;
}

#----------------------------------------
sub getLatestWebguiVersion {
    printTest("Getting current WebGUI version");
    my $currentversionUserAgent = new LWP::UserAgent;
	$currentversionUserAgent->env_proxy;
	$currentversionUserAgent->agent("WebGUI-Check/2.1");
    $currentversionUserAgent->timeout(30);
    $currentversionUserAgent->env_proxy();
    my $header = new HTTP::Headers;
    my $referer = "http://".`hostname`."/webgui-cli-version";
    chomp $referer;
    $header->referer($referer);
    my $currentversionRequest = new HTTP::Request (GET => "http://update.webgui.org/latest-version.txt", $header);
    my $currentversionResponse = $currentversionUserAgent->request($currentversionRequest);
    my $version = $currentversionResponse->content;
    chomp $version;
    if ($currentversionResponse->is_error || $version eq "") {
        printResult("Failed! Continuing without it.");
    } 
    else {
        printResult("OK");
    }
    return $version;
}

#----------------------------------------
sub getOs {
	if ($^O =~ /MSWin32/i || $^O =~ /^Win/i) {
		return "Windowsish";
	}
	return "Linuxish";
}

#----------------------------------------
sub installModule {
        my $module = shift;
        print "Attempting to install ".$module."...\n";
        my $cwd = Cwd::cwd;
        CPAN::Shell->install($module);
        chdir $cwd;
}

#----------------------------------------
sub isIn {
        my $key = shift;
        $_ eq $key and return 1 for @_;
        return 0;
}

#----------------------------------------
sub isRootRequirementMet {
    if (getOs() eq "Linuxish")	 {
	return ($< == 0);	
    } else {
	return 1;
    }
}

#----------------------------------------
sub printTest {
        my $test = shift;
        print sprintf("%-50s", $test.": ");
}

#----------------------------------------
sub printResult {
        my $result = shift;
        print "$result\n";
}

#----------------------------------------
sub prompt {
        my $question = shift;
        my $default = shift;
        my @answers = @_; # the rest are answers
        print "\n".$question." ";
        print "{".join("|",@answers)."} " if ($#answers > 0);
        print "[".$default."] " if (defined $default);
        my $answer = <STDIN>;
        chomp $answer;
        $answer = $default if ($answer eq "");
        $answer = prompt($question,$default,@answers) if (($#answers > 0 && !(isIn($answer,@answers))) || $answer eq "");
        return $answer;
}

__END__

=head1 NAME

testEnvironment - Test Perl environment for proper WebGUI support.

=head1 SYNOPSIS

 testEnvironment --simpleReport

 testEnvironment --help

=head1 DESCRIPTION

This WebGUI utility script tests the current Perl environment to make
sure all of WebGUI's dependencies are satisfied. It also checks for
proper installation of WebGUI's libraries.

If any of the required Perl modules is not available or outdated, the
script will ask if it should attempt installation using CPAN. This will
only be possible if the script is being run as a superuser.

The script will attempt to find out the latest available version from
L<http://update.webgui.org>, and compare with the currently installed one.

=over

=item B<--simpleReport>

Prints the status report to standard output, but does not attempt
to upgrade any outdated or missing Perl modules.

=item B<--help>

Shows this documentation, then exits.

=back

=head1 AUTHOR

Copyright 2001-2009 Plain Black Corporation.

=cut
