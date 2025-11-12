"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = validatePhoneNumberLength;

var _normalizeArguments2 = _interopRequireDefault(require("./normalizeArguments.js"));

var _parsePhoneNumberWithError_ = _interopRequireDefault(require("./parsePhoneNumberWithError_.js"));

var _ParseError = _interopRequireDefault(require("./ParseError.js"));

var _metadata = _interopRequireDefault(require("./metadata.js"));

var _checkNumberLength = _interopRequireDefault(require("./helpers/checkNumberLength.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function validatePhoneNumberLength() {
  var _normalizeArguments = (0, _normalizeArguments2["default"])(arguments),
      text = _normalizeArguments.text,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata;

  options = _objectSpread(_objectSpread({}, options), {}, {
    extract: false
  }); // Parse phone number.

  try {
    var phoneNumber = (0, _parsePhoneNumberWithError_["default"])(text, options, metadata);
    metadata = new _metadata["default"](metadata);
    metadata.selectNumberingPlan(phoneNumber.countryCallingCode);
    var result = (0, _checkNumberLength["default"])(phoneNumber.nationalNumber, metadata);

    if (result !== 'IS_POSSIBLE') {
      return result;
    }
  } catch (error) {
    /* istanbul ignore else */
    if (error instanceof _ParseError["default"]) {
      return error.message;
    } else {
      throw error;
    }
  }
}
//# sourceMappingURL=validatePhoneNumberLength.js.map