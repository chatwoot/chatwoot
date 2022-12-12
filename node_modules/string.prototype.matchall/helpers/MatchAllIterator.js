'use strict';

var Get = require('es-abstract/2020/Get');
var IsRegExp = require('es-abstract/2020/IsRegExp');
var Set = require('es-abstract/2020/Set');
var SpeciesConstructor = require('es-abstract/2020/SpeciesConstructor');
var ToBoolean = require('es-abstract/2020/ToBoolean');
var ToLength = require('es-abstract/2020/ToLength');
var ToString = require('es-abstract/2020/ToString');
var flagsGetter = require('regexp.prototype.flags');

var RegExpStringIterator = require('./RegExpStringIterator');
var OrigRegExp = RegExp;

module.exports = function MatchAllIterator(R, O) {
	var S = ToString(O);

	var matcher, global, fullUnicode, flags;
	if (IsRegExp(R)) {
		var C = SpeciesConstructor(R, OrigRegExp);
		flags = Get(R, 'flags');
		if (typeof flags === 'string') {
			matcher = new C(R, flags); // Construct(C, [R, flags]);
		} else if (C === OrigRegExp) {
			// workaround for older engines that lack RegExp.prototype.flags
			matcher = new C(R.source, flagsGetter(R)); // Construct(C, [R.source, flagsGetter(R)]);
		} else {
			matcher = new C(R, flagsGetter(R)); // Construct(C, [R, flagsGetter(R)]);
		}
		global = ToBoolean(Get(matcher, 'global'));
		fullUnicode = ToBoolean(Get(matcher, 'unicode'));
		var lastIndex = ToLength(Get(R, 'lastIndex'));
		Set(matcher, 'lastIndex', lastIndex, true);
	} else {
		flags = 'g';
		matcher = new OrigRegExp(R, flags);
		global = true;
		fullUnicode = false;
		if (Get(matcher, 'lastIndex') !== 0) {
			throw new TypeError('Assertion failed: newly constructed RegExp had a lastIndex !== 0. Please report this!');
		}
	}
	return new RegExpStringIterator(matcher, S, global, fullUnicode);
};
