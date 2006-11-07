/*
 * YUI Extensions
 * Copyright(c) 2006, Jack Slocum.
 * 
 * This code is licensed under BSD license. 
 * http://www.opensource.org/licenses/bsd-license.php
 */

/**
 * @class
 * Default UI code used internally by the Grid. Documentation to come.
 * @constructor
 */
YAHOO.ext.grid.GridView = function(){
	/** @private */
	this.grid = null;
	
	/** @private */
	this.lastFocusedRow = null;
	/**
	 * Fires when the ViewPort is scrolled - fireDirect sig: (this, scrollLeft, scrollTop)
	 * @type YAHOO.util.CustomEvent
	 * @deprecated
	 */
	this.onScroll = new YAHOO.util.CustomEvent('onscroll');
	
	/**
	 * @private
	 */
	this.adjustScrollTask = new YAHOO.ext.util.DelayedTask(this._adjustForScroll, this);
	/**
	 * @private
	 */
	this.ensureVisibleTask = new YAHOO.ext.util.DelayedTask();
};

YAHOO.ext.grid.GridView.prototype = {
	init: function(grid){
		this.grid = grid;
	},
	
	fireScroll: function(scrollLeft, scrollTop){
		this.onScroll.fireDirect(this.grid, scrollLeft, scrollTop);
	},
	
	/**
	 * Utility method that gets an array of the cell renderers
	 */
	getColumnRenderers : function(){
    	var renderers = [];
    	var cm = this.grid.colModel;
        var colCount = cm.getColumnCount();
        for(var i = 0; i < colCount; i++){
            renderers.push(cm.getRenderer(i));
        }
        return renderers;
    },
    
    buildIndexMap : function(){
        var colToData = {};
        var dataToCol = {};
        var cm = this.grid.colModel;
        for(var i = 0, len = cm.getColumnCount(); i < len; i++){
            var di = cm.getDataIndex(i);
            colToData[i] = di;
            dataToCol[di] = i;
        }
        return {'colToData': colToData, 'dataToCol': dataToCol};
    },
    
    getDataIndexes : function(){
    	if(!this.indexMap){
            this.indexMap = this.buildIndexMap();
        }
        return this.indexMap.colToData;
    },
    
    getColumnIndexByDataIndex : function(dataIndex){
        if(!this.indexMap){
            this.indexMap = this.buildIndexMap();
        }
    	return this.indexMap.dataToCol[dataIndex];
    },
    
    updateHeaders : function(){
        var colModel = this.grid.colModel;
        var hcells = this.headers;
        var colCount = colModel.getColumnCount();
        for(var i = 0; i < colCount; i++){
            hcells[i].textNode.innerHTML = colModel.getColumnHeader(i);
        }
    },
    
    adjustForScroll : function(disableDelay){
        if(!disableDelay){
            this.adjustScrollTask.delay(50);
        }else{
            this._adjustForScroll();
        }
    },
    
    getCellAtPoint : function(x, y){
        var colIndex = null;        
        var rowIndex = null;
        
        // translate page coordinates to local coordinates
        var xy = YAHOO.util.Dom.getXY(this.wrap);
        x = (x - xy[0]) + this.wrap.scrollLeft;
        y = (y - xy[1]) + this.wrap.scrollTop;
        
        var colModel = this.grid.colModel;
        var pos = 0;
        var colCount = colModel.getColumnCount();
        for(var i = 0; i < colCount; i++){
            if(colModel.isHidden(i)) continue;
            var width = colModel.getColumnWidth(i);
            if(x >= pos && x < pos+width){
                colIndex = i;
                break;
            }
            pos += width;
        }
        if(colIndex != null){
            rowIndex = (y == 0 ? 0 : Math.floor(y / this.getRowHeight()));
            if(rowIndex >= this.grid.dataModel.getRowCount()){
                return null;
            }
            return [colIndex, rowIndex];
        }
        return null;
    },
    
    /** @private */
    _adjustForScroll : function(){
        this.forceScrollUpdate();
        if(this.scrollbarMode == YAHOO.ext.grid.GridView.SCROLLBARS_OVERLAP){
            var adjustment = 0;
            if(this.wrap.clientWidth && this.wrap.clientWidth != 0){
                adjustment = this.wrap.offsetWidth - this.wrap.clientWidth;
            }
            this.hwrap.setWidth(this.wrap.offsetWidth-adjustment);
        }else{
            this.hwrap.setWidth(this.wrap.offsetWidth);
        }
        this.bwrap.setWidth(Math.max(this.grid.colModel.getTotalWidth(), this.wrap.clientWidth));
    },

    focusRow : function(row){
        if(typeof row == 'number'){
            row = this.getBodyTable().childNodes[row];
        }
        if(!row) return;
    	var left = this.wrap.scrollLeft;
    	try{ // try catch for IE occasional focus bug
    	    row.childNodes.item(0).hideFocus = true;
        	row.childNodes.item(0).focus();
        }catch(e){}
        this.ensureVisible(row);
        this.wrap.scrollLeft = left;
        this.handleScroll();
        this.lastFocusedRow = row;
    },

    ensureVisible : function(row, disableDelay){
        if(!disableDelay){
            this.ensureVisibleTask.delay(50, this._ensureVisible, this, [row]);
        }else{
            this._ensureVisible(row);
        }
    },

    /** @ignore */
    _ensureVisible : function(row){
        if(typeof row == 'number'){
            row = this.getBodyTable().childNodes[row];
        }
        if(!row) return;
    	var left = this.wrap.scrollLeft;
    	var rowTop = parseInt(row.offsetTop, 10); // parseInt for safari bug
        var rowBottom = rowTop + row.offsetHeight;
        var clientTop = parseInt(this.wrap.scrollTop, 10); // parseInt for safari bug
        var clientBottom = clientTop + this.wrap.clientHeight;
        if(rowTop < clientTop){
        	this.wrap.scrollTop = rowTop;
        }else if(rowBottom > clientBottom){
            this.wrap.scrollTop = rowBottom-this.wrap.clientHeight;
        }
        this.wrap.scrollLeft = left;
        this.handleScroll();
    },
    
    updateColumns : function(){
        this.grid.stopEditing();
        var colModel = this.grid.colModel;
        var hcols = this.headers;
        var colCount = colModel.getColumnCount();
        var pos = 0;
        var totalWidth = colModel.getTotalWidth();
        for(var i = 0; i < colCount; i++){
            if(colModel.isHidden(i)) continue;
            var width = colModel.getColumnWidth(i);
            hcols[i].style.width = width + 'px';
            hcols[i].style.left = pos + 'px';
            hcols[i].split.style.left = (pos+width-3) + 'px';
            this.setCSSWidth(i, width, pos);
            pos += width;
        }
        this.lastWidth = totalWidth;
        this.bwrap.setWidth(Math.max(totalWidth, this.wrap.clientWidth));
        if(!YAHOO.ext.util.Browser.isIE){ // fix scrolling prob in gecko and opera
        	this.wrap.scrollLeft = this.hwrap.dom.scrollLeft;
        }
        this.syncScroll();
        this.forceScrollUpdate();
    },
    
    setCSSWidth : function(colIndex, width, pos){
        var selector = ["#" + this.grid.id + " .ygrid-col-" + colIndex, ".ygrid-col-" + colIndex];
        YAHOO.ext.util.CSS.updateRule(selector, 'width', width + 'px');
        if(typeof pos == 'number'){
            YAHOO.ext.util.CSS.updateRule(selector, 'left', pos + 'px');
        }
    },
    
    handleHiddenChange : function(colModel, colIndex, hidden){
        if(hidden){
            this.hideColumn(colIndex);
        }else{
            this.unhideColumn(colIndex);
        }
        this.updateColumns();
    },
    
    hideColumn : function(colIndex){
        var selector = ["#" + this.grid.id + " .ygrid-col-" + colIndex, ".ygrid-col-" + colIndex];
        YAHOO.ext.util.CSS.updateRule(selector, 'position', 'absolute');
        YAHOO.ext.util.CSS.updateRule(selector, 'visibility', 'hidden');
        
        this.headers[colIndex].style.display = 'none';
        this.headers[colIndex].split.style.display = 'none';
    },
    
    unhideColumn : function(colIndex){
        var selector = ["#" + this.grid.id + " .ygrid-col-" + colIndex, ".ygrid-col-" + colIndex];
        YAHOO.ext.util.CSS.updateRule(selector, 'position', '');
        YAHOO.ext.util.CSS.updateRule(selector, 'visibility', 'visible');
        
        this.headers[colIndex].style.display = '';
        this.headers[colIndex].split.style.display = '';
    },
    
    getBodyTable : function(){
    	return this.bwrap.dom;
    },
    
    updateRowIndexes : function(firstRow, lastRow){
        var stripeRows = this.grid.stripeRows;
        var bt = this.getBodyTable();
        var nodes = bt.childNodes;
        firstRow = firstRow || 0;
        lastRow = lastRow || nodes.length-1;
        var re = /^(?:ygrid-row ygrid-row-alt|ygrid-row)/;
        for(var rowIndex = firstRow; rowIndex <= lastRow; rowIndex++){
            var node = nodes[rowIndex];
            if(stripeRows && (rowIndex+1) % 2 == 0){
        		node.className = node.className.replace(re, 'ygrid-row ygrid-row-alt');
        	}else{
        		node.className = node.className.replace(re, 'ygrid-row');
        	}
            node.rowIndex = rowIndex;
            nodes[rowIndex].style.top = (rowIndex * this.rowHeight) + 'px';
        }
    },

    insertRows : function(dataModel, firstRow, lastRow){
        this.updateBodyHeight();
        this.adjustForScroll(true);
        var renderers = this.getColumnRenderers();
        var dindexes = this.getDataIndexes();
        var colCount = this.grid.colModel.getColumnCount();
        var beforeRow = null;
        var bt = this.getBodyTable();
        if(firstRow < bt.childNodes.length){
            beforeRow = bt.childNodes[firstRow];
        }
        for(var rowIndex = firstRow; rowIndex <= lastRow; rowIndex++){
            var row = document.createElement('span');
            row.className = 'ygrid-row';
            row.style.top = (rowIndex * this.rowHeight) + 'px';
            this.renderRow(dataModel, row, rowIndex, colCount, renderers, dindexes);
            if(beforeRow){
            	bt.insertBefore(row, beforeRow);
            }else{
                bt.appendChild(row);
            }
        }
        this.updateRowIndexes(firstRow);
        this.adjustForScroll();
    },
    
    renderRow : function(dataModel, row, rowIndex, colCount, renderers, dindexes){
        for(var colIndex = 0; colIndex < colCount; colIndex++){
            var td = document.createElement('span');
            td.className = 'ygrid-col ygrid-col-' + colIndex + (colIndex == colCount-1 ? ' ygrid-col-last' : '');
            td.columnIndex = colIndex;
            td.tabIndex = 0;
            var span = document.createElement('span');
            span.className = 'ygrid-cell-text';
            td.appendChild(span);
            var val = renderers[colIndex](dataModel.getValueAt(rowIndex, dindexes[colIndex]), rowIndex, colIndex);
            if(val == '') val = '&nbsp;';
            span.innerHTML = val;
            row.appendChild(td);
        }
    },
    
    deleteRows : function(dataModel, firstRow, lastRow){
        this.updateBodyHeight();
        // first make sure they are deselected
        this.grid.selModel.deselectRange(firstRow, lastRow);
        var bt = this.getBodyTable();
        var rows = []; // get references because the rowIndex will change
        for(var rowIndex = firstRow; rowIndex <= lastRow; rowIndex++){
            rows.push(bt.childNodes[rowIndex]);
        }
        for(var i = 0; i < rows.length; i++){
            bt.removeChild(rows[i]);
            rows[i] = null;
        }
        rows = null;
        this.updateRowIndexes(firstRow);
        this.adjustForScroll();
    },
    
    updateRows : function(dataModel, firstRow, lastRow){
        var bt = this.getBodyTable();
        var dindexes = this.getDataIndexes();
        var renderers = this.getColumnRenderers();
        var colCount = this.grid.colModel.getColumnCount();
        for(var rowIndex = firstRow; rowIndex <= lastRow; rowIndex++){
            var row = bt.rows[rowIndex];
            var cells = row.childNodes;
            for(var colIndex = 0; colIndex < colCount; colIndex++){
                var td = cells[colIndex];
                var val = renderers[colIndex](dataModel.getValueAt(rowIndex, dindexes[colIndex]), rowIndex, colIndex);
                if(val == '') val = '&nbsp;';
                td.firstChild.innerHTML = val;
            }
        }
    },
    
    handleSort : function(dataModel, sortColumnIndex, sortDir, noRefresh){
        this.grid.selModel.syncSelectionsToIds();
        if(!noRefresh){
           this.updateRows(dataModel, 0, dataModel.getRowCount()-1);
        }
        this.updateHeaderSortState();
        if(this.lastFocusedRow){
            this.focusRow(this.lastFocusedRow);
        }
    },
    
    syncScroll : function(){
        this.hwrap.dom.scrollLeft = this.wrap.scrollLeft;
    },
    
    handleScroll : function(){
        this.syncScroll();
        this.fireScroll(this.wrap.scrollLeft, this.wrap.scrollTop);
        this.grid.fireEvent('bodyscroll', this.wrap.scrollLeft, this.wrap.scrollTop);
    },
    
    getRowHeight : function(){
        if(!this.rowHeight){
            var rule = YAHOO.ext.util.CSS.getRule(["#" + this.grid.id + " .ygrid-row", ".ygrid-row"]);
        	if(rule && rule.style.height){
        	    this.rowHeight = parseInt(rule.style.height, 10);
        	}else{
        	    this.rowHeight = 21;
        	}
        }
        return this.rowHeight;
    },
    
    renderRows : function(dataModel){
        if(this.grid.selModel){
            this.grid.selModel.clearSelections();
        }
    	var bt = this.getBodyTable();
    	bt.innerHTML = '';
    	this.rowHeight = this.getRowHeight();
    	this.insertRows(dataModel, 0, dataModel.getRowCount()-1);
    },
    
    updateCell : function(dataModel, rowIndex, dataIndex){
        var colIndex = this.getColumnIndexByDataIndex(dataIndex);
        if(typeof colIndex == 'undefined'){ // not present in grid
            return;
        }
        var bt = this.getBodyTable();
        var row = bt.childNodes[rowIndex];
        var cell = row.childNodes[colIndex];
        var renderer = this.grid.colModel.getRenderer(colIndex);
        var val = renderer(dataModel.getValueAt(rowIndex, dataIndex), rowIndex, colIndex);
        if(val == '') val = '&nbsp;';
        cell.firstChild.innerHTML = val;
    },
    
    calcColumnWidth : function(colIndex, maxRowsToMeasure){
        var maxWidth = 0;
        var bt = this.getBodyTable();
        var rows = bt.childNodes;
        var stopIndex = Math.min(maxRowsToMeasure || rows.length, rows.length);
        if(this.grid.autoSizeHeaders){
            var h = this.headers[colIndex];
            var curWidth = h.style.width;
            h.style.width = this.grid.minColumnWidth+'px';
            maxWidth = Math.max(maxWidth, h.scrollWidth);
            h.style.width = curWidth;
        }
        for(var i = 0; i < stopIndex; i++){
            var cell = rows[i].childNodes[colIndex].firstChild;
            maxWidth = Math.max(maxWidth, cell.scrollWidth);
        }
        return maxWidth + /*margin for error in IE*/ 5;
    },
    
    autoSizeColumn : function(colIndex, forceMinSize){
        if(forceMinSize){
           this.setCSSWidth(colIndex, this.grid.minColumnWidth);
        }
        var newWidth = this.calcColumnWidth(colIndex);
        this.grid.colModel.setColumnWidth(colIndex,
            Math.max(this.grid.minColumnWidth, newWidth));
        this.grid.fireEvent('columnresize', colIndex, newWidth);
    },
    
    autoSizeColumns : function(){
        var colModel = this.grid.colModel;
        var colCount = colModel.getColumnCount();
        var wrap = this.wrap;
        for(var i = 0; i < colCount; i++){
            this.setCSSWidth(i, this.grid.minColumnWidth);
            colModel.setColumnWidth(i, this.calcColumnWidth(i, this.grid.maxRowsToMeasure), true);
        }
        if(colModel.getTotalWidth() < wrap.clientWidth){
            var diff = Math.floor((wrap.clientWidth - colModel.getTotalWidth()) / colCount);
            for(var i = 0; i < colCount; i++){
                colModel.setColumnWidth(i, colModel.getColumnWidth(i) + diff, true);
            }
        }
        this.updateColumns();  
    },
    
    onWindowResize : function(){
        if(this.grid.monitorWindowResize){
            this.updateWrapHeight();
            this.adjustForScroll();
        }  
    },
    
    updateWrapHeight : function(){
        this.grid.container.beginMeasure();
        var box = this.grid.container.getBox(true);
        this.wrapEl.setHeight(box.height-this.footerHeight-parseInt(this.wrap.offsetTop, 10));
        this.grid.container.endMeasure();
    },
    
    forceScrollUpdate : function(){
        var wrap = this.wrap;
        YAHOO.util.Dom.setStyle(wrap, 'width', (wrap.offsetWidth) +'px');
        setTimeout(function(){ // set timeout so FireFox works
            YAHOO.util.Dom.setStyle(wrap, 'width', '');
        }, 1);
    },
    
    updateHeaderSortState : function(){
        var state = this.grid.dataModel.getSortState();
        var sortColumn = this.getColumnIndexByDataIndex(state.column);
        var sortDir = state.direction;
        for(var i = 0, len = this.headers.length; i < len; i++){
            var h = this.headers[i];
            if(i != sortColumn){
                h.sortDesc.style.display = 'none';
                h.sortAsc.style.display = 'none';
            }else{
                h.sortDesc.style.display = sortDir == 'DESC' ? 'block' : 'none';
                h.sortAsc.style.display = sortDir == 'ASC' ? 'block' : 'none';
            }
        }
    },

    render : function(){
        var grid = this.grid;
        var container = grid.container.dom;
        var dataModel = grid.dataModel;
        dataModel.onCellUpdated.subscribe(this.updateCell, this, true);
        dataModel.onTableDataChanged.subscribe(this.renderRows, this, true);
        dataModel.onRowsDeleted.subscribe(this.deleteRows, this, true);
        dataModel.onRowsInserted.subscribe(this.insertRows, this, true);
        dataModel.onRowsUpdated.subscribe(this.updateRows, this, true);
        dataModel.onRowsSorted.subscribe(this.handleSort, this, true);
    
        var colModel = grid.colModel;
        colModel.onWidthChange.subscribe(this.updateColumns, this, true);
        colModel.onHeaderChange.subscribe(this.updateHeaders, this, true);
        colModel.onHiddenChange.subscribe(this.handleHiddenChange, this, true);
        
        YAHOO.util.Event.on(window, 'resize', this.onWindowResize, this, true);
        
        var autoSizeDelegate = this.autoSizeColumn.createDelegate(this);
        
        var colCount = colModel.getColumnCount();
    
        var dh = YAHOO.ext.DomHelper;
        //create wrapper elements that handle offsets and scrolling
        var wrap = dh.append(container, {tag: 'div', cls: 'ygrid-wrap'});
        this.wrap = wrap;
        this.wrapEl = getEl(wrap, true);
        YAHOO.ext.EventManager.on(wrap, 'scroll', this.handleScroll, this, true);
        
        var hwrap = dh.append(container, {tag: 'div', cls: 'ygrid-wrap-headers'});
        this.hwrap = getEl(hwrap, true);
        
        var bwrap = dh.append(wrap, {tag: 'div', cls: 'ygrid-wrap-body', id: container.id + '-body'});
        this.bwrap = getEl(bwrap, true);
        this.bwrap.setWidth(colModel.getTotalWidth());
        bwrap.rows = bwrap.childNodes;
        
        this.footerHeight = 0;
        var foot = this.appendFooter(container);
        if(foot){
            this.footer = getEl(foot, true);
            this.footerHeight = this.footer.getHeight();
        }
        this.updateWrapHeight();
        
        var hrow = dh.append(hwrap, {tag: 'span', cls: 'ygrid-hrow'});
        this.hrow = hrow;
        
        // IE doesn't like iframes, we will leave this alone
        var iframe = document.createElement('iframe');
        iframe.className = 'ygrid-hrow-frame';
        iframe.frameBorder = 0;
        hwrap.appendChild(iframe);
        
        this.headerCtrl = new YAHOO.ext.grid.HeaderController(this.grid);
        this.headers = [];
        this.cols = [];
        
        
        
        var htemplate = dh.createTemplate({
           tag: 'span', cls: 'ygrid-hd ygrid-header-{0}', children: [{
                tag: 'span', 
                cls: 'ygrid-hd-body', 
                html: '<table border="0" cellpadding="0" cellspacing="0">' +
                      '<tbody><tr><td><span>{1}</span></td>' +
                      '<td><span class="sort-desc"></span><span class="sort-asc"></span></td>' +
                      '</tr></tbody></table>'
           }]           
        });
        htemplate.compile();
        for(var i = 0; i < colCount; i++){
            var hd = htemplate.append(hrow, [i, colModel.getColumnHeader(i)]);
            var spans = hd.getElementsByTagName('span');
            hd.textNode = spans[1];
            hd.sortDesc = spans[2];
    	    hd.sortAsc = spans[3];
    	    hd.columnIndex = i;
            this.headers.push(hd);
            if(colModel.isSortable(i)){
                this.headerCtrl.register(hd);
            }
            var split = dh.append(hrow, {tag: 'span', cls: 'ygrid-hd-split'});
            hd.split = split;
        	
        	YAHOO.util.Event.on(split, 'dblclick', autoSizeDelegate.createCallback(i+0, true));
        	
        	var sb = new YAHOO.ext.SplitBar(split, hd, null, YAHOO.ext.SplitBar.LEFT);
        	sb.columnIndex = i;
        	sb.minSize = grid.minColumnWidth;
        	sb.onMoved.subscribe(this.onColumnSplitterMoved, this, true);
        	YAHOO.util.Dom.addClass(sb.proxy, 'ygrid-column-sizer');
        	YAHOO.util.Dom.setStyle(sb.proxy, 'background-color', '');
        	sb.dd._resizeProxy = function(){
        	    var el = this.getDragEl();
        	    YAHOO.util.Dom.setStyle(el, 'height', (hwrap.clientHeight+wrap.clientHeight-2) +'px');
        	};
        }
        if(grid.autoSizeColumns){
            this.renderRows(dataModel);
            this.autoSizeColumns();
        }else{
            this.updateColumns();
            this.renderRows(dataModel);
        }
        
        for(var i = 0; i < colCount; i++){
            if(colModel.isHidden(i)){
                this.hideColumn(i);
            }
        }
        return this.bwrap;
        
        /*
        // Old DOM code
        //create wrapper elements that handle offsets and scrolling
        var wrap = document.createElement('div');
        wrap.className = 'ygrid-wrap';
        grid.container.dom.appendChild(wrap);
        this.wrap = wrap;
        this.wrapEl = getEl(wrap, true);
        YAHOO.ext.EventManager.on(wrap, 'scroll', this.handleScroll, this, true);
        
        var hwrap = document.createElement('div');
        hwrap.className = 'ygrid-wrap-headers';
        grid.container.dom.appendChild(hwrap);
        this.hwrap = getEl(hwrap, true);
        //this.hwrap.setWidth(colModel.getTotalWidth());
        
        var bwrap = document.createElement('div');
        bwrap.id = grid.container.id + '-body';
        bwrap.className = 'ygrid-wrap-body';
        wrap.appendChild(bwrap);
        this.bwrap = getEl(bwrap, true);
        this.bwrap.setWidth(colModel.getTotalWidth());
        bwrap.rows = bwrap.childNodes;
        
        this.footerHeight = 0;
        var foot = this.appendFooter(grid.container.dom);
        if(foot){
            this.footer = getEl(foot, true);
            this.footerHeight = this.footer.getHeight();
        }
        this.updateWrapHeight();
        
        var hrow = document.createElement('span');
        hrow.className = 'ygrid-hrow';
        hwrap.appendChild(hrow);
        var iframe = document.createElement('iframe');
        iframe.className = 'ygrid-hrow-frame';
        iframe.frameBorder = 0;
        hwrap.appendChild(iframe);
        this.hrow = hrow;
        this.headerCtrl = new YAHOO.ext.grid.HeaderController(this.grid);
        this.headers = [];
        this.cols = [];
        for(var i = 0; i < colCount; i++){
            var hd = document.createElement('span');
        	hd.className = 'ygrid-hd ygrid-header-' + i;
        	var span = document.createElement('span');
            span.className = 'ygrid-hd-body';
            hd.appendChild(span);
            var tb = document.createElement('table');
            span.appendChild(tb);
            tb.border = 0;
            tb.cellPadding=0;
            tb.cellSpacing = 0;
            var tbody = document.createElement('tbody');
            tb.appendChild(tbody);
            var tr = document.createElement('tr');
            tbody.appendChild(tr);
            var td = document.createElement('td');
            tr.appendChild(td);
            var td2 = document.createElement('td');
            tr.appendChild(td2);
            var text = document.createElement('span');
            text.innerHTML = colModel.getColumnHeader(i);
            td.appendChild(text);
            hd.textNode = text;
            hd.sortDesc = document.createElement('span');
    	    hd.sortDesc.className = 'sort-desc';
    	    hd.sortAsc = document.createElement('span');
    	    hd.sortAsc.className = 'sort-asc';
            td2.appendChild(hd.sortDesc);
    	    td2.appendChild(hd.sortAsc);
    	    hrow.appendChild(hd)
            hd.columnIndex = i;
            this.headers.push(hd);
            if(colModel.isSortable(i)){
                this.headerCtrl.register(hd);
            }
            var split = document.createElement('span');
        	split.className = 'ygrid-hd-split';
        	hrow.appendChild(split);
        	hd.split = split;
        	
        	YAHOO.util.Event.on(split, 'dblclick', autoSizeDelegate.createCallback(i+0, true));
        	
        	var sb = new YAHOO.ext.SplitBar(split, hd, null, YAHOO.ext.SplitBar.LEFT);
        	sb.columnIndex = i;
        	sb.minSize = grid.minColumnWidth;
        	// anonymous function = bad? 
        	sb.onMoved.subscribe(function(splitter, newSize){
        		colModel.setColumnWidth(splitter.columnIndex, newSize);
        		grid.fireEvent('columnresize', splitter.columnIndex, newSize);
        	});
        	YAHOO.util.Dom.addClass(sb.proxy, 'ygrid-column-sizer');
        	YAHOO.util.Dom.setStyle(sb.proxy, 'background-color', '');
        	sb.dd._resizeProxy = function(){
        	    var el = this.getDragEl();
        	    YAHOO.util.Dom.setStyle(el, 'height', (hwrap.clientHeight+wrap.clientHeight-2) +'px');
        	};
        }
        if(grid.autoSizeColumns){
            this.renderRows(dataModel);
            this.autoSizeColumns();
        }else{
            this.updateColumns();
            this.renderRows(dataModel);
        }
        
        for(var i = 0; i < colCount; i++){
            if(colModel.isHidden(i)){
                this.hideColumn(i);
            }
        }
        return this.bwrap;*/
    },
    
    onColumnSplitterMoved : function(splitter, newSize){
        this.grid.colModel.setColumnWidth(splitter.columnIndex, newSize);
        this.grid.fireEvent('columnresize', splitter.columnIndex, newSize);
    },
    
    appendFooter : function(parentEl){
        return null;  
    },
    
    updateBodyHeight : function(){
        YAHOO.util.Dom.setStyle(this.getBodyTable(), 'height', 
                             (this.grid.dataModel.getRowCount()*this.rowHeight)+'px');
    }
};
YAHOO.ext.grid.GridView.SCROLLBARS_UNDER = 0;
YAHOO.ext.grid.GridView.SCROLLBARS_OVERLAP = 1;
YAHOO.ext.grid.GridView.prototype.scrollbarMode = YAHOO.ext.grid.GridView.SCROLLBARS_UNDER;

