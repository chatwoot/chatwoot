'use strict';

var define = require('define-properties');
var AdvanceStringIndex = require('es-abstract/2020/AdvanceStringIndex');
var CreateIterResultObject = require('es-abstract/2020/CreateIterResultObject');
var Get = require('es-abstract/2020/Get');
var GetIntrinsic = require('es-abstract/GetIntrinsic');
var OrdinaryObjectCreate = require('es-abstract/2020/OrdinaryObjectCreate');
var RegExpExec = require('es-abstract/2020/RegExpExec');
var Set = require('es-abstract/2020/Set');
var ToLength = require('es-abstract/2020/ToLength');
var ToString = require('es-abstract/2020/ToString');
var Type = require('es-abstract/2020/Type');
var hasSymbols = require('has-symbols')();

var SLOT = require('internal-slot');
var undefined;

var RegExpStringIterator = function RegExpStringIterator(R, S, global, fullUnicode) {
	if (Type(S) !== 'String') {
		throw new TypeError('S must be a string');
	}
	if (Type(global) !== 'Boolean') {
		throw new TypeError('global must be a boolean');
	}
	if (Type(fullUnicode) !== 'Boolean') {
		throw new TypeError('fullUnicode must be a boolean');
	}
	SLOT.set(this, '[[IteratingRegExp]]', R);
	SLOT.set(this, '[[IteratedString]]', S);
	SLOT.set(this, '[[Global]]', global);
	SLOT.set(this, '[[Unicode]]', fullUnicode);
	SLOT.set(this, '[[Done]]', false);
};

var IteratorPrototype = GetIntrinsic('%IteratorPrototype%', true);
if (IteratorPrototype) {
	RegExpStringIterator.prototype = OrdinaryObjectCreate(IteratorPrototype);
}

define(RegExpStringIterator.prototype, {
	next: function next() {
		var O = this;
		if (Type(O) !== 'Object') {
			throw new TypeError('receiver must be an object');
		}
		if (
			!(O instanceof RegExpStringIterator)
			|| !SLOT.has(O, '[[IteratingRegExp]]')
			|| !SLOT.has(O, '[[IteratedString]]')
			|| !SLOT.has(O, '[[Global]]')
			|| !SLOT.has(O, '[[Unicode]]')
			|| !SLOT.has(O, '[[Done]]')
		) {
			throw new TypeError('"this" value must be a RegExpStringIterator instance');
		}
		if (SLOT.get(O, '[[Done]]')) {
			return CreateIterResultObject(undefined, true);
		}
		var R = SLOT.get(O, '[[IteratingRegExp]]');
		var S = SLOT.get(O, '[[IteratedString]]');
		var global = SLOT.get(O, '[[Global]]');
		var fullUnicode = SLOT.get(O, '[[Unicode]]');
		var match = RegExpExec(R, S);
		if (match === null) {
			SLOT.set(O, '[[Done]]', true);
			return CreateIterResultObject(undefined, true);
		}
		if (global) {
			var matchStr = ToString(Get(match, '0'));
			if (matchStr === '') {
				var thisIndex = ToLength(Get(R, 'lastIndex'));
				var nextIndex = AdvanceStringIndex(S, thisIndex, fullUnicode);
				Set(R, 'lastIndex', nextIndex, true);
			}
			return CreateIterResultObject(match, false);
		}
		SLOT.set(O, '[[Done]]', true);
		return CreateIterResultObject(match, false);
	}
});
if (hasSymbols) {
	var defineP = Object.defineProperty;
	if (Symbol.toStringTag) {
		if (defineP) {
			defineP(RegExpStringIterator.prototype, Symbol.toStringTag, {
				configurable: true,
				enumerable: false,
				value: 'RegExp String Iterator',
				writable: false
			});
		} else {
			RegExpStringIterator.prototype[Symbol.toStringTag] = 'RegExp String Iterator';
		}
	}

	if (!IteratorPrototype && Symbol.iterator) {
		var func = {};
		func[Symbol.iterator] = RegExpStringIterator.prototype[Symbol.iterator] || function SymbolIterator() {
			return this;
		};
		var predicate = {};
		predicate[Symbol.iterator] = function () {
			return RegExpStringIterator.prototype[Symbol.iterator] !== func[Symbol.iterator];
		};
		define(RegExpStringIterator.prototype, func, predicate);
	}
}

module.exports = RegExpStringIterator;
