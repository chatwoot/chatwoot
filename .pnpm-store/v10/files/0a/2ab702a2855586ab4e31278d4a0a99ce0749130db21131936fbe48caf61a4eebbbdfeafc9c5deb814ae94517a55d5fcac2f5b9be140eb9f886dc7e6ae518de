"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = getPossibleCountriesForNumber;

var _metadata2 = _interopRequireDefault(require("../metadata.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

/**
 * Returns a list of countries that the phone number could potentially belong to.
 * @param  {string} callingCode — Calling code.
 * @param  {string} nationalNumber — National (significant) number.
 * @param  {object} metadata — Metadata.
 * @return {string[]} A list of possible countries.
 */
function getPossibleCountriesForNumber(callingCode, nationalNumber, metadata) {
  var _metadata = new _metadata2["default"](metadata);

  var possibleCountries = _metadata.getCountryCodesForCallingCode(callingCode);

  if (!possibleCountries) {
    return [];
  }

  return possibleCountries.filter(function (country) {
    return couldNationalNumberBelongToCountry(nationalNumber, country, metadata);
  });
}

function couldNationalNumberBelongToCountry(nationalNumber, country, metadata) {
  var _metadata = new _metadata2["default"](metadata);

  _metadata.selectNumberingPlan(country);

  if (_metadata.numberingPlan.possibleLengths().indexOf(nationalNumber.length) >= 0) {
    return true;
  }

  return false;
}
//# sourceMappingURL=getPossibleCountriesForNumber.js.map