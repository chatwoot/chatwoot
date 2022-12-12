'use strict';

var getPolyfill = require('./polyfill');
var shim = require('./shim');
var implementation = require('./implementation');
var callBind = require('call-bind');

var bound = callBind(getPolyfill());

bound.shim = shim;
bound.getPolyfill = getPolyfill;
bound.implementation = implementation;

module.exports = bound;
