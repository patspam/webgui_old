package WebGUI::Help::Asset;
use strict

our $HELP = {

    'asset template' => {
        title     => 'asset template title',
        body      => '',
        variables => [ { name => 'controls', }, ],
        fields    => [],
        related   => []
    },

    'asset template asset variables' => {
        title     => 'asset template asset var title',
        body      => '',
        variables => [
            { name => 'title', },
            { name => 'menuTitle', },
            { name => 'url', },
            { name => 'isHidden', },
            { name => 'newWindow', },
            { name => 'encryptPage', },
            { name => 'ownerUserId', },
            { name => 'groupIdView', },
            { name => 'groupIdEdit', },
            { name => 'synopsis', },
            { name => 'extraHeadTags', },
            { name => 'isPackage', },
            { name => 'isPrototype', },
            { name => 'status', },
            { name => 'assetSize', },
        ],
        fields  => [],
        related => []
    },

};

1;
