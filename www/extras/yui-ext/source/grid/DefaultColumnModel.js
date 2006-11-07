/*
 * YUI Extensions
 * Copyright(c) 2006, Jack Slocum.
 * 
 * This code is licensed under BSD license. 
 * http://www.opensource.org/licenses/bsd-license.php
 */


/**
 * @class
 * This is the default implementation of a ColumnModel used by the Grid. It defines
 * the columns in the grid.
 * <br>Usage:<br>
 * <pre><code>
 * var sort = YAHOO.ext.grid.DefaultColumnModel.sortTypes;
 * var myColumns = [
	{header: "Ticker", width: 60, sortable: true, sortType: sort.asUCString}, 
	{header: "Company Name", width: 150, sortable: true, sortType: sort.asUCString}, 
	{header: "Market Cap.", width: 100, sortable: true, sortType: sort.asFloat}, 
	{header: "$ Sales", width: 100, sortable: true, sortType: sort.asFloat, renderer: money}, 
	{header: "Employees", width: 100, sortable: true, sortType: sort.asFloat}
 * ];
 * var colModel = new YAHOO.ext.grid.DefaultColumnModel(myColumns);
 * </code></pre>
 * @extends YAHOO.ext.grid.AbstractColumnModel
 * @constructor
*/
YAHOO.ext.grid.DefaultColumnModel = function(config){
	YAHOO.ext.grid.DefaultColumnModel.superclass.constructor.call(this);
    /**
     * The config passed into the constructor
     */
    this.config = config;
    
    /**
     * The width of columns which have no width specified (defaults to 100)
     * @type Number
     */
    this.defaultWidth = 100;
    /**
     * Default sortable of columns which have no sortable specified (defaults to false)
     * @type Boolean
     */
    this.defaultSortable = false;
};
YAHOO.extendX(YAHOO.ext.grid.DefaultColumnModel, YAHOO.ext.grid.AbstractColumnModel);