/**
 * @class
 * Used internal by GridView to route header related events.
 * @constructor
 */
YAHOO.ext.grid.HeaderController = function(grid){
	/** @private */
	this.grid = grid;
	/** @private */
	this.headers = [];
};

YAHOO.ext.grid.HeaderController.prototype = {
	register : function(header){
		this.headers.push(header);
		YAHOO.ext.EventManager.on(header, 'selectstart', this.cancelTextSelection, this, true);
        YAHOO.ext.EventManager.on(header, 'mousedown', this.cancelTextSelection, this, true);
        YAHOO.ext.EventManager.on(header, 'mouseover', this.headerOver, this, true);
        YAHOO.ext.EventManager.on(header, 'mouseout', this.headerOut, this, true);
        YAHOO.ext.EventManager.on(header, 'click', this.headerClick, this, true);
	},
	
	headerClick : function(e){
	    var grid = this.grid, cm = grid.colModel, dm = grid.dataModel;
	    grid.stopEditing();
        var header = grid.getHeaderFromChild(e.getTarget());
        var direction = header.sortDir || 'ASC';
        var state = dm.getSortState();
        if(typeof state.column != 'undefined' && 
                 grid.getView().getColumnIndexByDataIndex(state.column) == header.columnIndex){
            direction = (direction == 'ASC' ? 'DESC' : 'ASC');
        }
        header.sortDir = direction;
        dm.sort(cm, cm.getDataIndex(header.columnIndex), direction);
    },
    
    headerOver : function(e){
        var header = this.grid.getHeaderFromChild(e.getTarget());
        YAHOO.util.Dom.addClass(header, 'ygrid-hd-over');
        //YAHOO.ext.util.CSS.applyFirst(header, this.grid.id, '.ygrid-hd-over');
    },
    
    headerOut : function(e){
        var header = this.grid.getHeaderFromChild(e.getTarget());
        YAHOO.util.Dom.removeClass(header, 'ygrid-hd-over');
        //YAHOO.ext.util.CSS.revertFirst(header, this.grid.id, '.ygrid-hd-over');
    },
    
    cancelTextSelection : function(e){
    	e.preventDefault();
    }
};