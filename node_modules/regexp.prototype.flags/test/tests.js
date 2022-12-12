'use strict';

var has = require('has');
var inspect = require('object-inspect');

var getRegexLiteral = function (stringRegex) {
	try {
		/* jshint evil: true */
		/* eslint-disable no-new-func */
		return Function('return ' + stringRegex + ';')();
		/* eslint-enable no-new-func */
		/* jshint evil: false */
	} catch (e) { /**/ }
	return null;
};

module.exports = function runTests(flags, t) {
	t.equal(flags(/a/g), 'g', 'flags(/a/g) !== "g"');
	t.equal(flags(/a/gmi), 'gim', 'flags(/a/gmi) !== "gim"');
	t.equal(flags(new RegExp('a', 'gmi')), 'gim', 'flags(new RegExp("a", "gmi")) !== "gim"');
	t.equal(flags(/a/), '', 'flags(/a/) !== ""');
	t.equal(flags(new RegExp('a')), '', 'flags(new RegExp("a")) !== ""');

	t.test('sticky flag', { skip: !has(RegExp.prototype, 'sticky') }, function (st) {
		st.equal(flags(getRegexLiteral('/a/y')), 'y', 'flags(/a/y) !== "y"');
		st.equal(flags(new RegExp('a', 'y')), 'y', 'flags(new RegExp("a", "y")) !== "y"');
		st.end();
	});

	t.test('unicode flag', { skip: !has(RegExp.prototype, 'unicode') }, function (st) {
		st.equal(flags(getRegexLiteral('/a/u')), 'u', 'flags(/a/u) !== "u"');
		st.equal(flags(new RegExp('a', 'u')), 'u', 'flags(new RegExp("a", "u")) !== "u"');
		st.end();
	});

	t.test('dotAll flag', { skip: !has(RegExp.prototype, 'dotAll') }, function (st) {
		st.equal(flags(getRegexLiteral('/a/s')), 's', 'flags(/a/s) !== "s"');
		st.equal(flags(new RegExp('a', 's')), 's', 'flags(new RegExp("a", "s")) !== "s"');
		st.end();
	});

	t.test('sorting', function (st) {
		st.equal(flags(/a/gim), 'gim', 'flags(/a/gim) !== "gim"');
		st.equal(flags(/a/mig), 'gim', 'flags(/a/mig) !== "gim"');
		st.equal(flags(/a/mgi), 'gim', 'flags(/a/mgi) !== "gim"');
		if (has(RegExp.prototype, 'sticky')) {
			st.equal(flags(getRegexLiteral('/a/gyim')), 'gimy', 'flags(/a/gyim) !== "gimy"');
		}
		if (has(RegExp.prototype, 'unicode')) {
			st.equal(flags(getRegexLiteral('/a/ugmi')), 'gimu', 'flags(/a/ugmi) !== "gimu"');
		}
		if (has(RegExp.prototype, 'dotAll')) {
			st.equal(flags(getRegexLiteral('/a/sgmi')), 'gims', 'flags(/a/sgmi) !== "gims"');
		}
		st.end();
	});

	t.test('basic examples', function (st) {
		st.equal(flags(/a/g), 'g', '(/a/g).flags !== "g"');
		st.equal(flags(/a/gmi), 'gim', '(/a/gmi).flags !== "gim"');
		st.equal(flags(new RegExp('a', 'gmi')), 'gim', 'new RegExp("a", "gmi").flags !== "gim"');
		st.equal(flags(/a/), '', '(/a/).flags !== ""');
		st.equal(flags(new RegExp('a')), '', 'new RegExp("a").flags !== ""');

		st.end();
	});

	t.test('generic flags', function (st) {
		st.equal(flags({}), '');
		st.equal(flags({ ignoreCase: true }), 'i');
		st.equal(flags({ dotAll: 1, global: 0, sticky: 1, unicode: 1 }), 'suy');
		st.equal(flags({ __proto__: { multiline: true } }), 'm');

		st.end();
	});

	t.test('throws properly', function (st) {
		var nonObjects = ['', false, true, 42, NaN, null, undefined];
		st.plan(nonObjects.length);
		var throwsOnNonObject = function (nonObject) {
			st['throws'](flags.bind(null, nonObject), TypeError, inspect(nonObject) + ' is not an Object');
		};
		nonObjects.forEach(throwsOnNonObject);
	});
};
