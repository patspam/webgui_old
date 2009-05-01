// Really only used by the Template editor, but it doesn't belong in perl
// code.  It's too long.

var addClick = (function() {
    var uniqueId     = 1;
    var count        = 0;
    var urls         = {};
    var types        = {};
    var originals    = {};
    var addAnchor    = document.getElementById('addAnchor');
    var displayTable = document.getElementById('attachmentDisplay');
    
    var nodes = {
        table: '',
        index: 'Index',
        type:  'Type',
        url:   'Url'
    };

    function init() {
        displayTable.style.display = 'none';

        for (var k in nodes) {
            var id = 'addBox' + nodes[k];
            nodes[k] = document.getElementById(id);
        }

        var opts = nodes.type.options;
        for (var i = 0; i < opts.length; i++) {
            var o = opts[i];
            types[o.value] = o.text;
        }

        var query = YAHOO.util.Dom.getElementsByClassName;
        var existing = query('existingAttachment', 'tr');
        for (var i = 0; i < existing.length; i++) {
            var node = existing[i];
            var d = {
                index: query('index', 'td', node)[0].innerHTML,
                type:  query('type',  'td', node)[0].innerHTML,
                url:   query('url',   'td', node)[0].innerHTML
            };
            originals[d.url] = true;
            add(d);
            node.parentNode.removeChild(node);
        }
    }

    // When an original box gets changed, we should insert a removal node and
    // name the fields so that we remove the old and insert the new.
    function updater(u) {
        return function() {
            obj = urls[u];
            obj.index.onchange = null;
            obj.type.onchange  = null;
            insertHidden(u);
            nameFields(u);
        };
    }

    // Give the fields for an attachment entry some names so that they'll get
    // posted to the backend.
    function nameFields(u) {
        var id     = uniqueId++;
        var obj    = urls[u];
        obj.index.name = 'attachmentIndex' + id;
        obj.type.name  = 'attachmentType'  + id;
        obj.url.name   = 'attachmentUrl'   + id;
    }

    // Insert a hidden input field in the form so that the backend knows to
    // remove one of the original attachments
    function insertHidden(u) {
        var tr    = urls[u].tr;
        var hid   = document.createElement('input');
        hid.type  = 'hidden';
        hid.name  = 'removeAttachment';
        hid.value = u;
        tr.parentNode.appendChild(hid);
        delete originals[u];
    }

    // Make a function which will remove an attachment (remove the table row
    // and insertHidden if necesary)
    function remover(u) {
        return function() {
            var tr = urls[u].tr;

            if (originals[u]) {
                insertHidden(u);
            }

            tr.parentNode.removeChild(tr);
            delete urls[u];

            if (--count == 0) {
                displayTable.style.display = 'none';
            }
        }
    }

    // Add a new attachment (proper table row, etc).  Attachments that already
    // existed (originals) will have unnamed fields so they don't get posted
    // to the backend.
    function add(d) {
        if (urls[d.url]) {
            alert('Already attached!');
            return;
        }

        if (++count == 1) {
            displayTable.style.display = 'block'; 
        }

        var index   = document.createElement('input');
        index.size  = 2;
        index.value = d.index;

        var type  = document.createElement('select');

        for (var k in types) {
            var o = document.createElement('option');
            o.value = k;
            o.text  = types[k];
            if (k == d.type) {
                o.selected = true;
            }
            type.appendChild(o);
        }

        var url  = document.createElement('input');
        url.size = 40;

        var update   = updater(d.url);
        url.value    = d.url;
        url.oldValue = d.url;
        url.onchange = function() {
            var newValue = url.value;
            var oldValue = url.oldValue;
            if (urls[newValue]) {
                url.value = oldValue;
                alert('Already attached!');
            }
            else {
                url.oldValue = newValue;
                var d = urls[oldValue];
                if (originals[oldValue]) {
                    update();
                }

                delete urls[oldValue];
                urls[newValue] = d;
            }
        };

        var btn     = document.createElement('input');
        btn.type    = 'button';
        btn.value   = 'Remove';
        btn.onclick = remover(d.url);

        var tr   = document.createElement('tr');
        var data = [index, type, url, btn];
        for (var i = 0; i < data.length; i++) {
            var td = document.createElement('td');
            td.appendChild(data[i]);
            tr.appendChild(td);
        }

        urls[d.url] = {
            tr    : tr,
            index : index,
            type  : type,
            url   : url,
        };

        if (originals[d.url]) {
            // url's is already taken care of above
            index.onchange = update;
            type.onchange  = update;
        }
        else {
            nameFields(d.url);
        }

        addAnchor.appendChild(tr);
    }

    init();
    return function() {
        var d = {
            index: nodes.index.value,
            type:  nodes.type.value,
            url:   nodes.url.value
        };

        d.url = d.url.replace(/^\s+|\s+$/g, '')
        if (d.url == '') {
            alert('No url!');
            return;
        }
        add(d);
    };
})();
