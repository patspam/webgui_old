package WebGUI::i18n::English::Macros;

our $I18N = {

	'macro name' => {
		message => q|Macro Name|,
		lastUpdated => 1112591288
	},

	'macro shortcut' => {
		message => q|Macro Shortcut|,
		lastUpdated => 1112591289
	},

	'macros list title' => {
		message => q|Macros, List of Available|,
        	lastUpdated => 1112395935,
	},

	'macros list body' => {
                message => q|<p>The set of available Macros is defined in the WebGUI configuration file.  These Macros are available for use on your site:</p>
|,
		context => 'Content for dynamically generated macro list',
		lastUpdated => 1114134745,
	},

	'macro enabled' => {
		message => q|This macro is enabled in the WebGUI configuration file and can be used on this site.|,
		lastUpdated => 1046656837,
	},

	'macro disabled' => {
		message => q|This macro is not enabled in the WebGUI configuration file and cannot be used on this site.|,
		lastUpdated => 1046656837,
	},

	'macros using title' => {
		message => q|Macros, Using|,
		lastUpdated => 1046656837
	},

	'macros using body' => {
		message => q|<p>WebGUI macros are used to create dynamic content within otherwise static content. For instance, you may wish to show which user is logged in on every page, or you may wish to have a dynamically built menu or crumb trail. 
</p>

<p>Macros always begin with a caret (&#94;) and follow with at least one other character and ended with a semicolon (;). Some macros can be extended/configured by taking the format of <b>&#94;x</b>("<i>config text</i>");.  When providing  multiple arguments to a macro, they should be separated by only commas:<br />
<b>&#94;x</b>(<i>"First argument",2</i>);
</p>

|,
		lastUpdated => 1146608624,
        },

	'topicName' => {
		message => q|Macros|,
		lastUpdated => 1128920014,
	},

};

1;
