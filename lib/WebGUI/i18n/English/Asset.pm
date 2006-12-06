package WebGUI::i18n::English::Asset;

our $I18N = {
	'save and commit' => {
		message => q|save &amp; commit|,
		lastUpdated => 0,
		context => q|A button added to all asset properties pages when save and commit mode is enabled.|
	},

	'add the missing page' => {
		message => q|Add the missing page.|,
		lastUpdated => 0,
		context => q|the question asked of the admin when they click on a missing page|
	},

	'missing page query' => {
		message => q|The page you have requested does not exist. What would you like to do?|,
		lastUpdated => 0,
		context => q|the question asked of the admin when they click on a missing page|
	},

	'package corrupt' => {
		message => q|The package you tried to import appears to be corrupt. We imported up to the point where we detected corruption. If you won't want this portion, roll back your current version tag.|,
		lastUpdated => 0,
		context => q|error message about package corruption|
	},

	'import' => {
		message => q|Import|,
		lastUpdated => 0,
		context => q|the title on the package import button|
	},

	'over max assets' => {
		message => q|Your administrator has limited the number of assets you may place on your site, and you have exceeded the limit. Delete some old assets in order to add more.|,
		lastUpdated => 0,
		context => q|an error message that will be displayed if the number of assets is >= to the maximumAssets defined in the config file|
	},

	'confirm change url message' => {
		message => q|Setting this to 'Yes' confirms that you want to permanently change this URL, thusly deleteing all old revisions of this asset.|,
		lastUpdated => 0,
		context => q|explains the implications of the change url function|
	},

	'confirm change' => {
		message => q|Are you sure?|,
		lastUpdated => 0,
		context => q|confirmation question|
	},

	'change url' => {
		message => q|Change URL|,
		lastUpdated => 0,
		context => q|the title of the change url function|
	},

	'change url help' => {
		message => q|Bring up the Change URL screen for this Asset.|,
		lastUpdated => 0,
	},

	'change url body' => {
		message => q|<p>Suppose that you want to put a new Asset in the place of an old Asset and to use the old Asset's URL for the new Asset.  Normally, to do this you would have to change the URL in the latest revision of the Asset and then purge each and every revision of the old Asset (since the old revisions of the old Asset have the same URL).  Change URL allows you to do this easily.  Enter in the new URL for the old Asset, and it will perform all the work for you.</p>|,
		lastUpdated => 0,
	},

	'ago' => {
		message => q|ago|,
		lastUpdated => 0,
		context => q|a suffix for a measurement of time, like "3 seconds ago"|
	},

	'purge old trash' => {
		message => q|Purge Old Trash|,
		lastUpdated => 0,
		context => q|title of the purge trash workflow activity|
	},

	'purge trash after' => {
		message => q|Purge Old Trash After|,
		lastUpdated => 0,
		context => q|the label used in the purge old trash workflow activity|
	},

	'purge trash after help' => {
		message => q|How long should an asset stay in the trash before it's considered old enough to purge? Note that when it get's purged all it's revisions and descendants will be purged as well.|,
		lastUpdated => 0,
		context => q|the hover help for the purge trash after field|
	},

	'purge old asset revisions' => {
		message => q|Purge Old Asset Revisions|,
		lastUpdated => 0,
		context => q|title of the purge old asset revisions workflow activity|
	},

	'purge revision after' => {
		message => q|Purge Old Revisions After|,
		lastUpdated => 0,
		context => q|the label used in the purge expired asset revisions workflow activity|
	},

	'purge revision after help' => {
		message => q|How long should old revisions of an asset be kept? Old asset revisions are those that are no longer viewable by users, but are kept in the versioning system for rollbacks.|,
		lastUpdated => 0,
		context => q|the hover help for the purge revision after field|
	},

	'purge revision prompt' => {
		message => q|Are you certain you wish to delete this revision of this asset? It CANNOT be restored if you delete it.|,
		lastUpdated => 0,
		context => q|The prompt for purging a revision from the asset tree.|
	},

	'purge' => {
		message => q|Purge|,
		lastUpdated => 0,
		context => q|The label for the purge button in the trash manager.|
	},

	'lock' => {
		message => q|Lock|,
		lastUpdated => 0,
		context => q|A context menu item to lock an asset for editing.|
	},

	'lock help' => {
		message => q|Grab a copy of this Asset for editing, which locks the Asset to anyone not using your current version tag.  This option is only displayed if the Asset isn't currently locked.|,
		lastUpdated => 0,
	},

	'locked' => {
		message => q|Locked|,
		lastUpdated => 0,
		context => q|A label for a column in the asset manager indicating whether the asset is locked for editing.|
	},

	'revisions' => {
		message => q|Revisions|,
		lastUpdated => 0,
		context => q|Context menu item.|
	},

	'revisions help' => {
		message => q|Show a list of all revisions of this Asset.|,
		lastUpdated => 0,
	},

	'rank' => {
		message => q|Rank|,
		lastUpdated => 0,
		context => q|Column heading in asset manager.|
	},
	
	'revised by' => {
		message => q|Revised By|,
		lastUpdated => 0,
		context => q|manage revisions in tag|
	},

	'revision date' => {
		message => q|Revision Date|,
		lastUpdated => 0,
		context => q|manage revisions in tag|
	},

	'tag name' => {
		message => q|Tag Name|,
		lastUpdated => 0,
		context => q|manage revisions in tag|
	},

	'type' => {
		message => q|Type|,
		lastUpdated => 0,
		context => q|Column heading in asset manager.|
	},
	
	'size' => {
		message => q|Size|,
		lastUpdated => 0,
		context => q|Column heading in asset manager.|
	},
	
	'last updated' => {
		message => q|Last Updated|,
		lastUpdated => 0,
		context => q|Column heading in asset manager.|
	},
	
	'restore' => {
		message => q|Restore|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'promote' => {
		message => q|Promote|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'promote help' => {
		message => q|Move this Asset up one spot on the page.|,
		lastUpdated => 0,
	},

	'demote' => {
		message => q|Demote|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'demote help' => {
		message => q|Move this Asset down one spot on the page.|,
		lastUpdated => 0,
	},

	'cut' => {
		message => q|Cut|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},
	
	'duplicate' => {
		message => q|Duplicate|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},
	
	'copy' => {
		message => q|Copy|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},
	
	'create shortcut' => {
		message => q|Create Shortcut|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'view' => {
		message => q|View|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'view help' => {
		message => q|Most Assets are viewed as part of a container Asset like a Page or Folder.  This option will allow you to view the Asset standalone.|,
		lastUpdated => 0,
	},

	'delete' => {
		message => q|Delete|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},
	
	'manage' => {
		message => q|Manage|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'manage help' => {
		message => q|Bring up the Asset Manager displaying this Asset's children, if any.|,
		lastUpdated => 0,
	},

	'edit branch' => {
		message => q|Edit Branch|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'edit branch help' => {
		message => q|Bring up the Edit Branch interface, to make changes to this Asset and Assets below it|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},

	'edit branch body' => {
		message => q|<p>Edit Branch allows you to make changes to entire trees of Assets.  You can change who can view Assets, who can edit Assets or you can change the templates or other display features such as SSL or whether to hide the Asset from navigations.  The form will not give you editing privileges for Assets that you don't have.</p>
<p>Each field has a Yes/No button to confirm that you want to change it recursively.  Simply edit the fields that you want to change and select Yes from its change confirmation, and then hit save when you're all done.</p>|,
		lastUpdated => 0,
		context => q|Used in edit branch help.|
	},

	'edit' => {
		message => q|Edit|,
		lastUpdated => 0,
		context => q|Used in asset context menus.|
	},
	
	'change' => {
		message => q|Change recursively?|,
		lastUpdated => 1099344172,
		context => q|Used when editing an entire branch, and asks whether the user wants to change this field recursively.|
	},

	'select all' => {
		message => q|Select All|,
		lastUpdated => 1099344172,
		context => q|A label for the select all checkbox on the asset manager|
	},

	'packages' => {
		message => q|Packages|,
		lastUpdated => 1099344172,
		context => q|The title of the package chooser in the asset manager|
	},
	
	'assets' => {
		message => q|Assets|,
		lastUpdated => 1099344172,
		context => q|The title of the asset manager for the admin console.|
	},
	
	'properties' => {
		message => q|Properties|,
		lastUpdated => 1099344172,
		context => q|The name of the properties tab on the edit asset.|
	},
	
	'make package' => {
		message => q|Make package?|,
		lastUpdated => 1099344172,
	},

	'make prototype' => {
		message => q|Make prototype?|,
		lastUpdated => 1099344172,
	},

	'asset id' => {
		message => q|Asset ID|,
		lastUpdated => 1099344172,
	},

        'asset fields body' => {
                message => q|<p>These are the base properties that all Assets share:</p>|,
                context => q|Describing the form to add or edit an Asset.|,
                lastUpdated => 1127426220,
        },

        'asset id description' => {
                message => q|<p>This is the unique identifier WebGUI uses to keep track of this Asset instance. Normal users should never need to be concerned with the Asset ID, but some advanced users may need to know it for things like SQL Reports. The Asset ID is not editable.</p>|,
                lastUpdated => 1127426210,
        },

        '99 description' => {
                message => q|<p>The title of the asset.  This should be descriptive, but not very long.  If left
blank, this will be set to "Untitled".</p>
<p><i>Note:</i> You should always specify a title, even if the Asset template will not use it. In various places on the site, like the Page Tree, Clipboard and Trash, the <b>Title</b> is used to distinguish this Asset from others.</p>|,
                lastUpdated => 1146629119,
        },

        '411 description' => {
                message => q|<p>A shorter title that will appear in navigation. If left blank,
this will default to the <b>Title</b>.</p>|,
                lastUpdated => 1146629570,
        },

        '104 description' => {
                message => q|<p>The URL for this asset.  It must be unique.  If this field is left blank, then
a URL will be made from the parent's URL and the <b>Menu Title</b>.</p>|,
                lastUpdated => 1146629543,
        },

        '886 description' => {
                message => q|<p>Whether or not this asset will be hidden from the navigation menu and site maps.</p>|,
                lastUpdated => 1146629520,
        },

        '940 description' => {
                message => q|<p>Select yes to open this asset in a new window. Note that there are potentially many problems with this. It may not work in some navigations, or if the user turns off Javascript, or it may be blocked by some pop-up blockers. Use this feature with care.</p>|,
                lastUpdated => 1143218834,
        },

        'encrypt page description' => {
                message => q|<p>Should the page containing this asset be served over SSL?</p>|,
                lastUpdated => 1146629489,
        },

        '108 description' => {
                message => q|<p>The owner of an asset is usually the person who created the asset. This user always has full edit and viewing rights of the asset.</p>
<p><b>NOTE:</b> The owner can only be changed by an administrator.
</p>|,
                lastUpdated => 1165364456,
        },

        '872 description' => {
                message => q|<p>Choose which group can view this asset. If you want both visitors and registered users to be able to view the asset then you should choose the "Everybody" group.</p>|,
                lastUpdated => 1146629267,
        },

        '871 description' => {
                message => q|<p>Choose the group that can edit this asset. The group assigned editing rights can also always view the asset.</p>|,
                lastUpdated => 1146629269,
        },

        '412 description' => {
                message => q|<p>A short description of this Asset.</p>|,
                lastUpdated => 1146629271,
        },

        'extra head tags description' => {
                message => q|<p>These tags will be added to the &lt;head&gt; section of each page that the asset appears on.</p>|,
                lastUpdated => 1126471216,
        },

        'make package description' => {
                message => q|<p>Many WebGUI tasks are very repetitive.  Automating such tasks in WebGUI, such as
creating an Asset, or sets of Assets, is done by creating a package that can be reused
throughout the site.  Check yes if you want this Asset to be available as a package.</p>|,
                lastUpdated => 1165365151,
        },

        'make prototype description' => {
                message => q|<p>Set this Asset to be a Content Prototype so that others can use it on your site.</p>|,
                lastUpdated => 1119149899,
        },

        'prototype using title' => {
                message => q|Content Prototypes, Using|,
                lastUpdated => 1127413710,
        },

        'prototype using body' => {
                message => q|<p>Chances are if you like assets to be configured a certain way, then you'll find Prototypes useful. By setting an Asset as a Prototype you can create new items in your Add content menu configured exactly as you like. For instance, if you use the Collaboration System as a photo gallery, then create a photo gallery and mark it as a Prototype. From then on you can just "Add content > New Content > Photo Gallery".</p>
<p>The title of the Asset is used as the name of the Content Prototype in the Add content menu.  If you set the title
of your prototype to be the same as the name of an Asset (Article, DataForm, etc.) then it will replace the WebGUI
default Asset in the menu.</p>|,
                lastUpdated => 1127413713,
        },

	'asset fields title' => {
	    message => q|Asset, Common Fields|,
	    lastUpdated => 1113357557,
	},

	'controls' => {
		message => q|These are the icons and URLs that allow editing, cutting, copying, deleting and reordering the Asset.|,
		lastUpdated => 1148840768,
	},

        'asset template body' => {
                message => q|
<p>This variable is inserted into every template:</p>

        |,
        lastUpdated => 1113357523,
  },

	'asset template title' => {
	    message => q|Asset Template Variables|,
	    lastUpdated => 1100463645,
	},


	'asset' => {
		message => q|Asset|,
        	lastUpdated => 1100463645,
		context => 'The default name of all assets.'
	},

	'extra head tags' => {
		message => q|Extra &lt;head&gt; elements (tags)|,
		context => q|label for Asset form|,
        	lastUpdated => 1126381168,
	},

	'create package' => {
		message => q|Make available as package?|,
		context => q|label for Asset form|,
        	lastUpdated => 1106762073,
	},

	'errorEmptyField' => {
		message => q|<p><b>Error: Field name may not be empty.</b></p>|,
		lastUpdated => 1089039511,
	},

	'Select' => {
		message => q|Select...|,
		lastUpdated => 1127958072
	},

	'duplicateField' => {
		message => q|<p><b>Error: Fieldname "%field%" is already in use.</b></p>|,
		lastUpdated => 1089039511
	},

	'Metadata' => {
		message => q|Metadata|,
		lastUpdated => 1089039511
	},

	'Field name' => {
		message => q|Field name|,
		lastUpdated => 1089039511
	},

	'Edit Metadata' => {
		message => q|Edit Metadata property|,
		lastUpdated => 1089039511
	},

	'Add new field' => {
		message => q|Add new metadata property|,
		lastUpdated => 1089039511
	},

	'Add new field description' => {
		message => q|<p>Open up a form where new metadata fields can be added to this Asset.</p>|,
		lastUpdated => 1129329405
	},

	'deleteConfirm' => {
		message => q|Are you certain you want to delete this Metadata property ?|,
		lastUpdated => 1089039511
	},

	'Field Id' => {
		message => q|Field Id|,
		lastUpdated => 1089039511
	},

	'Delete Metadata field' => {
		message => q|Delete Metadata property|,
		lastUpdated => 1089039511
	},

	'content profiling' => {
		message => q|Content Profiling|,
		lastUpdated => 1089039511,
		context => q|The title of the content profiling manager for the admin console.|
	},

        'Field Name description' => {
                message => q|<p>The name of this metadata property.It must be unique. <br />
It is advisable to use only letters (a-z), numbers (0-9) or underscores (_) for
the field names.</p>|,
                lastUpdated => 1129329870,
        },

        'Metadata Description description' => {
                message => q|<p>An optional description for this metadata property. This text is displayed
as mouseover text in the asset properties tab.</p>|,
                lastUpdated => 1129329870,
        },

        'Data Type description' => {
                message => q|<p>Choose the type of form element for this field.</p>|,
                lastUpdated => 1129329870,
        },

        'Possible Values description' => {
                message => q|<p>This field is used only for the Radio List and Select List data types. Enter
the values you wish to appear, one per line.</p>|,
                lastUpdated => 1129329870,
        },


	'metadata edit property body' => {
		message => q|
<p>You may add as many Metadata properties to a Wobject as you like.</p>
|,
		lastUpdated => 1129330051
	},

        'metadata manage body' => {
                message => q|
<p>The content profiling system in WebGUI (also known as the metadata system) allows you to identify content. Metadata is
information about the content, and is defined in terms of property-value pairs.</p>
<p>Examples of metadata:</p>
<ul>
  <li>contenttype: sport</li>
  <li>adult content: no</li>
  <li>source: newspaper</li>
</ul>
<p>In the example <b>source: newspaper</b>, this metadata has a <i>property</i> named
<i>source</i> with a <i>value</i> of <i>newspaper</i>.</p>
<p>Metadata properties are defined globally, while Metadata values are set for
each asset under the tab &quot;Meta&quot; in the asset properties.</p>
<p>Before you can use metadata in WebGUI, you have to enable metadata in the WebGUI Settings (Content tab)</p>
<p>Usage of metadata:</p>
<ul>
  <li><p><b>Passive Profiling</b><br />
    When passive profiling is switched on, every wobject viewed by a user will
    be logged.  The WebGUI scheduler summarizes the profiling information on a regular
    basis.
    This is basically content
    ranking based upon the user's Areas of Interest (AOI).<br />
    By default the summarizer runs once a day. However you can change that by
    setting: <b>passiveProfileInterval = &lt;number of seconds&gt;</b> in the
    WebGUI config file.</p>
  </li>
  <li><p><b>Areas of Interest Ranking</b><br />
    Metadata in combination with passive profiling produces AOI (<b>Areas of
    Interest</b>) information. You can retrieve the value of a metadata property
    with the &#94;AOIRank(); and &#94;AOIHits(); macros.</p>
  </li>
  <li><p><b>Show content based upon criteria</b><br />
    The Wobject Proxy allows you to select content based upon criteria like:</p>
    <div class="helpIndent">
    contenttype = sport AND source != newspaper
    </div>
    <p>You can use the AOI macro's described above in the criteria, so you can
    present content based upon the users Areas of Interest. Example:<br />
    type = &#94;AOIRank(contenttype);</p></li>
   <li><p><b>Display</b><br />
    Metadata fields are exposed to the asset templates as their property name. So you can actually display the metadata
    to the rendered page using a template variable like &lt;tmpl_var <i>propertyname</i>&gt;</p></li>
   <li><p><b>Meta tags</b><br />
    Since the meta data is exposed as template variables, you can use them in the Head Block of Style templates
    to create meta tags from meta data, including the tags from the Dublin Core standard.</p></li>
</ul>|,
                context => q|Metadata help|,
                lastUpdated => 1165356337
        },

	'metadata edit property' => {
		message => q|Metadata, Edit|,
		lastUpdated => 1089039511
	},

        '1079' => {
                    lastUpdated => 1073152790,
                    message => q|Printable Style|
                  },
        '959' => {
                   lastUpdated => 1052850265,
                   message => q|Empty system clipboard.|
                 },
        'Uploads URL' => {
                           lastUpdated => 1089039511,
                           context => q|Field label for the Export Page operation|,
                           message => q|Uploads URL|
                         },
        '99' => {
                  lastUpdated => 1031514049,
                  message => q|Title|
                },
        'Page Export Status' => {
                                  lastUpdated => 1089039511,
                                  context => q|Title for the Page Export Status operation|,
                                  message => q|Page Export Status|
                                },
        '1083' => {
                    lastUpdated => 1076866510,
                    message => q|New Content|
                  },
        '965' => {
                   lastUpdated => 1099050265,
                   message => q|System Trash|
                 },
        '966' => {
        	         lastUpdated => 1099050265,
                   message => q|System Clipboard|
        	       },
        'Extras URL' => {
                          lastUpdated => 1089039511,
                          context => q|Field label for the Export Page operation|,
                          message => q|Extras URL|
                        },
        '895' => {
                   lastUpdated => 1056292971,
                   message => q|Cache Timeout|
                 },
        '108' => {
                   lastUpdated => 1031514049,
                   message => q|Owner|
                 },
        '872' => {
                   lastUpdated => 1044218038,
                   message => q|Who can view?|
                 },
        '896' => {
                   lastUpdated => 1056292980,
                   message => q|Cache Timeout (Visitors)|
                 },
        'Export as user' => {
                              lastUpdated => 1089039511,
                              context => q|Field label for the Export Page operation|,
                              message => q|Export as user|
                            },
        '871' => {
                   lastUpdated => 1044218026,
                   message => q|Who can edit?|
                 },
        '104' => {
                   lastUpdated => 1031514049,
                   context => q|asset property|,
                   message => q|URL|
                 },
        '11' => {
                  lastUpdated => 1051514049,
                  message => q|Empty trash.|
                },
        '412' => {
                   lastUpdated => 1031514049,
                   message => q|Summary|
                 },
        '954' => {
                   lastUpdated => 1052850265,
                   message => q|Manage system clipboard.|
                 },
        '1082' => {
                    lastUpdated => 1076866475,
                    message => q|Clipboard|
                  },
        '107' => {
                   lastUpdated => 1031514049,
                   message => q|Security|
                 },
        '174' => {
                   lastUpdated => 1031514049,
                   message => q|Display the title?|
                 },
        '487' => {
                   lastUpdated => 1031514049,
                   message => q|Possible Values|
                 },
        'Depth' => {
                     lastUpdated => 1089039511,
                     context => q|Field label for the Export Page operation|,
                     message => q|Depth|
                   },
        '964' => {
                   lastUpdated => 1052850265,
                   message => q|Manage system trash.|
                 },
        '105' => {
                   lastUpdated => 1046638916,
                   message => q|Display|
                 },
        '1073' => {
                    lastUpdated => 1070027660,
                    message => q|Style Template|
                  },
        'Export Page' => {
                           lastUpdated => 1089039511,
                           context => q|Title for the Export Page operation|,
                           message => q|Export Page|
                         },
        '951' => {
                   lastUpdated => 1052850265,
                   message => q|Are you certain that you wish to empty the clipboard to the trash?|
                 },
        '950' => {
                   lastUpdated => 1052850265,
                   message => q|Empty clipboard.|
                 },
        '85' => {
                  lastUpdated => 1031514049,
                  message => q|Description|
                },
        '486' => {
                   lastUpdated => 1031514049,
                   message => q|Data Type|
                 },
        '949' => {
                   lastUpdated => 1052850265,
                   message => q|Manage clipboard.|
                 },
        '411' => {
                   lastUpdated => 1031514049,
                   message => q|Menu Title|
                 },
        '886' => {
                   lastUpdated => 1044727952,
                   message => q|Hide from navigation?|
                 },
        '43' => {
                  lastUpdated => 1149960436,
                  message => q|Are you certain that you wish to delete this content? Note that this change is not versioned and will take place immediately.|
                },
        '940' => {
                   lastUpdated => 1050438829,
                   message => q|Open in new window?|
                 },
	'encrypt page' => {
                message => q|Encrypt content?|,
                lastUpdated =>1092748557,
                context => q|asset property|
        },

	'asset list title' => {
		 lastUpdated => 1112220921,
		 message => q|Asset, List of Available|
	       },

	'asset list body' => {
		 lastUpdated => 1112291919,
		 message => q|<p>These Assets are available for use at your site:</p>|
	       },

	'directory index' => {
		 lastUpdated => 1118896675,
		 message => q|Directory Index|,
	       },

        'Depth description' => {
                message => q|<p>Sets the depth of the page tree to export. Use a depth of 0 to export only the current page. </p>|,
                lastUpdated => 1121361557,
        },

        'Export as user description' => {
                message => q|<p>Run the export as this user. Defaults to Visitor.</p>|,
                lastUpdated => 1121361557,
        },

        'directory index description' => {
                message => q|<p>If the URL of the Asset to be exported looks like a directory, the directory index will
be appended to it.</p>|,
                lastUpdated => 1121361557,
        },

        'Extras URL description' => {
                message => q|<p>Sets the Extras URL. Defaults to the configured extrasURL in the WebGUI
config file.</p>|,
                lastUpdated => 1121361557,
        },

        'Uploads URL description' => {
                message => q|<p>Sets the Uploads URL. Defaults to the configured uploadsURL in the WebGUI config file.</p>|,
                lastUpdated => 1121361557,
        },

	'Page Export' => {
                message => q|Page, Export|,
                lastUpdated => 1089039511,
                context => q|Help title for Page Export operation|
        },
	'Page Export body' => {
                message => q|
<p>The Export Page function allows you to export WebGUI pages to static
HTML files on disk.  The &quot;exportPath&quot; variable in the WebGUI
config file must be enabled for this function to be available.</p>
				|,
                lastUpdated => 1121361734,
                context => q|Help body for Page Export operation|
        },

	'exporting page' => {
		message => q|Exporting page %-s ......|,
		lastUpdated => 1129420080,
	},

	'bad user privileges' => {
		message => q|User has no privileges to view this page.<br />|,
		lastUpdated => 1129420080,
	},

	'could not create path' => {
		message => q|
Couldn't create %-s because %-s <br />
This most likely means that you have a page with the same name as folder that you're trying to create.<br />
|,
		lastUpdated => 1129436410,
	},

	'could not open path' => {
		message => q|
Couldn't open %-s because %-s <br />
|,
		lastUpdated => 1129436544,
	},

	'export information' => {
		message => q|
<p>Exported %d pages in %d seconds.</p>|,
		lastUpdated => 1129436684,
	},

	'done' => {
		message => q|DONE<br />|,
		lastUpdated => 1129420080,
	},

	'committed versions' => {
		message => q|Committed Versions|,
		lastUpdated => 0,
		context => q|Admin console label for manage versions.|
	},

	'manage versions body' => {
		message => q|<p>This screen displays a list of all versions for the current Asset, showing the date it was committed or opened, who owns the tag for that version, and the name of the version tag.  Icons will allow you purge a revision and remove it from the system or to view that particular version of the  Asset.  The version tag name is a link that will take you to the Manage Revisions in Tag screen.|,
		lastUpdated => 0,
	},

	'asset toolbar title' => {
		message => q|Asset Toolbar|,
		lastUpdated => 0,
	},

	'asset toolbar body' => {
		message => q|<p>When you are viewing an asset in Admin mode, and if you have editing privileges for that asset
and you have Admin mode turned on, the asset will display a toolbar with icons that allow you
to edit or modify that asset.</p>|,
		lastUpdated => 1165448599,
	},

	'Class Icon' => {
		message => q|Class Icon|,
		lastUpdated => 0,
	},

	'Class Icon help' => {
		message => q|Each Asset will also display a class icon.  Most Class Icons are unique to an Asset, and are smaller versions of the icons diplayed in the New Content menu of the Admin Console for that Asset.  Clicking on the Class Icon will show a drop-down menu with additional editing options.|,
		lastUpdated => 1165448677,
	},

	'parent url' => {
		message => q|Parent URL|,
		lastUpdated => 0,
	},

	'specified base' => {
		message => q|Specified Base|,
		lastUpdated => 0,
	},

	'none' => {
		message => q|None|,
		lastUpdated => 0,
	},

	'current url' => {
		message => q|Current URL|,
		lastUpdated => 0,
	},

	'edit branch url help' => {
		message => q|<p>You can change the URL via two parts, the base URL (the left field) and the file url (the right field).  For the base URL, there are three options:</p>
<div>
<dl>
<dt>Parent URL</dt>
<dd>Start this URL with the URL of the parent.</dd>
<dt>Specified Base</dt>
<dd>Enter in a new base URL via the field that appears when Specified Base is selected.</dd>
<dt>None</dt>
<dd>Make all Assets have a "top-level" URL.</dd>
</dl>
</div>
<p>There are also three options for the file URL:</p>
<div>
<dl>
<dt>Menu Title</dt>
<dd>The new URL will be based on the Asset's Menu Title field.</dd>
<dt>Title</dt>
<dd>The new URL will be based on the Asset's Title field.</dd>
<dt>Current URL</dt>
<dd>The new URL will be based on the Asset's present URL.</dd>
</dl>
</div>
<p>New URLs will be passed through the makeUrlCompliant function that is specific to the default language for your site.</p>
|,
		lastUpdated => 0,
	},

	'topicName' => {
		message => q|Assets|,
		lastUpdated => 1128920336,
	},

	'extrasUploads symlinking' => {
		message => q|Symlinking extras and uploads dirs.|,
		lastUpdated => 1160773957,
	},

	'rootUrl symlinking default' => {
		message => q|Symlinking extras and uploads dirs.|,
		lastUpdated => 1160773957,
	},

	'rootUrl default not present' => {
		message => q|Not symlinking default asset; not included in exported subtree.|,
		lastUpdated => 1160773957,
	},

	'could not create' => {
		message => q|Could not create %s: %s|,
		lastUpdated => 1160773957,
	},

	'could not unlink' => {
		message => q|Could not unlink %s: %s|,
		lastUpdated => 1160773957,
	},

	'could not rmdir' => {
		message => q|Could not remove directory at %s: %s|,
		lastUpdated => 1160773957,
	},

	'could not symlink' => {
		message => q|Could not symlink %s to %s: %s|,
		lastUpdated => 1160773957,
	},

	'extrasUploads form label' => {
		message => q|Extras and uploads directories|,
		lastUpdated => 1160773957,
	},

	'extrasUploads form hoverHelp' => {
		message => q|What action to take regarding the extras and uploads directories, which are often referenced by parts of the site.  Symlink means to use a symbolic link (not available on all systems) to the original directory.  None means to do nothing, and ignore the extras and uploads directories; this will probably cause references to them to break in the exported site unless you've prepared the directories already.|,
		lastUpdated => 1160773957,
	},

	'extrasUploads form option symlink' => {
		message => q|Symlink|,
		lastUpdated => 1160773957,
	},

	'extrasUploads form option none' => {
		message => q|None|,
		lastUpdated => 1160773957,
	},

	'rootUrl form label' => {
		message => q|Root URL|,
		lastUpdated => 1160773957,
	},

	'rootUrl form hoverHelp' => {
		message => q|What action to take regarding queries to the root URL.  Symlink Default means to create a symbolic link from the root-URL index file to the index file of the default asset (not available on all systems).  None means to do nothing, which usually causes queries to the root URL to be rejected in the exported site.|,
		lastUpdated => 1160773957,
	},

	'rootUrl form option symlinkDefault' => {
		message => q|Symlink Default|,
		lastUpdated => 1160773957,
	},

	'rootUrl form option none' => {
		message => q|None|,
		lastUpdated => 1160773957,
	},

};

1;
