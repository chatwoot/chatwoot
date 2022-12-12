'use strict';
var os = require('os');
var bplist = require('bplist-parser');
var untildify = require('untildify');
var bundleId = 'com.apple.Safari';
var osxVersion = Number(os.release().split('.')[0]);
var file = untildify(osxVersion >= 14 ? '~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist' : '~/Library/Preferences/com.apple.LaunchServices.plist');

module.exports = function (cb) {
	if (process.platform !== 'darwin') {
		throw new Error('Only OS X systems are supported');
	}

	bplist.parseFile(file, function (err, data) {
		if (err) {
			return cb(err);
		}

		var handlers = data && data[0].LSHandlers;

		if (!handlers || handlers.length === 0) {
			return cb(null, bundleId);
		}

		for (var i = 0; i < handlers.length; i++) {
			var el = handlers[i];

			if (el.LSHandlerURLScheme === 'http' && el.LSHandlerRoleAll) {
				bundleId = el.LSHandlerRoleAll;
				break;
			}
		}

		cb(null, bundleId);
	});
};
