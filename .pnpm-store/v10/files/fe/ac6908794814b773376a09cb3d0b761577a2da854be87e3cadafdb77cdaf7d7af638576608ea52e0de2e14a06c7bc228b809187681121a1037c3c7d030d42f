"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = extractCountryCallingCodeFromInternationalNumberWithoutPlusSign;

var _metadata = _interopRequireDefault(require("../metadata.js"));

var _matchesEntirely = _interopRequireDefault(require("./matchesEntirely.js"));

var _extractNationalNumber = _interopRequireDefault(require("./extractNationalNumber.js"));

var _checkNumberLength = _interopRequireDefault(require("./checkNumberLength.js"));

var _getCountryCallingCode = _interopRequireDefault(require("../getCountryCallingCode.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

/**
 * Sometimes some people incorrectly input international phone numbers
 * without the leading `+`. This function corrects such input.
 * @param  {string} number — Phone number digits.
 * @param  {string?} country
 * @param  {string?} callingCode
 * @param  {object} metadata
 * @return {object} `{ countryCallingCode: string?, number: string }`.
 */
function extractCountryCallingCodeFromInternationalNumberWithoutPlusSign(number, country, callingCode, metadata) {
  var countryCallingCode = country ? (0, _getCountryCallingCode["default"])(country, metadata) : callingCode;

  if (number.indexOf(countryCallingCode) === 0) {
    metadata = new _metadata["default"](metadata);
    metadata.selectNumberingPlan(country, callingCode);
    var possibleShorterNumber = number.slice(countryCallingCode.length);

    var _extractNationalNumbe = (0, _extractNationalNumber["default"])(possibleShorterNumber, metadata),
        possibleShorterNationalNumber = _extractNationalNumbe.nationalNumber;

    var _extractNationalNumbe2 = (0, _extractNationalNumber["default"])(number, metadata),
        nationalNumber = _extractNationalNumbe2.nationalNumber; // If the number was not valid before but is valid now,
    // or if it was too long before, we consider the number
    // with the country calling code stripped to be a better result
    // and keep that instead.
    // For example, in Germany (+49), `49` is a valid area code,
    // so if a number starts with `49`, it could be both a valid
    // national German number or an international number without
    // a leading `+`.


    if (!(0, _matchesEntirely["default"])(nationalNumber, metadata.nationalNumberPattern()) && (0, _matchesEntirely["default"])(possibleShorterNationalNumber, metadata.nationalNumberPattern()) || (0, _checkNumberLength["default"])(nationalNumber, metadata) === 'TOO_LONG') {
      return {
        countryCallingCode: countryCallingCode,
        number: possibleShorterNumber
      };
    }
  }

  return {
    number: number
  };
}
//# sourceMappingURL=extractCountryCallingCodeFromInternationalNumberWithoutPlusSign.js.map