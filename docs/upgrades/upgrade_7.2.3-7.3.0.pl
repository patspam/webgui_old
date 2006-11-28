#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use lib "../../lib";
use strict;
use Getopt::Long;
use WebGUI::Session;


my $toVersion = "7.3.0"; # make this match what version you're going to
my $quiet; # this line required


my $session = start(); # this line required
addWikiAssets($session);
deleteOldFiles($session);
addFileFieldsToDataForm($session);
finish($session); # this line required

#-------------------------------------------------
sub addFileFieldsToDataForm {
	my $session = shift;
	print "\tAdding File Field Types to the Data Form Wobject\n" unless $quiet;
	$session->db->write("alter table DataForm add column (mailAttachments int(11) default 0)");
}

#-------------------------------------------------
sub deleteOldFiles {
	my $session = shift;
	print "\tDeleting old unneeded files.\n" unless $quiet;
	unlink "../../www/extras/assets/wiki.gif";
	unlink "../../www/extras/assets/wikiPost.gif";
	unlink "../../www/extras/assets/small/wiki.gif";
	unlink "../../www/extras/assets/small/wikiPost.gif";
}

#-------------------------------------------------
sub addWikiAssets {
	my $session = shift;
	print "\tAdding wiki assets.\n" unless $quiet;

	$session->db->write($_) for(<<'EOT',
  CREATE TABLE `WikiMaster` (
    `assetId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `revisionDate` bigint(20) NOT NULL,
    `groupToEditPages` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `groupToAdminister` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `richEditor` varchar(22) character set utf8 collate utf8_bin NOT NULL
                 default 'PBrichedit000000000002',
    `frontPageTemplateId` varchar(22) character set utf8 collate utf8_bin NOT NULL
                          default 'WikiFrontTmpl000000001',
    `pageTemplateId` varchar(22) character set utf8 collate utf8_bin NOT NULL
                     default 'WikiPageTmpl0000000001',
    `pageEditTemplateId` varchar(22) character set utf8 collate utf8_bin NOT NULL
                         default 'WikiPageEditTmpl000001',
    `recentChangesTemplateId` varchar(22) character set utf8 collate utf8_bin NOT NULL
                              default 'WikiRCTmpl000000000001',
    `pageHistoryTemplateId` varchar(22) character set utf8 collate utf8_bin NOT NULL
                            default 'WikiPHTmpl000000000001',
    `searchTemplateId` varchar(22) character set utf8 collate utf8_bin NOT NULL
                       default 'WikiSearchTmpl00000001',
    `recentChangesCount` int(11) NOT NULL default 50,
    `recentChangesCountFront` int(11) NOT NULL default 10,
    `thumbnailSize` int(11) NOT NULL default 0,
    `maxImageSize` int(11) NOT NULL default 0,
	`approvalWorkflow` varchar(22) binary not null default 'pbworkflow000000000003',
    PRIMARY KEY (`assetId`, `revisionDate`)
  ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
EOT
				    <<'EOT',
  CREATE TABLE `WikiPage` (
    `assetId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `revisionDate` bigint(20) NOT NULL,
    `content` mediumtext,
    `storageId` varchar(22) character set utf8 collate utf8_bin NULL,
    `views` bigint(20) NOT NULL default 0,
    PRIMARY KEY (`assetId`, `revisionDate`)
  ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
EOT
				    <<'EOT',
  CREATE TABLE `WikiMaster_titleIndex` (
    `assetId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `pageId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `title` varchar(255) NOT NULL,
    PRIMARY KEY (`assetId`, `pageId`)
  ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
EOT
				    # Don't want protection to be versioned, so put it in a
				    # separate table.
				    <<'EOT',
  CREATE TABLE `WikiPage_protected` (
    `assetId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    PRIMARY KEY (`assetId`)
  ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
EOT
				    <<'EOT',
  CREATE TABLE `WikiPage_extraHistory` (
    `assetId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `userId` varchar(22) character set utf8 collate utf8_bin NOT NULL,
    `dateStamp` bigint(20) NOT NULL,
    `actionTaken` varchar(255) NOT NULL,
    `url` varchar(255) NOT NULL,
    `title` varchar(255) NOT NULL
  ) ENGINE=MyISAM DEFAULT CHARSET=utf8;
EOT
				   );

	$session->config->addToArray('assets', 'WebGUI::Asset::Wobject::WikiMaster');
}

# ---- DO NOT EDIT BELOW THIS LINE ----

#-------------------------------------------------
sub start {
	my $configFile;
	$|=1; #disable output buffering
	GetOptions(
    		'configFile=s'=>\$configFile,
        	'quiet'=>\$quiet
	);
	my $session = WebGUI::Session->open("../..",$configFile);
	$session->user({userId=>3});
	my $versionTag = WebGUI::VersionTag->getWorking($session);
	$versionTag->set({name=>"Upgrade to ".$toVersion});
	$session->db->write("insert into webguiVersion values (".$session->db->quote($toVersion).",'upgrade',".$session->datetime->time().")");
	updateTemplates($session);
	return $session;
}

#-------------------------------------------------
sub finish {
	my $session = shift;
	my $versionTag = WebGUI::VersionTag->getWorking($session);
	$versionTag->commit;
	$session->close();
}

#-------------------------------------------------
sub updateTemplates {
	my $session = shift;
	return undef unless (-d "templates-".$toVersion);
        print "\tUpdating templates.\n" unless ($quiet);
	opendir(DIR,"templates-".$toVersion);
	my @files = readdir(DIR);
	closedir(DIR);
	my $importNode = WebGUI::Asset->getImportNode($session);
	my $newFolder = undef;
	foreach my $file (@files) {
		next unless ($file =~ /\.tmpl$/);
		open(FILE,"<templates-".$toVersion."/".$file);
		my $first = 1;
		my $create = 0;
		my $head = 0;
		my %properties = (className=>"WebGUI::Asset::Template");
		while (my $line = <FILE>) {
			if ($first) {
				$line =~ m/^\#(.*)$/;
				$properties{id} = $1;
				$first = 0;
			} elsif ($line =~ m/^\#create$/) {
				$create = 1;
			} elsif ($line =~ m/^\#(.*):(.*)$/) {
				$properties{$1} = $2;
			} elsif ($line =~ m/^~~~$/) {
				$head = 1;
			} elsif ($head) {
				$properties{headBlock} .= $line;
			} else {
				$properties{template} .= $line;	
			}
		}
		close(FILE);
		if ($create) {
			$newFolder = createNewTemplatesFolder($importNode) unless (defined $newFolder);
			my $template = $newFolder->addChild(\%properties, $properties{id});
		} else {
			my $template = WebGUI::Asset->new($session,$properties{id}, "WebGUI::Asset::Template");
			if (defined $template) {
				my $newRevision = $template->addRevision(\%properties);
			}
		}
	}
}

#-------------------------------------------------
sub createNewTemplatesFolder {
	my $importNode = shift;
	my $newFolder = $importNode->addChild({
		className=>"WebGUI::Asset::Wobject::Folder",
		title => $toVersion." New Templates",
		menuTitle => $toVersion." New Templates",
		url=> $toVersion."_new_templates",
		groupIdView=>"12"
		});
	return $newFolder;
}



