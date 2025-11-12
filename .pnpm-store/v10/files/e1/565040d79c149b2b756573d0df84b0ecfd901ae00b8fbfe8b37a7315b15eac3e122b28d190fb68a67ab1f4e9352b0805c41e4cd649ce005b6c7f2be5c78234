"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = matchPhoneNumberStringAgainstPhoneNumber;

var _parsePhoneNumber = _interopRequireDefault(require("../parsePhoneNumber.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

/**
 * Matches a phone number object against a phone number string.
 * @param  {string} phoneNumberString
 * @param  {PhoneNumber} phoneNumber
 * @param  {object} metadata — Metadata JSON
 * @return {'INVALID_NUMBER'|'NO_MATCH'|'SHORT_NSN_MATCH'|'NSN_MATCH'|'EXACT_MATCH'}
 */
function matchPhoneNumberStringAgainstPhoneNumber(phoneNumberString, phoneNumber, metadata) {
  // Parse `phoneNumberString`.
  var phoneNumberStringContainsCallingCode = true;
  var parsedPhoneNumber = (0, _parsePhoneNumber["default"])(phoneNumberString, metadata);

  if (!parsedPhoneNumber) {
    // If `phoneNumberString` didn't contain a country calling code
    // then substitute it with the `phoneNumber`'s country calling code.
    phoneNumberStringContainsCallingCode = false;
    parsedPhoneNumber = (0, _parsePhoneNumber["default"])(phoneNumberString, {
      defaultCallingCode: phoneNumber.countryCallingCode
    }, metadata);
  }

  if (!parsedPhoneNumber) {
    return 'INVALID_NUMBER';
  } // Check that the extensions match.


  if (phoneNumber.ext) {
    if (parsedPhoneNumber.ext !== phoneNumber.ext) {
      return 'NO_MATCH';
    }
  } else {
    if (parsedPhoneNumber.ext) {
      return 'NO_MATCH';
    }
  } // Check that country calling codes match.


  if (phoneNumberStringContainsCallingCode) {
    if (phoneNumber.countryCallingCode !== parsedPhoneNumber.countryCallingCode) {
      return 'NO_MATCH';
    }
  } // Check if the whole numbers match.


  if (phoneNumber.number === parsedPhoneNumber.number) {
    if (phoneNumberStringContainsCallingCode) {
      return 'EXACT_MATCH';
    } else {
      return 'NSN_MATCH';
    }
  } // Check if one national number is a "suffix" of the other.


  if (phoneNumber.nationalNumber.indexOf(parsedPhoneNumber.nationalNumber) === 0 || parsedPhoneNumber.nationalNumber.indexOf(phoneNumber.nationalNumber) === 0) {
    // "A SHORT_NSN_MATCH occurs if there is a difference because of the
    //  presence or absence of an 'Italian leading zero', the presence or
    //  absence of an extension, or one NSN being a shorter variant of the
    //  other."
    return 'SHORT_NSN_MATCH';
  }

  return 'NO_MATCH';
}
//# sourceMappingURL=matchPhoneNumberStringAgainstPhoneNumber.js.map