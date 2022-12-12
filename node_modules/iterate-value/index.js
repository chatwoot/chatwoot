'use strict';

var getIterator = require('es-get-iterator');
var $TypeError = TypeError;
var iterate = require('iterate-iterator');

module.exports = function iterateValue(iterable) {
	var iterator = getIterator(iterable);
	if (!iterator) {
		throw new $TypeError('non-iterable value provided');
	}
	if (arguments.length > 1) {
		return iterate(iterator, arguments[1]);
	}
	return iterate(iterator);
};
