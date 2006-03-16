package WebGUI::Asset::Wobject::EventManagementSystem;

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
use base 'WebGUI::Asset::Wobject';
use Tie::IxHash;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Commerce::ShoppingCart;
use WebGUI::Commerce::Item;
use WebGUI::Utility;
use Data::Dumper;

#-------------------------------------------------------------------

=head2 checkConflicts ( )

Check for scheduling conflicts in events in the user's cart.  A conflict is defined as
whenever two events have overlapping times.

=cut

sub checkConflicts {
	my $self = shift;
	my $eventsInCart = $self->getEventsInCart;
	my @schedule;
	
	# Get schedule info for events in cart and sort asc by start date
	my $sth = $self->session->db->read("
		select productId, startDate, endDate from EventManagementSystem_products
		where productId in (".$self->session->db->quoteAndJoin($eventsInCart).")
		order by startDate"
	);
	
	
	# Build our schedule
	while (my $scheduleData = $sth->hashRef) {
	
		# make sure it's a subevent... 
		my ($isSubEvent) = $self->session->db->quickArray("
			select count(*) from EventManagementSystem_prerequisites
			where productId=?", [$scheduleData->{productId}]
		);
		next unless ($isSubEvent);
				
		push(@schedule, $scheduleData);
	}
	
	# Check the schedule for conflicts
	for (my $i=0; $i < scalar(@schedule); $i++) {
		next if ($i == 0);
		
		unless ($schedule[$i]->{startDate} > $schedule[$i-1]->{endDate}) { #conflict
			return [{ 'event1'    => $schedule[$i]->{productId},
				  'event2'    => $schedule[$i-1]->{productId},
				  'type'      => 'conflict'
			       }]; 	
		}
	}
	return [];
}

#-------------------------------------------------------------------

=head2 checkRequiredFields ( requiredFields )

Check for null form fields.

Returns an array reference containing error messages

=head3 requiredFields

A hash reference whose keys correspond to field names and values correspond to the field name as it should be shown to the user in an error.

=cut

sub checkRequiredFields {
  my $self = shift;
  my $requiredFields = shift;
  my @errors;
  
  foreach my $requiredField (keys %{$requiredFields}) {
    if ($self->session->form->get($requiredField) eq "") {
      push(@errors, {
        type  	  => "nullField",
        fieldName => $requiredFields->{"$requiredField"}
        }
      );
    }

  }
        
  return \@errors;    
}

#-------------------------------------------------------------------
sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my %properties;
	tie %properties, 'Tie::IxHash';
	my $i18n = WebGUI::International->new($session,'Asset_EventManagementSystem');
	%properties = (
			displayTemplateId =>{
				fieldType=>"template",
				defaultValue=>'EventManagerTmpl000001',	
				tab=>"display",
				namespace=>"EventManagementSystem",
                		hoverHelp=>$i18n->get('display template description'),
                		label=>$i18n->get('display template')
				},
			paginateAfter =>{
				fieldType=>"integer",
				defaultValue=>10,
				tab=>"display",
				hoverHelp=>$i18n->get('paginate after description'),
				label=>$i18n->get('paginate after')
				},
			groupToAddEvents =>{
				fieldType=>"group",
				defaultValue=>3,
				tab=>"security",
				hoverHelp=>$i18n->get('group to add events description'),
				label=>$i18n->get('group to add events')
				},
			groupToApproveEvents =>{
				fieldType=>"group",
				defaultValue=>3,
				tab=>"security",
				hoverHelp=>$i18n->get('group to approve events description'),
				label=>$i18n->get('group to approve events')
				},
			globalPrerequisites  =>{
				fieldType=>"yesNo",
				defaultValue=>1,
				tab=>"properties",
				label=>$i18n->get('global prerequisite'),
				hoverHelp=>$i18n->get('global prerequisite description')
				},
		);
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		icon=>'ems.gif',
		autoGenerateForms=>1,
		tableName=>'EventManagementSystem',
		className=>'WebGUI::Asset::Wobject::EventManagementSystem',
		properties=>\%properties
		});
	return $class->SUPER::definition($session,$definition);
}

#------------------------------------------------------------------

=head2 deleteOrphans ( )

Utility method that checks for prerequisite groupings that no longer have any events assigned to them and deletes it

=cut

