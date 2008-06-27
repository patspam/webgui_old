package WebGUI::i18n::English::Asset_FlatDiscount;

use strict;

our $I18N = { 
	'add to cart' => {
		message 	=> q|Add To Cart|,
		lastUpdated => 0,
        context 	=> q|a button label|
	},

	'template' => {
		message 	=> q|Template|,
		lastUpdated => 0,
        context 	=> q|a property label|
	},

	'template help' => {
		message 	=> q|Choose the template you wish to use to display this coupon.|,
		lastUpdated => 0,
        context 	=> q|help for a property label|
	},

	'must spend' => {
		message 	=> q|Must Spend|,
		lastUpdated => 0,
        context 	=> q|a property label|
	},

	'must spend help' => {
		message 	=> q|How much must a visitor spend in this transaction for the discount to be applied?|,
		lastUpdated => 0,
        context 	=> q|help for a property label|
	},

	'percentage discount' => {
		message 	=> q|Percentage Discount|,
		lastUpdated => 0,
        context 	=> q|a property label|
	},

	'percentage discount help' => {
		message 	=> q|What percentage of the price will be subtracted by this coupon?|,
		lastUpdated => 0,
        context 	=> q|help for a property label|
	},

	'price discount' => {
		message 	=> q|Price Discount|,
		lastUpdated => 0,
        context 	=> q|a property label|
	},

	'price discount help' => {
		message 	=> q|What flat amount should be subtracted by this coupon?|,
		lastUpdated => 0,
        context 	=> q|help for a property label|
	},

	'flat discount coupon template' => {
		message 	=> q|Flat Discount Coupon Template|,
		lastUpdated => 0,
        context 	=> q|a help label|
	},

	'flat discount coupon template help' => {
		message 	=> q|The following template variables are available for this asset.|,
		lastUpdated => 0,
        context 	=> q|help for a help label|
	},

	'assetName' => {
		message 	=> q|Flat Discount Coupon|,
		lastUpdated => 0,
        context 	=> q|The name of this asset.|
	},

	'formHeader' => {
		message 	=> q|The top of the form.|,
		lastUpdated => 0,
        context 	=> q|template variable description|
	},

	'formFooter' => {
		message 	=> q|The bottom of the form.|,
		lastUpdated => 0,
        context 	=> q|template variable description|
	},

	'addToCartButton' => {
		message 	=> q|A submit button with 'add to cart' written on it.|,
		lastUpdated => 0,
        context 	=> q|template variable description|
	},

	'thank you message' => {
		message => q|Thank you message|,
		lastUpdated => 0,
		context => q|help for default price field|
	},

	'thank you message help' => {
		message => q|Write a "thank you message", this could also just be a notice that something was added to the cart.|,
		lastUpdated => 0,
		context => q|help for default price field|
	},

	'default thank you message' => {
		message => q|The coupon has been added to the cart.|,
		lastUpdated => 0,
		context => q|help for default price field|
	},

	'hasAddedToCart' => {
		message => q|A conditional indicating that the user has added the product to their cart, so we can display the thank you message.|,
		lastUpdated => 1214598286,
		context => q|template variable|
	},

	'alreadyHasCoupon' => {
		message => q|A conditional indicating that the user already has this coupon in their cart.|,
		lastUpdated => 0,
		context => q|template variable|
	},

};

1;
