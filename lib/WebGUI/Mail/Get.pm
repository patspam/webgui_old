package WebGUI::Mail::Get;

=head1 LEGAL

-------------------------------------------------------------------
WebGUI is Copyright 2001-2006 Plain Black Corporation.
-------------------------------------------------------------------
Please read the legal notices (docs/legal.txt) and the license
(docs/license.txt) that came with this distribution before using
this software.
-------------------------------------------------------------------
http://www.plainblack.com                     info@plainblack.com
-------------------------------------------------------------------

=cut

use strict;
use Net::POP3;
use MIME::Entity;
use MIME::Parser;
use LWP::MediaTypes qw(guess_media_type);
use WebGUI::Group;
use WebGUI::User;

=head1 NAME

Package WebGUI::Mail::Get

=head1 DESCRIPTION

This package is used for retrieving emails via POP3.

=head1 SYNOPSIS

use WebGUI::Mail::Get;


=head1 METHODS

These methods are available from this class:

=cut


#-------------------------------------------------------------------

=head2 connect ( session, params )

Constructor. Opens a connection to a POP3 server.

=head3 session

A reference to the current session.

=head3 params

A hash reference containing POP3 connection properties.

=head4 server

A scalar containing an IP address or host name of the server to connect to.

=head4 account

The account name to use to connect to this POP3 server.

=head4 password

The password to use to connect to this POP3 server.

=cut

sub connect {
	my $class = shift;
	my $session = shift;
	my $params = shift;
	my $pop = Net::POP3->new($params->{server}, Timeout => 60);
	unless (defined $pop) {
		$session->errorHandler->error("Couldn't connect to POP3 server ". $params->{server});
		return undef;
	}
	unless ($pop->login($params->{account}, $params->{password})) {
		$session->errorHandler->error("Couldn't log in to POP3 server ".$params->{server}." as ".$params->{account});
		return undef;
	}
	my $messageNumbers = $pop->list;
	my @ids = ();
	foreach my $key (keys %{$messageNumbers}) {
		push(@ids, $key);
	}
	bless {_pop=>$pop,  _session=>$session, _ids=>\@ids }, $class;
}

#-------------------------------------------------------------------

=head2 disconnect ( )

Disconnects from the POP3 server.

=cut

sub disconnect {
	my $self = shift;
	$self->{_pop}->quit;
}

#-------------------------------------------------------------------

=head2 getNextMessage ( )

Retrieves the next available message from the server. Returns undef if there are no more messages. Returns a hash reference containing the properties of the message. Here's an example:

 {
	to => 'John Doe <jon@example.com>, jane@example.com',
	from => 'sam@example.com',
	cc => 'joe@example.com',
	subject => 'This is my message subject',
	inReplyTo => 'some-message-id',
	messageId => 'some-message-id',
	date => 1144536119,
	parts => [
		{
			type=>'text/plain',
			content=>'Some body text goes here',
			filename => undef
		}, {
			type=>'image/png',
			content=>' ---- binary content here ---- ',
			filename => 'image.png'
		}, {
			type=>'application/msword',
			content=>' ---- binary content here ---- ',
			filename => undef
			alternative => [
				{
					type => 'text/html',
					content => '---- alternative content for msword doc here ---- ',
				},{
					type => 'text/plain',
					content => '---- even more alternative content for msword doc ---- ',
				}
			]
 		}
	]
}

=cut

sub getNextMessage {
	my $self = shift;
	my $id = pop(@{$self->{_ids}});
	return undef unless $id;
	my $rawMessage = $self->{_pop}->get($id);
	my $parser = MIME::Parser->new;
	$parser->output_to_core(1);
	my $parsedMessage = $parser->parse_data($rawMessage);
	if (defined $parsedMessage) {
		$self->{_pop}->delete($id);
	} else {
		$self->session->errorHandler->error("Could not parse POP3 message $id");
		return undef;
	}
	my $head = $parsedMessage->head;
        my $type = $head->get("Content-Type");
        my $alternate = 1 if lc $type =~ m{^multipart/alternative}; 
        # try to detect auto generated messages and drop them
        my $skipAuto = 0;
        my @headlines = split("\n",$head->stringify);
        foreach my $headline (@headlines) {
                $skipAuto = 1 if ($headline =~ m/^X-Auto/);
                $skipAuto = 1 if ($headline =~ m/^X-Mirror/);
        }
        my $returnPath = $head->get("Return-Path");
        chomp($returnPath);
        $skipAuto = 1 if ($returnPath eq "<>");        
        my $precedence = $head->get("Precedence");
        chomp($precedence);
        $skipAuto = 1 if ($precedence eq "bulk");
        $skipAuto = 1 if ($precedence eq "junk");
	$skipAuto = 1 if ($head->get("Content-Type") =~ m/multipart\/report/);
        $skipAuto = 1 if ($head->get("Content-Type") =~ m/report-type=.*delivery-status/);
	my $to = $head->get("To") || undef;
	chomp($to);
	my $from = $head->get("From") || undef;
	chomp($from);
	my $messageId = $head->get("Message-Id") || undef;
	chomp($messageId);
	if ($skipAuto) { # drop autogenerated messages
		$self->session->errorHandler->info("POP3: Dropped auto generated message ".$messageId." from ".$from." to ".$to);
		return $self->getNextMessage;
	}
	my $cc = $head->get("Cc") || undef;
	chomp($cc);
	my $subject = $head->get("Subject") || undef;
	chomp($subject);
	my $inReplyTo = $head->get("In-Reply-To") || $head->get("References") || undef; 
	chomp($inReplyTo);
	my %data = (
		to => $to,
		from => $from,
		cc => $cc,
		subject => $subject,
		inReplyTo => $inReplyTo,
		messageId => $messageId,
		"Return-Path" => $returnPath,
		date => $self->session->datetime->mailToEpoch($head->get("Date")),
		);
	my @segments = ();
	my @parts = $parsedMessage->parts;
	push(@parts, $parsedMessage) unless (@parts); # deal with the fact that there might be only one part
	# If this message has alternates, the last is the most canonical
	if ($alternate) {
		@parts = reverse @parts;
	}
	
	foreach my $part (@parts) {
		my $type = $part->mime_type;
		next if ($type eq "message/rfc822");
		next if ($type eq "message/delivery-status");
        	my $body = $part->bodyhandle;
		my $disposition = $part->head->get("Content-Disposition");
		$disposition =~ m/filename=\"(.*)\"/;
		my $filename = $1;
		my $content = "";
 		if (defined $body) {
			$content = $body->as_string;
		}
		next unless ($content);
		
		# If this is a multipart alternative message, and this is the first segment
		# Or if this is a normal mime message
		if (($alternate && !@segments) || !$alternate) {
			# Add the segment 
			push(@segments, {
				filename=>$filename,
				type=>$type,
				content=>$content
				});
		}
		# If this is a multipart alternative message, and this is not the first segment
		elsif ($alternate) {
			# Add an alternative to the last segment
			push @{$segments[-1]->{alternative}}, {
				type 		=> $type,
				content 	=> $content,
				};	 
		}
	}
	unless (scalar(@segments) > 0) { # drop empty messages
		$self->session->errorHandler->info("POP3: Dropped empty message ".$data{messageId}." from ".$data{from}." to ".$data{to});
		return $self->getNextMessage;
	}
	$data{parts} = \@segments;
        use Data::Dumper; $self->session->errorHandler->warn(Dumper \%data);
        return \%data;
}

#-------------------------------------------------------------------

=head2 session ( )

Returns a reference to the current session.

=cut

sub session {
	my $self = shift;
	return $self->{_session};
}

1;