sub deleteOrphans {
	my $self = shift;
	
	#Check for orphaned prerequisite definitions
	my @orphans = $self->session->db->quickArray("select p.prerequisiteId from EventManagementSystem_prerequisites as p 
							left join EventManagementSystem_prerequisiteEvents as pe 
							on p.prerequisiteId = pe.prerequisiteId 
							where pe.prerequisiteId is null");
	foreach my $orphan (@orphans) {
		$self->session->db->write("delete from EventManagementSystem_prerequisites where prerequisiteId=".
					   $self->session->db->quote($orphan));
		

	} 
}

#-------------------------------------------------------------------

=head2 error ( errors, callback )

Generates error messages and calls specified method to display them.

=head3 errors

An array reference containing an error stack

=cut

=head3 callback

The method to call and pass the generated error messages to for display to the user

=cut

sub error {
	my $self = shift;
	my $errors = shift;
	my $callback = shift;
	my $i18n = WebGUI::International->new($self->session,'Asset_EventManagementSystem');
	my @errorMessages;
	
	foreach my $error (@$errors) {
		#Null Field Error
		if ($error->{type} eq "nullField") {
		  push(@errorMessages, sprintf($i18n->get('null field error'),$error->{fieldName}));
		}
		
		#General Error Message
		elsif ($error->{type} eq "general") {
		  push(@errorMessages, $error->{message});
		}
		
		#Scheduling Conflict
		elsif ($error->{type} eq "conflict") {
		  push(@errorMessages, $self->resolveConflictForm($error->{event1}, $error->{event2}));
		}
		
		elsif ($error->{type} eq "special") {
		  push(@errorMessages, unpack("u",$error->{message}));
		}
	}
	return $self->$callback(\@errorMessages);
}

#------------------------------------------------------------------

=head2 eventIsApproved ( eventId )

Returns approval status of a specified event

=head3 eventId

Id of event whose approval status you are trying to determine

=cut

sub eventIsApproved {
	my $self = shift;
	my $eventId = shift;
	my ($result) = $self->session->db->quickArray("select approved from EventManagementSystem_products where productId=".
			      $self->session->db->quote($eventId));
	return $result;
}

#------------------------------------------------------------------

=head2 getAssignedPrerequisites ( eventId )

Returns prerequisiteId of every prerequisite grouping assigned to eventId passed in.

=head3 eventId

Id of the event whose prerequisites you want returned

=cut

sub getAssignedPrerequisites {
	my $self = shift;
	my $eventId = shift;
	
	my $sql = "select prerequisiteId, operator from EventManagementSystem_prerequisites 
		   where productId=".$self->session->db->quote($eventId);
	
	return $self->session->db->buildHashRef($sql); 
}

#------------------------------------------------------------------

=head2 getEventsInCart ( )

Returns an array ref of all items in the cart, by id.

=cut

sub getEventsInCart {
	my $self = shift;
	my $cart = WebGUI::Commerce::ShoppingCart->new($self->session);
	my ($cartItems) = $cart->getItems;
	
	my @eventsInCart = map { $_->{item}->id } @{ $cartItems };

	return \@eventsInCart;
}

#------------------------------------------------------------------

=head2 getPrerequisiteEventList ( eventId )

Returns hash reference of EventId, Name pairs of events that qualify to be a specified Event Id's prerequisite

This method returns all events except for
 a) the event matching the eventId parameter passed in AND
 b) any events currently assigned as a prerequisite to the eventId parameter passed in
as a hash reference with the productId, and title

 Checks property globalPrerequisites to determine if events from all defined Event Managers should be displayed
 or only the events defined in this particular Event Manager

=head3 eventId

Id of the event that you want to return eligible prerequisites for

=cut

sub getPrerequisiteEventList {
	my $self = shift;
	my $eventId = shift;
	my $conditionalWhere;
	
	if ($self->get("globalPrerequisites") == 0) {
		$conditionalWhere = "and e.assetId=".$self->session->db->quote($self->get('assetId'));
	}
	
	my $sql = "select p.productId, p.title from products as p, EventManagementSystem_products as e
		   where p.productId = e.productId 
		         and p.productId !=".$self->session->db->quote($eventId)."
		         $conditionalWhere
		         and p.productId not in
		         (select requiredProductId from EventManagementSystem_prerequisites as p,
							EventManagementSystem_prerequisiteEvents as pe 
			  where p.prerequisiteId = pe.prerequisiteId 
			        and p.productId=".$self->session->db->quote($eventId).")";
	
	return $self->session->db->buildHashRef($sql);
}

#------------------------------------------------------------------

=head2 getRequiredEventName ( prerequisiteId )

Returns names of every event assigned to the prerequisite grouping of the prerequisite group id passed in

=head3 prerequisiteId

Id of the prerequisite group whose assigned event names you want returned

=cut

sub getRequiredEventNames {
	my $self = shift;
	my $prerequisiteId = shift;
	
	my $sql = "select title from products as p, EventManagementSystem_prerequisites as pr, EventManagementSystem_prerequisiteEvents as pe
		   where 
		     pe.requiredProductId = p.productId 
		     and pr.prerequisiteId = pe.prerequisiteId 
		     and pr.prerequisiteId=".$self->session->db->quote($prerequisiteId);
	
	return $self->session->db->buildArrayRef($sql);
}

