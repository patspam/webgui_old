package WebGUI::i18n::English::Asset_Layout;

our $I18N = {
	'assetName' => {
		message => q|Page Layout|,
        	lastUpdated => 1128832065,
		context=>q|The name of the layout asset.|
	},

	'layout add/edit title' => {
		message => q|Page Layout, Add/Edit|,
        	lastUpdated => 1106683494,
	},

	'layout add/edit body' => {
                message => q|
<p>Page Layout Assets are used to display multiple Assets on the same time, much like
Page Layouts in version 5 of WebGUI.  The Page Layout Asset consists of a template with
multiple content areas, and Assets that are children of the Page Layout can be assigned
to be displayed in those areas.
</p>

<p>Page Layout Assets are Wobjects and Assets, and share the same properties of both.  Page Layout
Assets also have these unique properties:</p>|,
		context => 'Describing Page Layout Add/Edit form specific fields',
		lastUpdated => 1119410129,
	},

        'template description' => {
                message => q|Choose a template from the list to display the contents of the Page Layout Asset and
its children.|,
                lastUpdated => 1146455452,
        },

        'assets to hide description' => {
                message => q|This list contains one checkbox for each child Asset of the Page Layout.  Select the
checkbox for any Asset that you do not want displayed in the Page Layout Asset.
|,
                lastUpdated => 1119410080,
        },

	'layout template title' => {
		message => q|Page Layout Template|,
        	lastUpdated => 1109987374,
	},

	'showAdmin' => {
		message => q|A conditional showing if the current user has turned on Admin Mode and can edit this Asset.|,
		lastUpdated => 1148963207,
	},

	'dragger.icon' => {
		message => q|An icon that can be used to change the Asset's position with the mouse via a click and
drag interface.  If showAdmin is false, this variable is empty.|,
		lastUpdated => 1148963207,
	},

	'dragger.init' => {
		message => q|HTML and Javascript required to make the click and drag work. If showAdmin is false, this variable is empty.|,
		lastUpdated => 1148963207,
	},

	'position1_loop' => {
		message => q|Each position in the template has a loop which has the set of Assets
which are to be displayed inside of it.  Assets that have not been
specifically placed are put inside of position 1.|,
		lastUpdated => 1148963207,
	},

	'id' => {
		message => q|The Asset ID of the Asset.|,
		lastUpdated => 1148963207,
	},

	'content' => {
		message => q|The rendered content of the Asset.|,
		lastUpdated => 1148963207,
	},

	'attachment.size' => {
		message => q|The size of the file.|,
		lastUpdated => 1148963207,
	},

	'attachment.type' => {
		message => q|The type of the file (PDF, etc.)|,
		lastUpdated => 1148963207,
	},

	'layout template body' => {
                message => q|<p>The following variables are available in Page Layout Templates:</p>
		|,
		context => 'Describing the file template variables',
		lastUpdated => 1148963247,
	},

	'assets to hide' => {
		message => q|Assets To Hide.|,
		lastUpdated => 1118942468
	},

	'823' => {
		message => q|Go to the new page.|,
		lastUpdated => 1038706332
	},

	'847' => {
		message => q|Go back to the current page.|,
		lastUpdated => 1039587250
	},

};

1;
