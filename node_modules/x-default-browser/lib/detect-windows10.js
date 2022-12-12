var exec = require('child_process').exec;

module.exports = function (callback) {

    var registryQuery = 'HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\Shell\\Associations\\URLAssociations\\http\\UserChoice';
    var command = 'reg query ' + registryQuery + ' | findstr "ProgId"';

    exec(command, function (err, stdout, stderr) {
        var value;
        // parse the output which is sth like this (Windows 10):
        //   "    ProgId    REG_SZ    ChromeHTML\r\n"
        if (err) {
            if (stderr.length > 0) {
                return callback('Unable to execute the query: ' + err);
            } else {
                // findstr failed due to not finding match => key is empty, default browser is IE
                value = 'iexplore.exe';
            }
        }

        if (!value) {
            // merge multiple spaces to one
            stdout = stdout.trim().replace(/\s\s+/g, ' ');
            var split = stdout.split(' ');
            // need third substr, stdout is of this form: "    ProgId    REG_SZ    ChromeHTML\r\n"
            value = split[2].toLowerCase();
        }

        var out = {
            isEdge:     value.indexOf('app') > -1,          // AppXq0fevzme2pys62n3e0fbqa7peapykr8v
            isIE:       value.indexOf('ie.http') > -1,      // IE.HTTP
            isSafari:   value.indexOf('safari') > -1,       // SafariURL
            isFirefox:  value.indexOf('firefox') > -1,      // FirefoxURL
            isChrome:   value.indexOf('chrome') > -1,       // ChromeHTML
            isChromium: value.indexOf('chromium') > -1,     
            isOpera:    value.indexOf('opera') > -1,        // OperaHTML
            identity:   value
        };
        out.isBlink = (out.isChrome || out.isChromium || out.isOpera);
        out.isWebkit = (out.isSafari || out.isBlink);
        out.commonName = require('./common-name')(out);

        callback(null, out);
    });
};
