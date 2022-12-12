var exec = require('child_process').exec;

module.exports = function (callback) {

    // It seems that StartMenuInternet is more reliable; IE may be default without changing http-shell-open-command
    var registryQuery = 'HKCU\\Software\\Clients\\StartMenuInternet';
    //var registryQuery = 'HKCU\\Software\\Classes\\http\\shell\\open\\command'
    var command = 'reg query ' + registryQuery + ' | findstr "REG_SZ"';

    exec(command, function (err, stdout, stderr) {
        var value;
        // parse the output which is sth like this (XP):
        //   ! REG.EXE VERSION 3.0
        //
        //   HKEY_CURRENT_USER\Software\Classes\http\shell\open\command
        //   <NO NAME>   REG_SZ  "C:\Program Files\Mozilla Firefox\firefox.exe" -osint -url "%1"
        if (err) {
            if (stderr.length > 0) {
                return callback('Unable to execute the query: ' + err);
            } else {
                // findstr failed due to not finding match => key is empty, default browser is IE
                value = 'iexplore.exe';
            }
        }

        if (!value) {
            // XP hack to get rid of space so we can later split on it...
            stdout = stdout.replace("NO NAME", "NONAME");
            // on XP it's tab-separated, on Win7 space-separated...
            var split = stdout.trim().split(/(\t| +)/);
            // splits to sth like [ '(Default)', '    ', 'REG_SZ', '    ', 'value' ] but for "Google Chrome" it will be further split...
            value = (split[4] + (split[5] || "") + (split[6] || "")).toLowerCase();
        }

        //var pos1 = value.indexOf('"') + 1;
        //var pos2 = value.indexOf('"', pos1);
        //var path = value.substring(pos1, pos2);

        var out = {
            isIE:       value.indexOf('iexplore') > -1,     // IEXPLORE.EXE             / -
            isSafari:   value.indexOf('safari') > -1,       // Safari.exe
            // works also for nightly
            isFirefox:  value.indexOf('firefox') > -1,      // FIREFOX.EXE              / "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" -osint -url "%1"
            // note that both chrome and chromium are chrome.exe! we can't look for 'chrome' hence
            isChrome:   value.indexOf('google') > -1,       // Google Chrome            / "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -- "%1"
            isChromium: value.indexOf('chromium') > -1,     // Chromium.<randomstring>  / "C:\Users\<username>\AppData\Local\Chromium\Application\chrome.exe" -- "%1"
            isOpera:    value.indexOf('opera') > -1,        // OperaStable              / "C:\Program Files (x86)\Opera\launcher.exe" -noautoupdate -- "%1"
            identity:   value
        };
        out.isBlink = (out.isChrome || out.isChromium || out.isOpera);
        out.isWebkit = (out.isSafari || out.isBlink);
        out.commonName = require('./common-name')(out);

        callback(null, out);
    });
};
