package WebGUI::i18n::English::Form_DataTable;

use strict; 

our $I18N = { 
	'topicName' => {
		message     => q{DataTable},
		lastUpdated => 0,
	},

    'delete rows' => {
        message     => q{Delete Selected Rows},
        lastUpdated => 0,
        context     => q{Label for button to delete the selected rows},
    },

    'save' => {
        message     => q{Save},
        lastUpdated => 0,
        context     => q{Label for button to Save changes},
    },

    "add row"   => {
        message     => q{Add Row},
        lastUpdated => 0,
        context     => q{Label for button to Add Row to the table},
    },

    "help" => {
        message     => q{Help},
        lastUpdated => 0,
        context     => q{Label for button to open the help dialog},
    },

    "edit schema" => {
        message     => q{Edit Schema},
        lastUpdated => 0,
        context     => q{Label for button to edit the table column configuration},
    },

    "delete confirm" => {
        message     => q{Are you sure you want to delete these rows?},
        lastUpdated => 0,
        context     => q{Message for pop-up to confirm deleting rows from the table},
    },

    "format text" => {
        message     => q{Text},
        lastUpdated => 0,
        context     => q{Format for a plain text column},
    },

    "format email" => {
        message     => q{E-mail},
        lastUpdated => 0,
        context     => q{Format for a column for an e-mail address},
    },

    "format link" => {
        message     => q{URL},
        lastUpdated => 0,
        context     => q{Format for a column for URLs},
    },

    "format number" => {
        message     => q{Number},
        lastUpdated => 0,
        context     => q{Format for a column with numbers},
    },

    "add column" => {
        message     => q{Add Column},
        lastUpdated => 0,
        context     => q{Label for button to add a column},
    },

    "cancel"    => {
        message     => q{Cancel},
        lastUpdated => 0,
        context     => q{Label for button to cancel},
    },

    "ok"        => {
        message     => q{Ok},
        lastUpdated => 0,
        context     => q{Label for button to close an information dialog},
    },

    "save success" => {
        message     => q{Table saved successfully!},
        lastUpdated => 0,
        context     => q{Message shown when the table save succeeds},
    },

    "save failure" => {
        message     => q{Save failed! Please try again.},
        lastUpdated => 0,
        context     => q{Message shown when the table save fails},
    },

    "help edit cell" => {
        message     => q{Double-click a cell to edit the cell. Hitting tab will save the current cell and open the next.},
        lastUpdated => 0,
        context     => q{How to edit a cell. Shown in the help pop-up},
    },

    "help select row" => {
        message     => q{Click on a row to select it. Hold shift or ctrl to select multiple rows.},
        lastUpdated => 0,
        context     => q{How to select a row. Shown in the help pop-up},
    },
    
    "help add row" => {
        message     => q{Clicking Add Row will add a row to the bottom of the table.},
        lastUpdated => 0,
        context     => q{How to add a row. Shown in the help pop-up},
    },

    "help default sort" => {
        message     => q{By default, the table will be sorted exactly as it is when it is saved.},
        lastUpdated => 0,
        context     => q{How to set the default sort. Shown in the help pop-up},
    },

    "help reorder column" => {
        message     => q{Drag and drop columns to reorder them.},
        lastUpdated => 0,
        context     => q{How to reorder columns. Shown in the help pop-up},
    },
};

1;
