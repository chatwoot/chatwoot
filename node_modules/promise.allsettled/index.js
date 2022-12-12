'use strict';

var callBind = require('call-bind');
var define = require('define-properties');

var requirePromise = require('./requirePromise');
var implementation = require('./implementation');
var getPolyfill = require('./polyfill');
var shim = require('./shim');

requirePromise();
var bound = callBind(getPolyfill());

var rebindable = function allSettled(iterable) {
	// eslint-disable-next-line no-invalid-this
	return bound(typeof this === 'undefined' ? Promise : this, iterable);
};

define(rebindable, {
	getPolyfill: getPolyfill,
	implementation: implementation,
	shim: shim
});

module.exports = rebindable;
