package WebGUI::Help::Asset_Thingy;

our $HELP = {
    'thingy template' => {
        title  => 'thingy template label',
        body   => '',
        fields => [],
        isa    => [
            {   namespace => "Asset_Thingy",
                tag       => "thingy asset template variables",
            },
            {   namespace => "Asset_Template",
                tag       => "template variables",
            },
        ],
         variables => [
            { 'name' => 'view_url' },
            {   'name'      => 'things_loop',
                'variables' => [
                    { 'name' => 'thing_editIcon' },
                    { 'name' => 'thing_deleteIcon' },
                    { 'name' => 'thing_viewIcon' },
                    { 'name' => 'thing_label' },
                    { 'name' => 'thing_id' },
                    { 'name' => 'thing_editUrl' },
                    { 'name' => 'thing_deleteUrl' },
                    { 'name' => 'thing_searchUrl' },
                    { 'name' => 'thing_addUrl' },
                    { 'name' => 'thing_copyUrl' },
                    { 'name' => 'thing_copyIcon' },
                ]
            },
        ],
        related => [
            {   tag       => 'edit thing template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'view thing template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'search thing template',
                namespace => 'Asset_Thingy',
            },
        ],
    },

  'edit thing template' => {
        title  => 'edit thing template label',
        body   => '',
        fields => [],
        isa    => [
            {   namespace => "Asset_Thingy",
                tag       => "thingy asset template variables",
            },
            {   namespace => "Asset_Template",
                tag       => "template variables",
            },
        ],
         variables => [
            { 'name' => 'delete_url' },
            { 'name' => 'delete_confirm' },
            { 'name' => 'search_url' },
            { 'name' => 'add_url' },
            { 'name' => 'editScreenTitle' },
            { 'name' => 'editInstructions' },
            {   'name'      => 'error_loop',
                'variables' => [ { 'name' => 'error_message' } ]
            },
            {   'name'      => 'field_loop',
                'variables' => [
                    { 'name' => 'field_isHidden' },
                    { 'name' => 'field_isRequired' },
                    { 'name' => 'field_isVisible' },
                    { 'name' => 'field_label' },
                    { 'name' => 'field_form' },
                    { 'name' => 'field_name' },
                    { 'name' => 'field_value' },
                    { 'name' => 'field_subtext' },
                    { 'name' => 'field_pretext' },
                ],
            },
            {   'name'      => 'listOfThings',
                'variables' => [
                    { 'name' => 'name' },
                    { 'name' => 'search_url' },
                    { 'name' => 'canView' },
                    { 'name' => 'isCurrent' },
                ],
            },
            {   'required' => 1,
                'name'     => 'form_start',
            },
            {   'required' => 1,
                'name'     => 'form_submit',
            },
            {   'required' => 1,
                'name'     => 'form_end',
            }
        ],
        related => [
            {   tag       => 'thingy template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'view thing template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'search thing template',
                namespace => 'Asset_Thingy',
            },
        ],
    },

    'view thing template' => {
        title => 'view thing template label',
        body  => '',
        isa   => [
            {   namespace => "Asset_Thingy",
                tag       => "thingy asset template variables",
            },
            {   namespace => "Asset_Template",
                tag       => "template variables",
            },
        ],
        fields    => [],
        variables => [
            { 'name' => 'delete_url' },
            { 'name' => 'delete_confirm' },
            { 'name' => 'search_url' },
            { 'name' => 'add_url' },
            { 'name' => 'edit_url' },
            { 'name' => 'viewScreenTitle' },
            {   'name'      => 'listOfThings',
                'variables' => [
                    { 'name' => 'name' },
                    { 'name' => 'search_url' },
                    { 'name' => 'canView' },
                    { 'name' => 'isCurrent' },
                ],
            },
            {   'name'      => 'field_loop',
                'variables' => [
                    { 'name' => 'field_isHidden' },
                    { 'name' => 'field_isRequired' },
                    { 'name' => 'field_isVisible' },
                    { 'name' => 'field_label' },
                    { 'name' => 'field_value' },
                    { 'name' => 'field_name' },
                    { 'name' => 'field_id' },
                    { 'name' => 'field_url' },
                    { 'name' => 'field_subtext' },
                    { 'name' => 'field_pretext' },
                ],
            },
        ],
        related => [
            {   tag       => 'edit thing template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'search thing template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'thingy template',
                namespace => 'Asset_Thingy',
            },
        ]
    },

    'search thing template' => {
        title  => 'search thing template label',
        body   => '',
        fields => [],
        isa    => [
            {   namespace => "Asset_Thingy",
                tag       => "thingy asset template variables",
            },
            {   namespace => "Asset_Template",
                tag       => "template variables",
            },
        ],
         variables => [
            { 'name' => 'add_url' },
            { 'name' => 'import_url' },
            { 'name' => 'export_url' },
            { 'name' => 'searchScreenTitle' },
            { 'name' => 'searchDescription' },
            {   'name'      => 'searchFields_loop',
                'variables' => [
                    { 'name' => 'searchFields_fieldId' },
                    { 'name' => 'searchFields_form' },
                    { 'name' => 'searchFields_textForm' },
                    { 'name' => 'searchFields_label' },
                    { 'name' => 'searchFields_is__fieldType__' },
                ],
            },
            {   'name'      => 'listOfThings',
                'variables' => [
                    { 'name' => 'name' },
                    { 'name' => 'search_url' },
                    { 'name' => 'canView' },
                    { 'name' => 'isCurrent' },
                ],
            },
            {   'required' => 1,
                'name'     => 'form_start',
            },
            {   'required' => 1,
                'name'     => 'form_submit',
            },
            {   'required' => 1,
                'name'     => 'form_end',
            },
            {   'name'      => 'displayInSearchFields_loop',
                'variables' => [
                    { 'name' => 'displayInSearchFields_fieldId' },
                    { 'name' => 'displayInSearchFields_orderByUrl' },
                    { 'name' => 'displayInSearchFields_label' },
                ]
            },
            {   'name'      => 'searchResult_loop',
                'variables' => [
                    { 'name' => 'searchResult_id' },
                    { 'name' => 'searchResult_view_url' },
                    { 'name' => 'searchResult_edit_icon' },
                    { 'name' => 'searchResult_delete_icon' },
                    {   'name' => 'searchResult_field_loop',
                        'variables' => [
                        { 'name' => 'field_id' },
                        { 'name' => 'field_value' },
                    ]
                    },
                ]
            },
        ],
        related => [
            {   tag       => 'edit thing template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'view thing template',
                namespace => 'Asset_Thingy',
            },
            {   tag       => 'thingy template',
                namespace => 'Asset_Thingy',
            },
        ],
    },

    'thingy asset template variables' => {
        private => 1,
        title   => 'thingy asset template variables title',
        body    => 'thingy asset template variables body',
        isa     => [
            {   namespace => "Asset_Wobject",
                tag       => "wobject template variables",
            },
        ],
        fields    => [],
        variables => [
            { 'name' => 'canEditThings' },
            { 'name' => 'manage_url' },
            { 'name' => 'addThing_url' },
        ],
        related => [],
    },
};

1;

