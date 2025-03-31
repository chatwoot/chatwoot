'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var Call = require('./Call');
var Type = require('./Type');

var assertRecord = require('../helpers/assertRecord');

// https://262.ecma-international.org/14.0/#sec-iteratornext

module.exports = function IteratorNext(iteratorRecord) {
	assertRecord(Type, 'Iterator Record', 'iteratorRecord', iteratorRecord);

	var result;
	if (arguments.length < 2) { // step 1
		result = Call(iteratorRecord['[[NextMethod]]'], iteratorRecord['[[Iterator]]']); // step 1.a
	} else { // step 2
		result = Call(iteratorRecord['[[NextMethod]]'], iteratorRecord['[[Iterator]]'], [arguments[1]]); // step 2.a
	}

	if (Type(result) !== 'Object') {
		throw new $TypeError('iterator next must return an object'); // step 3
	}
	return result; // step 4
};
