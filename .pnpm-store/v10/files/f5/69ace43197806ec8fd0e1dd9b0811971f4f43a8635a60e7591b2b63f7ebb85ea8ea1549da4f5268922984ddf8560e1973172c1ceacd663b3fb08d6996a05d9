'use strict';

var Type = require('./Type');

// var modulo = require('./modulo');
var $floor = Math.floor;

// http://262.ecma-international.org/11.0/#eqn-floor

module.exports = function floor(x) {
	// return x - modulo(x, 1);
	if (Type(x) === 'BigInt') {
		return x;
	}
	return $floor(x);
};
