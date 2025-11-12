'use strict';

var hasOwn = require('hasown');

var hasUnscopables = typeof Symbol === 'function' && typeof Symbol.unscopables === 'symbol';

var map = hasUnscopables && Array.prototype[Symbol.unscopables];

var $TypeError = TypeError;

module.exports = function shimUnscopables(method) {
	if (typeof method !== 'string' || !method) {
		throw new $TypeError('method must be a non-empty string');
	}
	if (!hasOwn(Array.prototype, method)) {
		throw new $TypeError('method must be on Array.prototype');
	}
	if (hasUnscopables) {
		map[method] = true;
	}
};
