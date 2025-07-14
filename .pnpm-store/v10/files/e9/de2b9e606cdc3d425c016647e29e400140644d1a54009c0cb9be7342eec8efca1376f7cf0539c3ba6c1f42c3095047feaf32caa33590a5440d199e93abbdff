"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = isValidNumberForRegion;

var _isValid = _interopRequireDefault(require("../isValid.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

/**
 * Checks if a given phone number is valid within a given region.
 * Is just an alias for `phoneNumber.isValid() && phoneNumber.country === country`.
 * https://github.com/googlei18n/libphonenumber/blob/master/FAQ.md#when-should-i-use-isvalidnumberforregion
 */
function isValidNumberForRegion(input, country, options, metadata) {
  // If assigning the `{}` default value is moved to the arguments above,
  // code coverage would decrease for some weird reason.
  options = options || {};
  return input.country === country && (0, _isValid["default"])(input, options, metadata);
}
//# sourceMappingURL=isValidNumberForRegion_.js.map