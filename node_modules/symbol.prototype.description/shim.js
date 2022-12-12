'use strict';

var hasSymbols = require('has-symbols')();
var polyfill = require('./polyfill');
var getInferredName = require('es-abstract/helpers/getInferredName');

var gOPD = Object.getOwnPropertyDescriptor;
var gOPDs = require('object.getownpropertydescriptors/polyfill')();
var dP = Object.defineProperty;
var dPs = Object.defineProperties;
var setProto = Object.setPrototypeOf;

var define = function defineGetter(getter) {
	dP(Symbol.prototype, 'description', {
		configurable: true,
		enumerable: false,
		get: getter
	});
};

var shimGlobal = function shimGlobalSymbol(getter) {
	var origSym = Function.apply.bind(Symbol);
	var emptyStrings = Object.create ? Object.create(null) : {};
	var SymNew = function Symbol() {
		var sym = origSym(this, arguments);
		if (arguments.length > 0 && arguments[0] === '') {
			emptyStrings[sym] = true;
		}
		return sym;
	};
	SymNew.prototype = Symbol.prototype;
	setProto(SymNew, Symbol);
	var props = gOPDs(Symbol);
	delete props.length;
	delete props.arguments;
	delete props.caller;
	dPs(SymNew, props);
	Symbol = SymNew; // eslint-disable-line no-native-reassign, no-global-assign

	var boundGetter = Function.call.bind(getter);
	var wrappedGetter = function description() {
		/* eslint no-invalid-this: 0 */
		var symbolDescription = boundGetter(this);
		if (emptyStrings[this]) {
			return '';
		}
		return symbolDescription;
	};
	define(wrappedGetter);
	return wrappedGetter;
};

module.exports = function shimSymbolDescription() {
	if (!hasSymbols) {
		return false;
	}
	var desc = gOPD(Symbol.prototype, 'description');
	var getter = polyfill();
	var isMissing = !desc || typeof desc.get !== 'function';
	var isBroken = !isMissing && (typeof Symbol().description !== 'undefined' || Symbol('').description !== '');
	if (isMissing || isBroken) {
		if (!getInferredName) {
			return shimGlobal(getter);
		}
		define(getter);
	}
	return getter;
};
