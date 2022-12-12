'use strict';

var $TypeError = TypeError;

// eslint-disable-next-line consistent-return
module.exports = function iterateIterator(iterator) {
	if (!iterator || typeof iterator.next !== 'function') {
		throw new $TypeError('iterator must be an object with a `next` method');
	}
	if (arguments.length > 1) {
		var callback = arguments[1];
		if (typeof callback !== 'function') {
			throw new $TypeError('`callback`, if provided, must be a function');
		}
	}
	var values = callback || [];
	var result;
	while ((result = iterator.next()) && !result.done) {
		if (callback) {
			callback(result.value); // eslint-disable-line callback-return
		} else {
			values.push(result.value);
		}
	}
	if (!callback) {
		return values;
	}
};
