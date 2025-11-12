'use strict';

var callBound = require('call-bind/callBound');

var $arrayPush = callBound('Array.prototype.push');

var IteratorStep = require('./IteratorStep');
var IteratorValue = require('./IteratorValue');
var Type = require('./Type');

var assertRecord = require('../helpers/assertRecord');

// https://262.ecma-international.org/14.0/#sec-iteratortolist

module.exports = function IteratorToList(iteratorRecord) {
	assertRecord(Type, 'Iterator Record', 'iteratorRecord', iteratorRecord);

	var values = []; // step 1
	var next = true; // step 2
	while (next) { // step 3
		next = IteratorStep(iteratorRecord); // step 3.a
		if (next) {
			var nextValue = IteratorValue(next); // step 3.b.i
			$arrayPush(values, nextValue); // step 3.b.ii
		}
	}
	return values; // step 4
};
