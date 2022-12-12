"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.includeConditionalArg = exports.testValue = void 0;

var _isEqual = _interopRequireDefault(require("lodash/isEqual"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

var count = function count(vals) {
  return vals.map(function (v) {
    return typeof v !== 'undefined';
  }).filter(Boolean).length;
};

var testValue = function testValue(cond, value) {
  var _ref = cond,
      exists = _ref.exists,
      eq = _ref.eq,
      neq = _ref.neq,
      truthy = _ref.truthy;

  if (count([exists, eq, neq, truthy]) > 1) {
    throw new Error("Invalid conditional test ".concat(JSON.stringify({
      exists: exists,
      eq: eq,
      neq: neq
    })));
  }

  if (typeof eq !== 'undefined') {
    return (0, _isEqual["default"])(value, eq);
  }

  if (typeof neq !== 'undefined') {
    return !(0, _isEqual["default"])(value, neq);
  }

  if (typeof exists !== 'undefined') {
    var valueExists = typeof value !== 'undefined';
    return exists ? valueExists : !valueExists;
  }

  var shouldBeTruthy = typeof truthy === 'undefined' ? true : truthy;
  return shouldBeTruthy ? !!value : !value;
};
/**
 * Helper function to include/exclude an arg based on the value of other other args
 * aka "conditional args"
 */


exports.testValue = testValue;

var includeConditionalArg = function includeConditionalArg(argType, args, globals) {
  if (!argType["if"]) return true;
  var _ref2 = argType["if"],
      arg = _ref2.arg,
      global = _ref2.global;

  if (count([arg, global]) !== 1) {
    throw new Error("Invalid conditional value ".concat(JSON.stringify({
      arg: arg,
      global: global
    })));
  }

  var value = arg ? args[arg] : globals[global];
  return testValue(argType["if"], value);
};

exports.includeConditionalArg = includeConditionalArg;