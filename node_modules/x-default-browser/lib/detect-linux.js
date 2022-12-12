var exec = require('child_process').exec;

module.exports = function (callback) {

    var command = 'xdg-mime query default x-scheme-handler/http';

    exec(command, function (err, stdout, stderr) {
        if(err) {
            callback('Unable to execute the query: ' + err + '\n' + stderr);
            return;
        }

        var value = stdout;

        /*
         *  ubuntu 14.04.1:
         *  --------
         *  firefox.desktop
         *  google-chrome.desktop
         *  chromium-browser.desktop
         *  opera.desktop
         */
        var out = {
            isIE:       false,
            isSafari:   false,
            isFirefox:  value.indexOf('firefox') > -1,
            isChrome:   value.indexOf('google') > -1,
            isChromium: value.indexOf('chromium') > -1,
            isOpera:    value.indexOf('opera') > -1,
            identity:   value
        };
        out.isWebkit = out.isBlink = (out.isChrome || out.isChromium || out.isOpera);
        out.commonName = require('./common-name')(out);

        callback(null, out);
    });
};
