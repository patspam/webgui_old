package WebGUI::Help::Asset_Photo;

our $HELP = {
    'help commentForm' => {
        title   => 'help commentForm title',
        body    => 'help commentForm body',
        variables => [
            {
                name        => 'commentForm_start',
                description => 'helpvar commentForm_start',
            },
            {
                name        => 'commentForm_end',
                description => 'helpvar commentForm_end',
            },
            {
                name        => 'commentForm_bodyText',
                description => 'helpvar commentForm_bodyText',
            },
            {
                name        => 'commentForm_submit',
                description => 'helpvar commentForm_submit',
            },
        ],
    },

    'help common' => {
        title   => 'help common title',
        body    => 'help common body',
        isa => [
            {
                tag         => 'help searchForm',
                namespace   => 'Asset_Gallery',
            },
            {
                tag         => 'help commentForm',
                namespace   => 'Asset_Photo',
            },
        ],
        variables => [
            {
                name        => 'canComment',
                description => 'helpvar canComment',
            },
            {
                name        => 'canEdit',
                description => 'helpvar canEdit',
            },
            {
                name        => 'fileUrl',
                description => 'helpvar fileUrl',
            },
            {
                name        => 'numberOfComments',
                description => 'helpvar numberOfComments',
            },
            {
                name        => 'ownerUsername',
                description => 'helpvar ownerUsername',
            },
            {
                name        => 'thumbnailUrl',
                description => 'helpvar thumbnailUrl',
            },
            {
                name        => 'url_delete',
                description => 'helpvar url_delete',
            },
            {
                name        => 'url_demote',
                description => 'helpvar url_demote',
            },
            {
                name        => 'url_edit',
                description => 'helpvar url_edit',
            },
            {
                name        => 'url_gallery',
                description => 'helpvar url_gallery',
            },
            {
                name        => 'url_makeShortcut',
                description => 'helpvar url_makeShortcut',
            },
            {
                name        => 'url_listFilesForOwner',
                description => 'helpvar url_listFilesForOwner',
            },
            {
                name        => 'url_promote',
                description => 'helpvar url_promote',
            },
            { 
                name        => 'resolutions_loop',
                description => 'helpvar resolutions_loop',
                variables   => [
                    {
                        name        => 'url_download',
                        description => 'helpvar resolutions_loop url_download',
                    },
                ],
            },
            {
                name        => 'exif_',
                description => 'helpvar exif_',
            },
            {
                name        => 'exifLoop',
                description => 'helpvar exifLoop',
                variables   => [
                    {
                        name        => 'tag',
                        description => 'helpvar exifLoop tag',
                    },
                    {
                        name        => 'value',
                        description => 'helpvar exifLoop value',
                    },
                ],
            },
            {
                name        => 'synopsis_text',
                description => 'helpvar synopsis_text',
            },
            {
                name        => 'url_album',
                description => 'helpvar url_album',
            },
            {
                name        => 'url_thumbnails',
                description => 'helpvar url_thumbnails',
            },
            {
                name        => 'url_slideshow',
                description => 'helpvar url_slideshow',
            },
            {
                name        => 'gallery_title',
                description => 'helpvar gallery_title',
            },
            {
                name        => 'gallery_menuTitle',
                description => 'helpvar gallery_menuTitle',
            },
            {
                name        => 'gallery_url',
                description => 'helpvar gallery_url',
            },
            {
                name        => 'album_title',
                description => 'helpvar album_title',
            },
            {
                name        => 'album_menuTitle',
                description => 'helpvar album_menuTitle',
            },
            {
                name        => 'album_thumbnailUrl',
                description => 'helpvar album_thumbnailUrl',
            },
            {
                name        => 'album_url',
                description => 'helpvar album_url',
            },
        ],
    },

    'help delete'   => {
        title       => 'help delete title',
        body        => 'help delete body',
        isa         => [
            {
                tag         => 'help common',
                namespace   => 'Asset_Photo',
            },
        ],
        variables   => [
            {
                name        => 'url_yes',
                description => 'helpvar url_yes',
            },
        ],
    },
    
    'help edit' => {
        title       => 'help edit title',
        body        => 'help edit body',
        variables => [
            { 
                name        => 'isNewPhoto',
                description => 'helpvar isNewPhoto',
            },
            {
                name        => 'url_addArchive',
                description => 'helpvar url_addArchive',
            },
            {
                name        => 'form_start',
                description => 'helpvar form_start',
                required    => 1,
            },
            {
                name        => 'form_end',
                description => 'helpvar form_end',
                required    => 1,
            },
            {
                name        => 'form_submit',
                description => 'helpvar form_submit',
            },
            {
                name        => 'form_title',
                description => 'helpvar form_title',
            },
            {
                name        => 'form_synopsis',
                description => 'helpvar form_synopsis',
            },
            {
                name        => 'form_photo',
                description => 'helpvar form_photo',
            },
            {
                name        => 'form_keywords',
                description => 'helpvar form_keywords',
            },
            {
                name        => 'form_location',
                description => 'helpvar form_location',
            },
            {
                name        => 'form_friendsOnly',
                description => 'helpvar form_friendsOnly',
            },
        ],
    },
    
    'help makeShortcut' => {
        title       => 'help makeShortcut title',
        body        => 'help makeShortcut body',
        variables => [
            {
                name        => 'form_start',
                description => 'helpvar form_start',
                required    => 1,
            },
            {
                name        => 'form_end',
                description => 'helpvar form_end',
                required    => 1,
            },
            {
                name        => 'form_parentId',
                description => 'helpvar form_parentId',
                required    => 1,
            },
        ],
    },

    'help view' => {
        title       => 'help view title',
        body        => 'help view body',
        isa         => [
            { 
                tag         => 'help common',
                namespace   => 'Asset_Photo',
            },
        ],
        variables => [
            {
                name        => 'commentLoop',
                description => 'helpvar commentLoop',
                variables   => [
                    {
                        name        => 'userId',
                        description => 'helpvar commentLoop userId',
                    },
                    {
                        name        => 'visitorIp',
                        description => 'helpvar commentLoop visitorIp',
                    },
                    {
                        name        => 'creationDate',
                        description => 'helpvar commentLoop creationDate',
                    },
                    {
                        name        => 'bodyText',
                        description => 'helpvar commentLoop bodyText',
                    },
                    {
                        name        => 'username',
                        description => 'helpvar commentLoop username',
                    },
                    {
                        name        => 'url_deleteComment',
                        description => 'helpvar commentLoop url_deleteComment',
                    },
                ],
            },
            {
                name        => 'commentLoop_pageBar',
                description => 'helpvar commentLoop_pageBar',
            },
            {
                name        => 'keywords',
                description => 'helpvar keywords',
                variables   => [
                    {
                        name        => 'keyword',
                        description => 'helpvar keyword',
                    },
                    {
                        name        => 'url_searchKeyword',
                        description => 'helpvar url_searchKeyword',
                    },
                    {
                        name        => 'url_searchKeywordUser',
                        description => 'helpvar url_searchKeywordUser',
                    },
                ],
            },
        ],
    },

    'help editComment' => {
        title       => 'help editComment title',
        body        => 'help editComment body',
        isa         => [
            { 
                tag         => 'help common',
                namespace   => 'Asset_Photo',
            },
            {
                tag         => 'help commentForm',
                namespace   => 'Asset_Photo',
            },
        ],
        variables => [
            {
                name        => 'errors',
                description => 'helpvar errors',
                variables   => [
                    { 
                        name        => 'error',
                        description => 'helpvar error',
                    },
                ],
            },
        ],
    },

};

1;

