"use strict";

var _interopRequireDefault = require("@babel/runtime/helpers/interopRequireDefault");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.generateObjSchema = exports.enumArraySchema = exports.arraySchema = void 0;

var _defineProperty2 = _interopRequireDefault(require("@babel/runtime/helpers/defineProperty"));

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); if (enumerableOnly) symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; }); keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i] != null ? arguments[i] : {}; if (i % 2) { ownKeys(Object(source), true).forEach(function (key) { (0, _defineProperty2["default"])(target, key, source[key]); }); } else if (Object.getOwnPropertyDescriptors) { Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)); } else { ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } } return target; }

/**
 * JSON schema to accept an array of unique strings
 */
var arraySchema = {
  type: 'array',
  items: {
    type: 'string'
  },
  uniqueItems: true,
  additionalItems: false
};
/**
 * JSON schema to accept an array of unique strings from an enumerated list.
 */

exports.arraySchema = arraySchema;

var enumArraySchema = function enumArraySchema() {
  var enumeratedList = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : [];
  var minItems = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 0;
  return _objectSpread(_objectSpread({}, arraySchema), {}, {
    items: {
      type: 'string',
      "enum": enumeratedList
    },
    minItems
  });
};
/**
 * Factory function to generate an object schema
 * with specified properties object
 */


exports.enumArraySchema = enumArraySchema;

var generateObjSchema = function generateObjSchema() {
  var properties = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  var required = arguments.length > 1 ? arguments[1] : undefined;
  return {
    type: 'object',
    properties,
    required
  };
};

exports.generateObjSchema = generateObjSchema;