/**
 * Returns the number of columns.
 * @return {Number}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getColumnCount = function(){
    return this.config.length;
};
    
/**
 * Returns true if the specified column is sortable.
 * @param {Number} col The column index
 * @return {Boolean}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.isSortable = function(col){
    if(typeof this.config[col].sortable == 'undefined'){
        return this.defaultSortable;
    }
    return this.config[col].sortable;
};
    
/**
 * Returns the sorting comparison function defined for the column (defaults to sortTypes.none).
 * @param {Number} col The column index
 * @return {Function}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getSortType = function(col){
    if(!this.dataMap){
        // build a lookup so we don't search every time
        var map = [];
        for(var i = 0, len = this.config.length; i < len; i++){
            map[this.getDataIndex(i)] = i;
        }
        this.dataMap = map;
    }
    col = this.dataMap[col];
    if(!this.config[col].sortType){
        return YAHOO.ext.grid.DefaultColumnModel.sortTypes.none;
    }
    return this.config[col].sortType;
};
    
/**
 * Sets the sorting comparison function for a column.
 * @param {Number} col The column index
 * @param {Function} fn
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setSortType = function(col, fn){
    this.config[col].sortType = fn;
};
    

/**
 * Returns the rendering (formatting) function defined for the column.
 * @param {Number} col The column index
 * @return {Function}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getRenderer = function(col){
    if(!this.config[col].renderer){
        return YAHOO.ext.grid.DefaultColumnModel.defaultRenderer;
    }
    return this.config[col].renderer;
};
    
/**
 * Sets the rendering (formatting) function for a column.
 * @param {Number} col The column index
 * @param {Function} fn
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setRenderer = function(col, fn){
    this.config[col].renderer = fn;
};
    
/**
 * Returns the width for the specified column.
 * @param {Number} col The column index
 * @return {Number}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getColumnWidth = function(col){
    return this.config[col].width || this.defaultWidth;
};
    
/**
 * Sets the width for a column.
 * @param {Number} col The column index
 * @param {Number} width The new width
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setColumnWidth = function(col, width, suppressEvent){
    this.config[col].width = width;
    this.totalWidth = null;
    if(!suppressEvent){
         this.onWidthChange.fireDirect(this, col, width);
    }
};
    
/**
 * Returns the total width of all columns.
 * @param {Boolean} includeHidden True to include hidden column widths
 * @return {Number}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getTotalWidth = function(includeHidden){
    if(!this.totalWidth){
        this.totalWidth = 0;
        for(var i = 0; i < this.config.length; i++){
            if(includeHidden || !this.isHidden(i)){
                this.totalWidth += this.getColumnWidth(i);
            }
        }
    }
    return this.totalWidth;
};
    
/**
 * Returns the header for the specified column.
 * @param {Number} col The column index
 * @return {String}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getColumnHeader = function(col){
    return this.config[col].header;
};
     
/**
 * Sets the header for a column.
 * @param {Number} col The column index
 * @param {String} header The new header
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setColumnHeader = function(col, header){
    this.config[col].header = header;
    this.onHeaderChange.fireDirect(this, col, header);
};
/**
 * Returns the dataIndex for the specified column.
 * @param {Number} col The column index
 * @return {Number}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getDataIndex = function(col){
    if(typeof this.config[col].dataIndex != 'number'){
        return col;
    }
    return this.config[col].dataIndex;
};
     
/**
 * Sets the dataIndex for a column.
 * @param {Number} col The column index
 * @param {Number} dataIndex The new dataIndex
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setDataIndex = function(col, dataIndex){
    this.config[col].dataIndex = dataIndex;
};
/**
 * Returns true if the cell is editable.
 * @param {Number} colIndex The column index
 * @param {Number} rowIndex The row index
 * @return {Boolean}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.isCellEditable = function(colIndex, rowIndex){
    return this.config[colIndex].editable || (typeof this.config[colIndex].editable == 'undefined' && this.config[colIndex].editor);
};

/**
 * Returns the editor defined for the cell/column.
 * @param {Number} colIndex The column index
 * @param {Number} rowIndex The row index
 * @return {Object}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.getCellEditor = function(colIndex, rowIndex){
    return this.config[colIndex].editor;
};
   
/**
 * Sets if a column is editable.
 * @param {Number} col The column index
 * @param {Boolean} editable True if the column is editable
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setEditable = function(col, editable){
    this.config[col].editable = editable;
};


/**
 * Returns true if the column is hidden.
 * @param {Number} colIndex The column index
 * @return {Boolean}
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.isHidden = function(colIndex){
    return this.config[colIndex].hidden;
};
   
/**
 * Sets if a column is hidden.
 * @param {Number} colIndex The column index
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setHidden = function(colIndex, hidden){
    this.config[colIndex].hidden = hidden;
    this.totalWidth = null;
    this.fireHiddenChange(colIndex, hidden);
};

/**
 * Sets the editor for a column.
 * @param {Number} col The column index
 * @param {Object} editor The editor object
 */
YAHOO.ext.grid.DefaultColumnModel.prototype.setEditor = function(col, editor){
    this.config[col].editor = editor;
};


/**
 * Default empty rendering function
 */
YAHOO.ext.grid.DefaultColumnModel.defaultRenderer = function(value){
	if(typeof value == 'string' && value.length < 1){
	    return '&nbsp;';
	}
	return value;
}

/**
 * Defines the default sorting (casting?) comparison functions used when sorting data:
 * <br>&nbsp;&nbsp;sortTypes.none - sorts data as it is without casting or parsing (the default)
 * <br>&nbsp;&nbsp;sortTypes.asUCString - case insensitive string
 * <br>&nbsp;&nbsp;sortTypes.asDate - attempts to parse data as a date
 * <br>&nbsp;&nbsp;sortTypes.asFloat
 * <br>&nbsp;&nbsp;sortTypes.asInt
 */
YAHOO.ext.grid.DefaultColumnModel.sortTypes = {};

YAHOO.ext.grid.DefaultColumnModel.sortTypes.none = function(s) {
	return s;
};

YAHOO.ext.grid.DefaultColumnModel.sortTypes.asUCString = function(s) {
	return String(s).toUpperCase();
};

YAHOO.ext.grid.DefaultColumnModel.sortTypes.asDate = function(s) {
    if(s instanceof Date){
        return s;
    }
	return Date.parse(String(s));
};

YAHOO.ext.grid.DefaultColumnModel.sortTypes.asFloat = function(s) {
	var val = parseFloat(String(s).replace(/,/g, ''));
    if(isNaN(val)) val = 0;
	return val;
};

YAHOO.ext.grid.DefaultColumnModel.sortTypes.asInt = function(s) {
    var val = parseInt(String(s).replace(/,/g, ''));
    if(isNaN(val)) val = 0;
	return val;
};