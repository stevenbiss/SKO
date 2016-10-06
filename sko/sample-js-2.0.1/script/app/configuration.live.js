/*
 * ADOBE SYSTEMS INCORPORATED
 * Copyright 2014 Adobe Systems Incorporated
 * All Rights Reserved.

 * NOTICE:  Adobe permits you to use, modify, and distribute this file in accordance with the
 * terms of the Adobe license agreement accompanying it.  If you have received this file from a
 * source other than Adobe, then your use, modification, or distribution of it requires the prior
 * written permission of Adobe.
 */

(function() {
    'use strict';
	
		var currentdate = new Date(); 
		var datetime = currentdate.getFullYear() + "-"
                + (currentdate.getMonth()+1)  + "-" 
                + currentdate.getDate() + " @ "  
                + currentdate.getHours() + ":"  
                + currentdate.getMinutes() + ":" 
                + currentdate.getSeconds();
		
    // Export symbols.
    window.Configuration = {
        PLAYER: {
            NAME: 'SKO JS LIVE | ' + datetime,
            VIDEO_ID: 'SKO JS LIVE | ' + datetime,
            VIDEO_NAME: 'SKO JS LIVE | ' + datetime
        },

        VISITOR: {
            MARKETING_CLOUD_ORG_ID: '90E5833357B240DF7F000101@AdobeOrg',
            TRACKING_SERVER: 'stevenbiss.sc.omtrdc.net',
            DPID: 'sample-dpid',
            DPUUID: 'sample-dpuuid'
        },

        APP_MEASUREMENT: {
            RSID: 'asbiss1',
            TRACKING_SERVER: 'stevenbiss.sc.omtrdc.net',
            PAGE_NAME: 'SKO.VHLSample.HTML5'
        },

        HEARTBEAT: {
            TRACKING_SERVER: 'stevenbiss.hb.omtrdc.net',
            PUBLISHER: '90E5833357B240DF7F000101@AdobeOrg',
            CHANNEL: 'test-channel',
            OVP: 'test-ovp',
            SDK: 'test-sdk'
        }
    };
})();
