#!/usr/bin/env node
'use strict';
var meow = require('meow');
var defaultBrowserId = require('./');

meow({
	help: [
		'Example',
		'  $ default-browser-id',
		'  com.apple.Safari'
	].join('\n')
});

defaultBrowserId(function (err, id) {
	if (err) {
		console.error(err.message);
		process.exit(1);
	}

	console.log(id);
});