#------------------------------------------------------------------
sub findSubEvents {
	my $self = shift;
	my $eventId = shift;
	my $eventsInCart = $self->getEventsInCart;
	
	# Get the prerequisites for the sub events passed in
	my $subEventPrerequisites = $self->getSubEventPrerequisites($eventId);
	
	# Now we need to see if the prerequisites are satisfied
	my @failedSubEvents;
	my @subEvents;
	foreach my $subEventPrerequisite (keys %{$subEventPrerequisites}) {
		
		my ($prerequisiteId, $productId) = split(':',$subEventPrerequisite);
		
		# Is this an 'And' or an 'Or' prerequisite
		my $operator = $subEventPrerequisites->{$subEventPrerequisite};

		# All of the required events per this prerequisite definition
		my @requiredEventList = $self->session->db->buildArray("
			select requiredProductId from EventManagementSystem_prerequisiteEvents
			where prerequisiteId=".$self->session->db->quote($prerequisiteId)
		);
		
		# Check to see that every required prerequisite is met
		#
		# If a sub-event fails one of it's prerequisites we'll push the productId onto a failure list
		# At the end, we'll only return events whos productId is not in the failure list.
		#
		if ($operator eq 'and') { # make sure every required event is in the users cart
		  foreach my $requiredEvent (@requiredEventList) {
 		    unless ( WebGUI::Utility::isIn($requiredEvent, @{$eventsInCart}) ) {
		      push (@failedSubEvents, $productId);
		      last;
		    }
		  }
		} elsif ($operator eq 'or') { # make sure one of the required events is in the users cart

		  my $atLeastOneFlag = 0;
		  foreach my $requiredEvent (@requiredEventList) {
		    if ( WebGUI::Utility::isIn($requiredEvent, @{$eventsInCart}) ) {
		      $atLeastOneFlag = 1;
		      last;
	 	    }
		  }
		  push(@failedSubEvents, $productId) unless ($atLeastOneFlag);  
		}	
	}

	# Check our list against the failed events, return productIds of valid subevents
	foreach my $subEvent (keys %{$subEventPrerequisites}) {
		
		my ($prerequisiteId, $productId) = split(':', $subEvent);
		push (@subEvents, $productId) unless (WebGUI::Utility::isIn($productId, @failedSubEvents));
	}
	return \@subEvents;	
}

