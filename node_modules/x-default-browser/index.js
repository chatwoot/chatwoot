var detect;
var os = require('os');

if (os.platform() == 'win32') {
    if (os.release().indexOf('10.') === 0)
        detect = require('./lib/detect-windows10');
    else
        detect = require('./lib/detect-windows');
} else if (os.platform() == 'darwin') {
    detect = require('./lib/detect-mac');
} else if (os.platform() == 'linux' || os.platform() == 'freebsd') {
    detect = require('./lib/detect-linux');
} else {
    detect = require('./lib/detect-stub');
}

module.exports = detect;
