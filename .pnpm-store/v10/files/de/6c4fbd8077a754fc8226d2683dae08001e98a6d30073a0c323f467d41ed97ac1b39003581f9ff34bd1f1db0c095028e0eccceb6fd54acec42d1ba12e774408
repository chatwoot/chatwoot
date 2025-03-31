'use strict';

var GetIntrinsic = require('get-intrinsic');

var $TypeError = GetIntrinsic('%TypeError%');

var substring = require('./substring');
var Type = require('./Type');

var assertRecord = require('../helpers/assertRecord');

// https://262.ecma-international.org/13.0/#sec-getmatchstring

module.exports = function GetMatchString(S, match) {
	if (Type(S) !== 'String') {
		throw new $TypeError('Assertion failed: `S` must be a String');
	}
	assertRecord(Type, 'Match Record', 'match', match);

	if (!(match['[[StartIndex]]'] <= S.length)) {
		throw new $TypeError('`match` [[StartIndex]] must be a non-negative integer <= the length of S');
	}
	if (!(match['[[EndIndex]]'] <= S.length)) {
		throw new $TypeError('`match` [[EndIndex]] must be an integer between [[StartIndex]] and the length of S, inclusive');
	}
	return substring(S, match['[[StartIndex]]'], match['[[EndIndex]]']);
};
