"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = getCountryByCallingCode;

var _getCountryByNationalNumber = _interopRequireDefault(require("./getCountryByNationalNumber.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

var USE_NON_GEOGRAPHIC_COUNTRY_CODE = false;

function getCountryByCallingCode(callingCode, _ref) {
  var nationalPhoneNumber = _ref.nationalNumber,
      defaultCountry = _ref.defaultCountry,
      metadata = _ref.metadata;

  /* istanbul ignore if */
  if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
    if (metadata.isNonGeographicCallingCode(callingCode)) {
      return '001';
    }
  }

  var possibleCountries = metadata.getCountryCodesForCallingCode(callingCode);

  if (!possibleCountries) {
    return;
  } // If there's just one country corresponding to the country code,
  // then just return it, without further phone number digits validation.


  if (possibleCountries.length === 1) {
    return possibleCountries[0];
  }

  return (0, _getCountryByNationalNumber["default"])(nationalPhoneNumber, {
    countries: possibleCountries,
    defaultCountry: defaultCountry,
    metadata: metadata.metadata
  });
}
//# sourceMappingURL=getCountryByCallingCode.js.map