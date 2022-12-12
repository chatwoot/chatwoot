"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.globals = exports.decorators = void 0;

var _withMeasure = require("./withMeasure");

var _constants = require("./constants");

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var decorators = [_withMeasure.withMeasure];
exports.decorators = decorators;

var globals = _defineProperty({}, _constants.PARAM_KEY, false);

exports.globals = globals;