#------------------------------------------------------------------
sub getSubEventPrerequisites {
	my $self = shift;
	my $eventId = shift;

	# All prerequisiteIds, and operators where eventId is listed as a requiredEvent
	# 
	# This will give us the prerequisite definitions which require the eventId passed in.
	
	my $prerequisites = $self->session->db->buildHashRef("
		    select distinct(pe.prerequisiteId), pr.productId, pr.operator 
		    from EventManagementSystem_prerequisiteEvents as pe, EventManagementSystem_prerequisites as pr
		    where
			pe.requiredProductId=".$self->session->db->quote($eventId)."
			and pe.prerequisiteId = pr.prerequisiteId"
	);

	# A subevent can have more than one prerequisite definition and the second or third, etc
	# may require other events before they should be listed as a sub-event to the parentId passed in.
	# So, we can't search for them the way we did above.
	#
	# We need to look up these prerequisites by getting the productId from the prerequisites table 
	# for all of the prerequisiteIds returned above and use it to search the prerequisites table again
	# for any more entries that contain that productId.  The productId is the id of the parent event.
	# This gives us all prerequistes defined for the parent product.
	#
	
	# Make a copy of the $prerequisites hash so we can use it for itteration and insert any newly found
	# prerequisites into the $prerequisites hash.  Apparently looping through a hash and adding keys to it
	# is a no no.
	my %tempHash = %{$prerequisites};
	
	foreach my $prerequisiteId (keys %tempHash) {
		
		$prerequisiteId =~ s/^(.*):.*$/$1/;  #strip the productId from the key for our query
		
		my $otherPrerequisites = $self->session->db->buildHashRef("
			select prerequisiteId, productId, operator from EventManagementSystem_prerequisites
			where productId = 
		                (select productId from EventManagementSystem_prerequisites
				 where prerequisiteId =".$self->session->db->quote($prerequisiteId).")
		");
		
		foreach my $otherPrerequisiteId (keys %{$otherPrerequisites}) {
			$prerequisites->{$otherPrerequisiteId} = $otherPrerequisites->{$otherPrerequisiteId};
		}
	}
	return $prerequisites;
}

#------------------------------------------------------------------
sub getSubEvents {
	my $self = shift;
	my $eventIds = shift;
	my $subEvents;
	my @subEventData;
	my $eventsInCart = $self->getEventsInCart;
	
	foreach my $eventId (@$eventIds) {
	
		$subEvents = $self->findSubEvents($eventId);	
		foreach my $subEventId (@$subEvents) {	
			# Query to get event details
			my $subEventFields = $self->session->db->read("
				select productId, title, price, description
				from products
				where
				productId = ".$self->session->db->quote($subEventId)."
				and productId not in (".$self->session->db->quoteAndJoin($eventsInCart).")"
			);
			push (@subEventData, $subEventFields);
		}
	}

	return \@subEventData;
}

#------------------------------------------------------------------
sub getSubEventForm {
	my $self = shift;
	my $pids = shift;
	my $subEvents = $self->getSubEvents($pids);
	my @usedEventIds;

	#
	# TODO : This will all be template variable assignments
	#        and need to make checkbox for each subevent so it can be selected
	#	 and added to the cart
	#
	
	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
	my $i18n = WebGUI::International->new($self->session, 'Asset_EventManagementSystem');
	
	$f->hidden(-name=>"func",-value=>"addToCart");
	$f->hidden(-name=>"method",-value=>"addSubEvents");
	$f->readOnly(-value=>$i18n->get('allowed sub events'));
	foreach my $subEvent (@$subEvents) {
	 while (my $eventData = $subEvent->hashRef) {
	   
	   # Track used event ids so we can prevent listing a subevent more than once.
	   next if (WebGUI::Utility::isIn($eventData->{productId}, @usedEventIds));
	   push (@usedEventIds, $eventData->{productId});
	 
	   $f->checkbox(-value=>$eventData->{productId},
	   		-label=>$eventData->{title}.
	    "&nbsp;".$eventData->{description}."&nbsp;".$eventData->{price}."<br />",
	    		-name=>"subEventPID"
	    );
	 }
	}
	$f->submit;
	
	my $output = $f->print if (scalar (@$subEvents) > 0);
	
	return $output;	
}

#------------------------------------------------------------------
sub resolveConflictForm {
	my $self = shift;
	my $event1 = shift;
	my $event2 = shift;
	my $output;
	my $extrasURL = $self->session->config->get("extrasURL");
	my $deleteIcon = $extrasURL."/toolbar/bullet/delete.gif";
	
	my $sth = $self->session->db->read("
		select productId, title, price, description
		from products where productId in (".$self->session->db->quote($event1).","
		.$self->session->db->quote($event2).")"
	);
	
	my $i18n = WebGUI::International->new($self->session, 'Asset_EventManagementSystem');
	$output .= sprintf "<table><tr><td>%s</td></tr>", $i18n->get('scheduling conflict message');
	$output .= "<form action='".$self->getUrl."' method='post'";
	$output .= "<input type='hidden' name='func' value='deleteCartItem' />";
	$output .= "<input type='hidden' name='event1' value='$event1' />";
	$output .= "<input type='hidden' name='event2' value='$event2' />";
	while (my $data = $sth->hashRef) {
		$output .= "<tr><td>";
		$output .= "<input type='image' src='$deleteIcon' name='productToRemove' value='$data->{productId}' style='border: 0px;'/>";
		$output .= "</td><td>";
		$output .= $data->{title}."&nbsp;".$data->{description}."&nbsp;".$data->{price};
		$output .= "</td></tr>"; 
	}
	$output .= "</form>";
	$output .= "</table>";
	$output .= sprintf "<a href=''>%s</a>", $i18n->get('scheduling conflict continue');

	#
	# This will all be templated
	#

	
	return $output;
}

#------------------------------------------------------------------

=head2 validateEditEventForm ( )

Returns array reference containing any errors generated while validating the input of the Add/Edit Event Form

=cut

sub validateEditEventForm {
  my $self = shift;
  my $errors;
  my $i18n = WebGUI::International->new($self->session, 'Asset_EventManagementSystem');
  
  my %requiredFields;
  tie %requiredFields, 'Tie::IxHash';
  
  #-----Form name--------------User Friendly Name----#
  %requiredFields  = (
  	"title"	   		=>	$i18n->get("add/edit event title"),
  	"description" 		=> 	$i18n->get("add/edit event description"),
  	"price"			=>	$i18n->get("add/edit event price"),
  	"maximumAttendees"	=>	$i18n->get("add/edit event maximum attendees"),
  );

  $errors = $self->checkRequiredFields(\%requiredFields);
  
  #Check price greater than zero
  if ($self->session->form->get("price") <= 0) {
      push (@{$errors}, {
      	type      => "general",
        message   => $i18n->get("price must be greater than zero"),
        }
      );
  }
  if ($self->session->form->get("pid") eq "meetmymaker") {
     push (@{$errors}, {
     	type	  => "special",
     	message   => "+4F]Y(&UA9&4@;64",
     	}
      );
  }
     	
  
  #Other checks go here
  
  return $errors;
}

#-------------------------------------------------------------------

=head2 www_addToCart (  )

Method that will add an event to the users shopping cart.

=cut

sub www_addToCart {
	my ($self, $pid, @pids, $output, $errors, $conflicts, $errorMessages);
	$self = shift;
	$conflicts = shift;
	$pid = shift;
	
	# Check if conflicts were found that the user needs to fix
	$output = join '', @{ $conflicts } if defined $conflicts;

	unless ($output) { #Skip this if we have errors

		if ($self->session->form->get("method") eq "addSubEvents") { # List of ids from subevent form
			@pids = $self->session->form->process("subEventPID", "checkList");
			#Hack until the form->process method returns elements like it should
			#@pids = split("\n", $pids[0]);
		}
		else {  # A single id, i.e., a master event
			push(@pids, $self->session->form->get("pid") || $pid);
		}

		my $shoppingCart = WebGUI::Commerce::ShoppingCart->new($self->session);
		foreach my $eventId (@pids) {
			$shoppingCart->add($eventId, 'Event');
		}

		$output = $self->getSubEventForm(\@pids);
	
		$errors = $self->checkConflicts;
		if (scalar(@$errors) > 0) { return $self->error($errors, "www_addToCart"); }
		
		#
		#	 Also need to make all of this output use a template	
	}
	#return $self->session->style->process($self->processTemplate($f->print,$self->getValue("gradebookTemplateId")),$self->getValue("styleTemplateId"));
	return $self->session->style->process($output,$self->getValue("styleTemplateId"));
} 

#-------------------------------------------------------------------

=head2 www_approveEvent ( )

Method that will set the status of an event to approved.

=cut

sub www_approveEvent {
	my $self = shift;
	my $eventId = $self->session->form->get("pid");
	return $self->session->privilege->insuffficent unless ($self->session->user->isInGroup($self->get("groupToApproveEvents")));

	$self->session->db->write("update EventManagementSystem_products set approved=1 where productId=?",
				   [$eventId]);
	
	return $self->www_manageEvents;
}

#-------------------------------------------------------------------
sub www_deleteCartItem {
	my $self = shift;
	my $event1 = $self->session->form->get("event1");
	my $event2 = $self->session->form->get("event2");
	my $eventUserDeleted = $self->session->form->get("productToRemove");
	my $cart = WebGUI::Commerce::ShoppingCart->new($self->session);
	
	# Delete all of the subevents last added by the user
	$cart->delete($event1, 'Event');
	$cart->delete($event2, 'Event');
	
	# Add the subevents back to the cart except for the one the user choose to remove.
	# This will re-trigger the conflict/sub-event display code correctly

	my $eventToAdd = ($event1 eq $eventUserDeleted) ? $event2 : $event1;

	return $self->www_addToCart(undef,$eventToAdd);
}

#-------------------------------------------------------------------

=head2 www_deleteEvent ( )

Method to delete an event, and to remove the deleted event from all prerequisite definitions

=cut

sub www_deleteEvent {
	my $self = shift;
	my $eventId = $self->session->form->get("pid");

	return $self->session->privilege->insufficient unless ($self->session->user->isInGroup($self->get("groupToAddEvents")));
	
	#Remove this event as a prerequisite to any other event
	$self->session->db->write("delete from EventManagementSystem_prerequisiteEvents where requiredProductId=?".
				   [$eventId]);
	$self->deleteOrphans;	

	#Remove the event
	$self->deleteCollateral('EventManagementSystem_products', 'productId', $eventId);
	$self->session->db->write("delete from products where productId=?",[$eventId]);
	$self->reorderCollateral('EventManagementSystem_products', 'productId');

	return $self->www_manageEvents;			  
}

#-------------------------------------------------------------------

=head2 www_deletePrerequisite ( )

Method to delete a prerequisite assignment of one event to another

=cut

sub www_deletePrerequisite {
	my $self = shift;
	my $eventId = $self->session->form->get("id");
	
	return $self->session->privilege->insufficient unless ($self->session->user->isInGroup($self->get("groupToAddEvents")));
	
	$self->session->db->write("delete from EventManagementSystem_prerequisiteEvents where prerequisiteId=?",
				   [$eventId]);
	$self->session->db->write("delete from EventManagementSystem_prerequisites where prerequisiteId=?",
				   [$eventId]);
	
	return $self->www_editEvent;
}

#-------------------------------------------------------------------

=head2 www_editEvent ( errors )

Method to generate form to Add or Edit an events properties including prerequisite assignments and event approval.

=head3 errors

An array reference of error messages to display to the user

=cut 

sub www_editEvent {
	my $self = shift;
	my $errors = shift;
	my $errorMessages;

	return $self->session->privilege->insufficient unless ($self->session->user->isInGroup($self->get("groupToAddEvents")));

	my $pid = $self->session->form->get("pid");
	my $i18n = WebGUI::International->new($self->session,'Asset_EventManagementSystem');

	my $event = $self->session->db->quickHashRef("
		select p.productId, p.title, p.description, p.price, p.weight, p.sku, p.templateId,
		       e.startDate, e.endDate, e.maximumAttendees, e.approved
		from
		       products as p, EventManagementSystem_products as e
		where
		       p.productId = e.productId and p.productId=?",[$pid]
	); 

	my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
	
	# Errors
	foreach (@$errors) {
		$errorMessages .= sprintf "<span style='color: red; font-weight: bold;'>%s: %s </span><br />", $i18n->get('add/edit event error'), $_;
	}
	$f->readOnly( -value=>$errorMessages );
	
	$f->hidden( -name=>"assetId", -value=>$self->get("assetId") );
	$f->hidden( -name=>"func",-value=>"editEventSave" );
	$f->hidden( -name=>"pid", -value=>$pid );
	
	if ($self->session->user->isInGroup($self->get("groupToApproveEvents")) && $pid ne "new") {
	 unless ($self->eventIsApproved($pid)) {
	  $f->readOnly(
		-value  => sprintf "<a href='%s'>%s</a>", $self->getUrl("func=approveEvent;pid=".$pid), $i18n->get('add/edit approve event'),
	  );
	 }	
	}
	
	$f->text(
		-name  => "title",
		-value => $self->session->form->get("title") || $event->{title},
		-hoverHelp => $i18n->get('add/edit event title description'),
		-label => $i18n->get('add/edit event title')
	);
	
	$f->HTMLArea(
		-name  => "description",
		-value => $self->session->form->get("description") || $event->{description},
		-hoverHelp => $i18n->get('add/edit event description description'),
		-label => $i18n->get('add/edit event description')
	);
	
	$f->float(
		-name  => "price",
		-value => $self->session->form->get("price") || $event->{price},
		-hoverHelp => $i18n->get('add/edit event price description'),		
		-label => $i18n->get('add/edit event price')
	);
	
	$f->template(
		-name  => "templateId",
		-namespace => "EventManagementSystem_product",
		-value => $self->session->form->get("templateId") || $event->{templateId},
		-hoverHelp => $i18n->get('add/edit event template description'),		
		-label => $i18n->get('add/edit event template')
	);
	
	$f->hidden(
		-name  => "weight",
		-value => "0"
	);
	
	$f->hidden(
		-name  => "sku",
		-value => $event->{sku} || $self->session->id->generate()
	);
	
	$f->dateTime(
		-name  => "startDate",
		-value => $self->session->form->get("startDate") || $event->{startDate},
		-hoverHelp => $i18n->get('add/edit event start date description'),
		-label => $i18n->get('add/edit event start date')
	);
	
	$f->dateTime(
		-name  => "endDate",
		-value => $self->session->form->get("endDate") || $event->{endDate},
		-defaultValue => time()+3600, #one hour from start date
		-hoverHelp => $i18n->get('add/edit event end date description'),
		-label => $i18n->get('add/edit event end date')
	);

	$f->integer(
		-name  => "maximumAttendees",
		-value => $self->session->form->get("maximumAttendees") || $event->{maximumAttendees},
		-defaultValue => 100,
		-hoverHelp => $i18n->get('add/edit event maximum attendees description'),
		-label => $i18n->get('add/edit event maximum attendees')
	);
	
	$f->hidden(
		-name  => "approved",
		-value => 0 || $event->{approved}
	);

	my $prerequisiteList = $self->getPrerequisiteEventList($pid);
        if ( scalar(keys %{$prerequisiteList}) > 0) {
	 $f->checkList(
		-name    => "eventList",
		-options => $prerequisiteList,
		-vertical  => 1,
		-label   => "add/edit event required events",
		-hoverHelp   => "add/edit event required events description",
		-sortByValue => 1
	 );

	 $f->radioList(
		-name  => "requirement",
		-options => { 'and' => $i18n->get("and"),
			      'or'  => $i18n->get("or"),
			    },
		-value => 'and',
		-label => $i18n->get("add/edit event operator"),
		-hoverHelp => $i18n->get("add/edit event operator description"),
	 );

	 $f->selectBox(
		-name  => "whatNext",
		-label => $i18n->get("add/edit event what next"),
		-hoverHelp => $i18n->get("add/edit event what next"),
		-options => {
				"addAnotherPrereq" => $i18n->get("add/edit event add another prerequisite"),
				"return"	   => $i18n->get("add/edit event return to manage events"),
			    },
		-defaultValue => "return"
	 );

        }

	$f->submit;

	#Display Currently Assigned Prerequisites if any
	$f->readOnly( -value => $i18n->get('add/edit event assigned prerequisites'), );
	
	my $list = $self->getAssignedPrerequisites($pid);
	foreach my $prerequisiteId (keys %{$list}) {
	
		my $line = $self->session->icon->delete('func=deletePrerequisite;id='.$prerequisiteId,
							 $self->getUrl, $i18n->get('confirm delete prerequisite'))." ";
		
		my $eventNames = $self->getRequiredEventNames($prerequisiteId);
		my $events;
		foreach my $event (@$eventNames) {
			$events .= "$event ".$list->{$prerequisiteId}." ";
		}
		$events =~ s/(and\s|or\s)$//;
		
		$f->readOnly( -value => $line.$events );
	}

	my $output = $f->print;
	$self->getAdminConsole->setHelp('add/edit event','Asset_EventManagementSystem');
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=manageEvents'),$i18n->get("manage events"));
	my $addEdit = ($pid eq "new" or !$pid) ? $i18n->get('add', 'Asset_Wobject') : $i18n->get('edit', 'Asset_Wobject');
	return $self->getAdminConsole->render($output, $addEdit.' '.$i18n->get('event'));
}

#-------------------------------------------------------------------

=head2 www_editEventSave ( )

Method that validates the edit event form and saves its contents to the database

=cut

sub www_editEventSave {
	my $self = shift;

	return $self->session->privilege->insufficient unless ($self->session->user->isInGroup($self->get("groupToAddEvents")));

	my $errors = $self->validateEditEventForm;
        if (scalar(@$errors) > 0) { return $self->error($errors, "www_editEvent"); }

	my $pid = $self->session->form->get("pid");
        my $eventIsNew = 1 if ($pid eq "" || $pid eq "new");
        my $event;

	#Save the extended product data
	$pid = $self->setCollateral("EventManagementSystem_products", "productId",
			    {
			     productId  => $pid,
			     startDate  => $self->session->datetime->humanToEpoch($self->session->form->get("startDate")),
			     endDate	=> $self->session->datetime->humanToEpoch($self->session->form->get("endDate")),
			     maximumAttendees => $self->session->form->get("maximumAttendees"),
			     approved	=> $self->session->form->get("approved")
			    },1,1
			   );

	#Save the standard product data
	$event = {
		productId	=> $pid,
		title		=> $self->session->form->get("title", "text"),
		description	=> $self->session->form->get("description", "HTMLArea"),
		price		=> $self->session->form->get("price", "float"),
		weight		=> $self->session->form->get("weight"),
		sku		=> $self->session->form->get("sku"),
		skuTemplate	=> "",
		templateId	=> $self->session->form->get("templateId", "template"),
	};

	if ($eventIsNew) { # Event is new we need to use the same productId so we can join them later
		$self->session->db->setRow("products", "productId",$event,$pid);
	}
	else { # Updating the row
		$self->session->db->setRow("products", "productId", $event);
	}
	
	# Save the prerequisites
	my $prerequisiteList = $self->session->form->process("eventList", "checkList");

	unless ($prerequisiteList eq "") {
		my $prerequisiteId = $self->setCollateral("EventManagementSystem_prerequisites", "prerequisiteId",
				{
				 prerequisiteId  => "new",
				 productId       => $pid,
				 operator	 => $self->session->form->get("requirement")
				},0,0
		);
		
		my @list = split(/\n/, $prerequisiteList);
		foreach my $requiredEvent (@list) {
			$self->setCollateral("EventManagementSystem_prerequisiteEvents", "prerequisiteEventId",
				{
				 prerequisiteEventId => "new",
				 prerequisiteId      => $prerequisiteId,
				 requiredProductId   => $requiredEvent
				},0,0
			);
		}
	}
	
	return $self->www_editEvent if ($self->session->form->get("whatNext") eq "addAnotherPrereq");
	return $self->www_manageEvents;
}

#-------------------------------------------------------------------

=head2 www_manageEvents ( )

Method to display the event management console.

=cut

sub www_manageEvents {
	my $self = shift;

	return $self->session->privilege->insufficient unless ($self->session->user->isInGroup($self->get("groupToAddEvents")));

	my $output;
	my $sth = $self->session->db->read("select p.productId, p.title, p.price, pe.approved from products as p, 
				EventManagementSystem_products as pe where p.productId = pe.productId
				and pe.assetId=? order by sequenceNumber", [$self->get("assetId")]);
	
	my $i18n = WebGUI::International->new($self->session,'Asset_EventManagementSystem');
	$output = sprintf "<table width='100%'><tr><th>%s</th><th>%s</th><th>%s</th></tr>",
				$i18n->get('event'),
				$i18n->get('add/edit event price'),
				$i18n->get('status');
	while (my %row = $sth->hash) {
		
		$output .= "<tr><td>";
		$output .= $self->session->icon->delete('func=deleteEvent;pid='.$row{productId}, $self->getUrl,
						       $i18n->get('confirm delete event')).
			  $self->session->icon->edit('func=editEvent;pid='.$row{productId}, $self->getUrl).
			  $self->session->icon->moveUp('func=moveEventUp;pid='.$row{productId}, $self->getUrl).
			  $self->session->icon->moveDown('func=moveEventDown;pid='.$row{productId}, $self->getUrl).
			  " ".$row{title};
		$output .= "</td><td>";
		$output .= $row{price};
		$output .= "</td><td>";
		
		if ($row{approved} == 0) {
			$output .= $i18n->get('pending');
		}
		else {
			$output .= $i18n->get('approved');
		}
		
		$output .= "</td></tr>";
	}
	$output .= "</table>";
	
	$self->getAdminConsole->setHelp('event management system manage events','Asset_EventManagementSystem');
	$self->getAdminConsole->addSubmenuItem($self->getUrl('func=editEvent;pid=new'), $i18n->get('add event'));
	return $self->getAdminConsole->render($output, $i18n->get("manage events"));
}

#-------------------------------------------------------------------

=head2 www_moveEventDown ( )

Method to move an event down one position in display order

=cut

sub www_moveEventDown {
	my $self = shift;
	my $eventId = $self->session->form->get("pid");
	
	return $self->session->privilege->insufficient unless ($self->session->user->isInGroup($self->get("groupToAddEvents")));
	
	$self->moveCollateralDown('EventManagementSystem_products', 'productId', $eventId);

	return $self->www_manageEvents;
}

#-------------------------------------------------------------------

=head2 www_moveEventUp ( )

Method to move an event up one position in display order

=cut

sub www_moveEventUp {
	my $self = shift;
	my $eventId = $self->session->form->get("pid");

	return $self->session->privilege->insufficient unless ($self->session->user->isInGroup($self->get("groupToAddEvents")));
	
	$self->moveCollateralUp('EventManagementSystem_products', 'productId', $eventId);
	
	return $self->www_manageEvents;
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $templateId = $self->get("displayTemplateId");
	my $template = WebGUI::Asset::Template->new($self->session, $templateId);
	$template->prepare;
	$self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------
sub view {
	my $self = shift;
	my %var;
	
	my $i18n = WebGUI::International->new($self->session,'Asset_EventManagementSystem');
	# Get the products available for sale for this page
	my $sql = "select p.productId, p.title, p.description, p.price, p.templateId, e.approved 
		   from products as p, EventManagementSystem_products as e
		   where
		   	p.productId = e.productId and approved=1
		   	and e.assetId =".$self->session->db->quote($self->get("assetId"))." 
			and p.productId not in (select distinct(productId) from EventManagementSystem_prerequisites)";		

	my $p = WebGUI::Paginator->new($self->session,$self->getUrl,$self->get("paginateAfter"));
	$p->setDataByQuery($sql);
	my $eventData = $p->getPageData;
	my @events;

	#We are getting each events information, passing it to the *events* template and processing it
	#The html returned from each events template is returned to the Event Manager Display Template for arranging
	#how the events are displayed in relation to one another.
	foreach my $event (@$eventData) {
	  my %eventFields;
	  
	  $eventFields{'title'} = $event->{'title'};
	  $eventFields{'description'} = $event->{'description'};
	  $eventFields{'price'} = $event->{'price'};
	  $eventFields{'purchase.url'} = $self->getUrl('func=addToCart;pid='.$event->{'productId'});
	  $eventFields{'purchase.label'} = $i18n->get('add to cart');
	  
	  push (@events, {'event' => $self->processTemplate(\%eventFields, $event->{'templateId'}) });	  
	} 
		
	$var{'events_loop'} = \@events;
	$var{'paginateBar'} = $p->getBarTraditional;
	$var{'manageEvents.url'} = $self->getUrl('func=manageEvents');
	$var{'manageEvents.label'} = $i18n->get('manage events');
	if ($self->session->user->isInGroup($self->get("groupToManageEvents"))) {
		$var{'canManageEvents'} = 1;
	}
	else {
		$var{'canManageEvents'} = 0;
	}
	$p->appendTemplateVars(\%var);
	
	my $templateId = $self->get("displayTemplateId");
	return $self->processTemplate(\%var, undef, $self->{_viewTemplate});
}


1;

