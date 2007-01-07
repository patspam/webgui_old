#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
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


print "\nWebGUI is checking your system environment:\n\n";

my ($os, $prereq, $dbi, $dbDrivers, $simpleReport, $help);

GetOptions(
	'simpleReport'=>\$simpleReport,
	'help'=>\$help
);

if ($help){
        print <<STOP;


Usage: perl $0 

Options:
	
   --help         Display this help message and exit.
   --simpleReport Print a status report to stdout and do not upgrade any perl modules


STOP
        exit;
}

$prereq = 1;

printTest("Operating System");
printResult(getOs());

printTest("WebGUI Root");
printResult($webguiRoot);


###################################
# Checking Perl
###################################

printTest("Perl Interpreter");
if ($] >= 5.006) {
	printResult("OK");
} else {
	failAndExit("Please upgrade to 5.6 or later! Cannot continue without Perl 5.6 or higher.");
}


checkModule("LWP",5.80);
checkModule("HTTP::Request",1.40);
checkModule("HTTP::Headers",1.61);
checkModule("Digest::MD5",2.20);
checkModule("DBI",1.40);
checkModule("DBD::mysql",2.1021);
checkModule("HTML::Parser",3.36);
checkModule("Archive::Tar",1.05);
checkModule("IO::Zlib",1.01);
checkModule("Compress::Zlib",1.34);
checkModule("Net::SMTP",2.24);
checkModule("Tie::IxHash",1.21);
checkModule("Tie::CPHash",1.001);
checkModule("XML::Simple",2.09);
checkModule("SOAP::Lite",0.60);
checkModule("Time::HiRes",1.38);
checkModule("Image::Magick",5.47,1);
checkModule("Log::Log4perl",0.51);
checkModule("Net::LDAP",0.25);
checkModule("Date::Manip",5.42);
checkModule("HTML::Highlight",0.20);
checkModule("HTML::TagFilter",0.07);
checkModule("HTML::Template",2.7);
checkModule("Parse::PlainConfig",1.1);
checkModule("XML::RSSLite",0.11);


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
	printResult("OK");
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

        if ($afterinstall == 1) {
                failAndExit("Install of $module failed!") unless eval($statement);
                # //todo: maybe need to check new install module version 
		printResult("OK");
		return;
	    
        } elsif (eval($statement)) {
		$statement = '$'.$module."::VERSION";
		my $currentVersion = eval($statement);
		if ($currentVersion >= $version) {
			printResult("OK");
		} else {
                	printResult("Outdated - Current: ".$currentVersion." / Required: ".$version);
			return if $simpleReport;
			if ( isRootRequirementMet()) {
                		my $installThisModule = prompt ("The perl module $module is outdated, do you want to upgrade it now?", "y", "y", "n");
                		if ($installThisModule eq "y") {
                        		installModule($module);
                        		checkModule($module,$version,$skipInstall,1);
                		} else {
                        #		failAndExit("Aborting test due to user input!");
                		}
			} else {
				failAndExit("Aborting test, not all modules available, and you're not root so I can't install them.");
			}
}
        } else {
		if ($skipInstall == 2) {
			printResult("Not Installed, but it's optional anyway");
		} else {
                	printResult("Not Installed");
		}
		return if $simpleReport;
		if (  isRootRequirementMet()) {
                	my $installThisModule = prompt ("The perl module $module is not installed, do you want to install it now?", "y", "y", "n");
                	if ($installThisModule eq "y") {
                        	installModule($module);
                        	checkModule($module,$version,$skipInstall,1);
                	} else {
#                        	failAndExit("Aborting test due to user input!");
                	}
		} else {
			failAndExit("Aborting test, not all modules available, and you're not root so I can't install them.");
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
        } else {
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
        CPAN::Shell->install($module);
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
        print sprintf("%-45s", $test.": ");
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



