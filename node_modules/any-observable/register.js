'use strict';
module.exports = require('./loader')(global, loadImplementation);

function loadImplementation(implementation) {
	let impl;

	if (implementation === 'global.Observable') {
		// If no implementation or env specified use global.Observable
		impl = {
			Observable: global.Observable,
			implementation: 'global.Observable'
		};
	} else if (implementation) {
		// If implementation specified, require it
		const lib = require(implementation);

		impl = {
			Observable: lib.Observable || lib.default || lib,
			implementation
		};
	} else {
		// Try to auto detect implementation. This is non-deterministic
		// and should prefer other branches, but this is our last chance
		// to load something without throwing error
		impl = tryAutoDetect();
	}

	if (!impl) {
		throw new Error('Cannot find any-observable implementation nor' +
			' global.Observable. You must install polyfill or call' +
			' require("any-observable/register") with your preferred' +
			' implementation, e.g. require("any-observable/register")(\'rxjs\')' +
			' on application load prior to any require("any-observable").');
	}

	return impl;
}

function tryAutoDetect() {
	const libs = [
		'rxjs',
		'zen-observable'
	];

	for (const lib of libs) {
		try {
			return loadImplementation(lib);
		} catch (_) {}
	}

	return null;
}
