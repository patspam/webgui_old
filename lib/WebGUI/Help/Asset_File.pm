package WebGUI::Help::Asset_File;

our $HELP = {

        'file add/edit' => {
		title => 'file add/edit title',
		body => 'file add/edit body',
		isa => [
			{
				tag => 'asset fields',
				namespace => 'Asset',
			},
		],
		fields => [
                        {
                                title => 'cache timeout',
                                namespace => 'Asset_File',
                                description => 'cache timeout help',
                                uiLevel => 8,
                        },
			{
				title => 'current file',
				description => 'current file description',
				namespace => 'Asset_File',
			},
			{
				title => 'new file',
				description => 'new file description',
				namespace => 'Asset_File',
			},
                        {
                                title => 'file template title',
                                description => 'file template description',
                                namespace => 'Asset_File',
                        },
		],
		related => [
			{
				tag => 'file template',
				namespace => 'Asset_File',
			},
		]
	},

        'file template' => {
		title => 'file template title',
		body => 'file template body',
		isa => [
			{
				namespace => "Asset_Template",
				tag => "template variables"
			},
			{
				namespace => "Asset",
				tag => "asset template"
			},
		],
		variables => [
			  {
			    'name' => 'fileSize'
			  },
			  {
			    'name' => 'fileIcon'
			  },
			  {
			    'name' => 'fileUrl'
			  },
			  {
			    'name' => 'controls'
			  },
			  {
			    'name' => 'filename'
			  },
			  {
			    'name' => 'storageId'
			  },
			  {
			    'name' => 'title'
			  },
			  {
			    'name' => 'menuTitle'
			  }
			],
		fields => [
		],
		related => [
			{
				tag => 'file add/edit',
				namespace => 'Asset_File',
			},
		]
	},

};

1;
