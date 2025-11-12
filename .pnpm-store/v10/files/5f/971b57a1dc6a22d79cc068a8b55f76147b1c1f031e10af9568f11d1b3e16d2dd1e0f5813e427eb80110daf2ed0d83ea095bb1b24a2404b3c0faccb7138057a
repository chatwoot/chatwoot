"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = isValidNumber;

var _isValid = _interopRequireDefault(require("../isValid.js"));

var _getNumberType = require("./getNumberType.js");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

// Finds out national phone number type (fixed line, mobile, etc)
function isValidNumber() {
  var _normalizeArguments = (0, _getNumberType.normalizeArguments)(arguments),
      input = _normalizeArguments.input,
      options = _normalizeArguments.options,
      metadata = _normalizeArguments.metadata; // `parseNumber()` would return `{}` when no phone number could be parsed from the input.


  if (!input.phone) {
    return false;
  }

  return (0, _isValid["default"])(input, options, metadata);
}
//# sourceMappingURL=isValidNumber.js.map