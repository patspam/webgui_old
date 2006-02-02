package WebGUI::i18n::English::Asset_EventManagementSystem;

our $I18N = { ##hashref of hashes
	'display template' => { 
		message => q|Display Template|,
		lastUpdated => 1131394070, #seconds from the epoch
		context => q|Field label for template selector|
	},

	'display template description' => {
		message => q|Controls the layout, look, and appearence of an Event Management System.|,
		lastUpdated => 1131394072,
		context => q|Describes this template field selector|
	},

	'add/edit event template' => { 
		message => q|Event Template|,
		lastUpdated => 1131394070, #seconds from the epoch
		context => q|Field label for event template selector|
	},

	'add/edit event template description' => {
		message => q|Controls the layout, look, and appearence of an individual Event in the Event Management System.|,
		lastUpdated => 1131394072,
		context => q|Describes the event template field selector|
	},

	'paginate after' => {
		message => q|Paginate After|,
		lastUpdated => 1131394072,
		context => q|Field label for Paginate After|
	},

	'paginate after description' => {
		message => q|Number of events to display on one page.|,
		lastUpdated => 1131394072,
		context => q|Describes the Paginate After field|
	},

	'group to add events' => {
		message => q|Group to Add Events|,
		lastUpdated => 1131394072,
		context => q|Field label|
	},

	'group to add events description' => {
		message => q|Members of the selected group will have the ability to add events to an Event Management System.
		Events added will not be available for purchase until the event is approved by a member of the Group to Approve Events.|,
		lastUpdated => 1131394072,
		context => q|Describes the Group To Add Events field|
	},

	'add/edit event start date' => {
		message => q|Event Start Date|,
		lastUpdated => 1138837472,
		context => q|Event start date field label|
	},

	'add/edit event start date description' => {
		message => q|The time and date when the event starts.|,
		lastUpdated => 1131394072,
		context => q|hover help for Event Start Date field|
	},

	'add/edit event end date' => {
		message => q|Event End Date|,
		lastUpdated => 1138837472,
		context => q|Event end date field label|
	},

	'add/edit event end date description' => {
		message => q|The time and date when the event ends.|,
		lastUpdated => 1138837560,
		context => q|hover help for Event End Date field|
	},

	'group to approve events' => {
		message => q|Group to Approve Events|,
		lastUpdated => 1131394072,
		context => q|Field Label|
	},

	'group to approve events description' => {
		message => q|Members of the selected group will have the ability to approve a pending event so that it is available for purchase.|,
		lastUpdated => 1131394072,
		context => q|Describes the Group To Approve Events field|
	},

	'add/edit event title' => {
		message => q|Event Title|,
		lastUpdated => 1138312761,
	},

	'add/edit event title description' => {
		message => q|Enter the name or title of your event.|,
		lastUpdated => 1138312761,
	},

	'add/edit event description' => {
		message => q|Description|,
		lastUpdated => 1138312761,
	},

	'add/edit event description description' => {
		message => q|The details of your event, such as location, time, and what the event is about.|,
		lastUpdated => 1138312761,
	},

	'add/edit event price' => {
		message => q|Price|,
		lastUpdated => 1138312761,
	},

	'add/edit event price description' => {
		message => q|The cost to attend the event.|,
		lastUpdated => 1138312761,
	},

	'add/edit event maximum attendees' => {
		message => q|Maximum Attendees|,
		lastUpdated => 1138312761,
	},

	'add/edit event maximum attendees description' => {
		message => q|Based on room size, chairs, staffing and other requirements, the number of people who can attend the event.|,
		lastUpdated => 1138899055,
	},

	'global prerequisite' => {
		message => q|Global Prerequisites|,
		lastUpdated => 1138312761,
	},

	'global prerequisite description' => {
		message => q|When set to yes, you may assign events belonging to another instance of an Event Management System Asset as a prerequisite event for one of the events defined in this instance os the asset.  When set to no, only events defined within this instance of the asset may be used as prerequisites.|,
		lastUpdated => 1138312761,
	},

	'price must be greater than zero' => {
		message => q|Price must be greater than zero.|,
		lastUpdated => 1138312761,
		message => q|Error message for an illegal price.|,
	},


	#If the help file documents an Asset, it must include an assetName key
	#If the help file documents an Macro, it must include an macroName key
	#For all other types, use topicName
	'assetName' => {
		message => q|Event Management System|,
		lastUpdated => 1131394072,
	},

};

1;
