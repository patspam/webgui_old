package WebGUI::Help::Macro_AdminToggle;

our $HELP = {

        'admin toggle' => {
		title => 'admin toggle title',
		body => '',
		variables => [
		          {
		            'name' => 'toggle.url'
		          },
		          {
		            'name' => 'toggle.text'
		          }
		],
		fields => [
		],
		related => [
			{
				tag => 'template language',
				namespace => 'Asset_Template'
			},
		]
	},

};

1;
