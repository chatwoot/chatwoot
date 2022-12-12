'use strict';

module.exports = function requirePromise() {
	if (typeof Promise !== 'function') {
		throw new TypeError('`Promise.allSettled` requires a global `Promise` be available.');
	}
};
