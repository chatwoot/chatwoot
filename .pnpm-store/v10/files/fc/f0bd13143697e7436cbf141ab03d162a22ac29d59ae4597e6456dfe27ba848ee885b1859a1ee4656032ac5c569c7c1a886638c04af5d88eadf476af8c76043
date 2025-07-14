"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = isValidNumberForRegion;

var _isViablePhoneNumber = _interopRequireDefault(require("../helpers/isViablePhoneNumber.js"));

var _parse = _interopRequireDefault(require("../parse.js"));

var _isValidNumberForRegion_ = _interopRequireDefault(require("./isValidNumberForRegion_.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

// This function has been deprecated and is not exported as
// `isValidPhoneNumberForCountry()` or `isValidPhoneNumberForRegion()`.
//
// The rationale is:
//
// * We don't use the "region" word, so "country" would be better.
//
// * It could be substituted with:
//
// ```js
// export default function isValidPhoneNumberForCountry(phoneNumberString, country) {
// 	const phoneNumber = parsePhoneNumber(phoneNumberString, {
// 		defaultCountry: country,
// 		// Demand that the entire input string must be a phone number.
// 		// Otherwise, it would "extract" a phone number from an input string.
// 		extract: false
// 	})
// 	if (!phoneNumber) {
// 		return false
// 	}
// 	if (phoneNumber.country !== country) {
// 		return false
// 	}
// 	return phoneNumber.isValid()
// }
// ```
//
// * Same function could be used for `isPossiblePhoneNumberForCountry()`
//   by replacing `isValid()` with `isPossible()`.
//
// * The reason why this function is not exported is because its result is ambiguous.
//   Suppose `false` is returned. It could mean any of:
//   * Not a phone number.
//   * The phone number is valid but belongs to another country or another calling code.
//   * The phone number belongs to the correct country but is not valid digit-wise.
//   All those three cases should be handled separately from a "User Experience" standpoint.
//   Simply showing "Invalid phone number" error in all of those cases would be lazy UX.
function isValidNumberForRegion(number, country, metadata) {
  if (typeof number !== 'string') {
    throw new TypeError('number must be a string');
  }

  if (typeof country !== 'string') {
    throw new TypeError('country must be a string');
  } // `parse` extracts phone numbers from raw text,
  // therefore it will cut off all "garbage" characters,
  // while this `validate` function needs to verify
  // that the phone number contains no "garbage"
  // therefore the explicit `isViablePhoneNumber` check.


  var input;

  if ((0, _isViablePhoneNumber["default"])(number)) {
    input = (0, _parse["default"])(number, {
      defaultCountry: country
    }, metadata);
  } else {
    input = {};
  }

  return (0, _isValidNumberForRegion_["default"])(input, country, undefined, metadata);
}
//# sourceMappingURL=isValidNumberForRegion.js.map