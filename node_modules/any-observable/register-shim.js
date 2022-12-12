/* eslint-env node, browser */
'use strict';
module.exports = require('./loader')(window, loadImplementation);

/**
 * Browser specific loadImplementation. Always uses `window.Observable`
 *
 * To register a custom implementation, must register with `Observable` option.
 */
function loadImplementation() {
	if (typeof window.Observable === 'undefined') {
		throw new TypeError(`any-observable browser requires a polyfill or explicit registration e.g: require('any-observable/register')('rxjs', {Observable: require('rxjs/Observable').Observable})`);
	}

	return {
		Observable: window.Observable,
		implementation: 'window.Observable'
	};
}
