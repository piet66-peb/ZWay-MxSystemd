/*** MxSystemd V1.2.0 2024-09-08 Z-Way HA module *********************************/

//h-------------------------------------------------------------------------------
//h
//h Name:         index.js
//h Type:         Javascript code for Z-Way module MxSystemd
//h Purpose:      
//h Project:      Z-Way HA
//h Usage:        
//h Remark:       
//h Result:       
//h Examples:     
//h Outline:      
//h Resources:    AutomationModule
//h Issues:       
//h Authors:      peb Peter M. Ebert
//h Version:      V1.2.0 2024-09-08/peb
//v History:      V1.0.0 2024-03-27/peb first version
//h Copyright:    (C) Peter M. Ebert 2019
//h License:      http://opensource.org/licenses/MIT
//h 
//h-------------------------------------------------------------------------------
/*jshint esversion: 5 */
/*jshint strict: false */
/*globals inherits, _module: true, AutomationModule */

//h-------------------------------------------------------------------------------
//h
//h Name:         MxSystemd
//h Purpose:      create module subclass.
//h
//h-------------------------------------------------------------------------------
function MxSystemd(id, controller) {
    // Call superconstructor first (AutomationModule)
    MxSystemd.super_.call(this, id, controller);

    this.MODULE='index.js';
    this.VERSION='V1.2.0';
    this.WRITTEN='2024-09-08/peb';
}
inherits(MxSystemd, AutomationModule);
_module = MxSystemd;

//h-------------------------------------------------------------------------------
//h
//h Name:         init
//h Purpose:      module initialization.
//h
//h-------------------------------------------------------------------------------
MxSystemd.prototype.init = function(config) {
    MxSystemd.super_.prototype.init.call(this, config);
    var self = this;

    //b nothing to do
    //---------------
    
}; //init

//h-------------------------------------------------------------------------------
//h
//h Name:         stop
//h Purpose:      module stop.
//h
//h-------------------------------------------------------------------------------
MxSystemd.prototype.stop = function() {
    var self = this;

    //b nothing to do
    //---------------

    MxSystemd.super_.prototype.stop.call(this);
}; //stop

