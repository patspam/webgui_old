package WebGUI::i18n::English::PayDriver_PayPalStd;

=head1 LEGAL
 -------------------------------------------------------------------
 PayPal Standard payment driver for WebGUI.
 Copyright (C) 2009  Invicta Services, LLC.
 -------------------------------------------------------------------
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along
 with this program; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 -------------------------------------------------------------------
=cut

use strict;

our $I18N = {
    'error occurred message' => {
        message     => q|The following errors occurred:|,
        lastUpdated => 0,
        context => q|The message that tell the user that there were some errors in their submitted credentials.|,
    },
    'PayPal' => {
        message     => q|PayPal|,
        lastUpdated => 0,
        context     => q|The name of the PayPal Website Payments Standard plugin|,
    },
    'label' => {
        message     => q|PayPal|,
        lastUpdated => 0,
        context     => q|Default PayPal payment gateway label|
    },

    'vendorId' => {
        message     => q|PayPal Account|,
        lastUpdated => 0,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'vendorId help' => {
        message     => q|Fill in the email address that identifies your PayPal account.|,
        lastUpdated => 0,
        context     => q|Hover help for vendor id in the configuration form of the PayPal module.|
    },

    'emailMessage' => {
        message     => q|Email message|,
        lastUpdated => 0,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'emailMessage help' => {
        message     => q|The message that will be appended to the email user will receive from PayPal.|,
        lastUpdated => 0,
        context     => q|Hover help for the email message field in the configuration form of the PayPal module.|
    },

    'password' => {
        message     => q|Password|,
        lastUpdated => 0,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'password help' => {
        message     => q|The password for your PayPal account.|,
        lastUpdated => 0,
        context     => q|Hover help for the password field in the configuration form of the PayPal module.|
    },

    'signature' => {
        message     => q|Signature|,
        lastUpdated => 0,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'signature help' => {
        message     => q|The account signature for your PayPal account.|,
        lastUpdated => 0,
        context     => q|Hover help for the signature field in the configuration form of the PayPal module.|
    },

    'currency' => {
        message     => q|Currency|,
        lastUpdated => 0,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'currency help' => {
        message     => q|The currency for your transactions with your PayPal account.|,
        lastUpdated => 0,
        context     => q|Hover help for the signature field in the configuration form of the PayPal module.|
    },

    'use sandbox' => {
        message     => q|Use Sandbox|,
        lastUpdated => 0,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'use sandbox help' => {
        message =>
            q|Set this option to yes if you want to use the PayPal SANDBOX development (i.e. NOT production) environment. Recommended for testing.|,
        lastUpdated => 0,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'button image' => {
        message     => q|PayPal Button image URL|,
        lastUpdated => 1241986933,
        context     => q|Form label in the configuration form of the PayPal module.|
    },
    'button image help' => {
        message     => q|Set this option to use PayPal images for checkout buttons.|,
        lastUpdated => 1241986933,
        context     => q|Form label in the configuration form of the PayPal module.|
    },

    'module name' => {
        message     => q|PayPal|,
        lastUpdated => 0,
        context     => q|The displayed name of the payment module.|
    },

    'invalid firstName' => {
        message     => q|You have to enter a valid first name.|,
        lastUpdated => 0,
        context     => q|An error indicating that an invalid first name has been entered.|
    },
    'invalid lastName' => {
        message     => q|You have to enter a valid last name.|,
        lastUpdated => 0,
        context     => q|An error indicating that an invalid last name has been entered.|
    },
    'invalid address' => {
        message     => q|You have to enter a valid address.|,
        lastUpdated => 0,
        context     => q|An error indicating that an invalid street has been entered.|
    },
    'invalid city' => {
        message     => q|You have to enter a valid city.|,
        lastUpdated => 0,
        context     => q|An error indicating that an invalid city has been entered.|
    },
    'invalid zip' => {
        message     => q|You have to enter a valid zipcode.|,
        lastUpdated => 0,
        context     => q|An error indicating that an invalid zipcode has been entered.|
    },
    'invalid email' => {
        message     => q|You have to enter a valid email address.|,
        lastUpdated => 0,
        context     => q|An error indicating that an invalid email address has been entered.|
    },
    'PayPal' => {
        message     => q|PayPal|,
        lastUpdated => 0,
        context     => q|Name of the gateway from the definition|
    },
    'no description' => {
        message     => q|No description|,
        lastUpdated => 0,
        context     => q|The default description of purchase of users.|
    },
    'extra info' => {
        message =>
            q|Remember to set both &quot;Payment Data Transfer&quot; and &quot;Auto Return&quot; <b>ON</b> in the Website Payments section of your PayPal Profile.<br />
Additionally, set the &quot;Return URL&quot; to:|,
        lastUpdated => 0,
        context     => q|An informational message that's shown in the configuration form of this plugin.|
    },
};

1;

