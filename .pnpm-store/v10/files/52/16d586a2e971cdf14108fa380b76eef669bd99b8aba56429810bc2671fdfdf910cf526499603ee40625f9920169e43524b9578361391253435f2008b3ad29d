"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = parsePhoneNumber;

var _parsePhoneNumberWithError_ = _interopRequireDefault(require("./parsePhoneNumberWithError_.js"));

var _ParseError = _interopRequireDefault(require("./ParseError.js"));

var _metadata = require("./metadata.js");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function parsePhoneNumber(text, options, metadata) {
  // Validate `defaultCountry`.
  if (options && options.defaultCountry && !(0, _metadata.isSupportedCountry)(options.defaultCountry, metadata)) {
    options = _objectSpread(_objectSpread({}, options), {}, {
      defaultCountry: undefined
    });
  } // Parse phone number.


  try {
    return (0, _parsePhoneNumberWithError_["default"])(text, options, metadata);
  } catch (error) {
    /* istanbul ignore else */
    if (error instanceof _ParseError["default"]) {//
    } else {
      throw error;
    }
  }
}
//# sourceMappingURL=parsePhoneNumber_.js.map