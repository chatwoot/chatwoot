var defaultBrowserMac = require('default-browser-id');

var exec = require('child_process').exec;

module.exports = function (callback) {

    defaultBrowserMac(function (err, browserId) {
        if(err) {
            callback('Unable to retrieve default browser: ' + err);
            return;
        }

        var value = browserId;
        var valueLC = value.toLowerCase();

        /*
            Safari         com.apple.Safari
            Google Chrome  com.google.chrome
            Opera          com.operasoftware.Opera
            Firefox        org.mozilla.firefox
         */
        var out = {
            isIE:       false,
            isSafari:   valueLC.indexOf('safari') > -1,
            isFirefox:  valueLC.indexOf('firefox') > -1,
            isChrome:   valueLC.indexOf('google') > -1,
            isChromium: valueLC.indexOf('chromium') > -1, // untested
            isOpera:    valueLC.indexOf('opera') > -1,
            identity:   value
        };
        out.isBlink = (out.isChrome || out.isChromium || out.isOpera);
        out.isWebkit = (out.isSafari || out.isBlink);
        out.commonName = require('./common-name')(out);

        callback(null, out);
    });
};
