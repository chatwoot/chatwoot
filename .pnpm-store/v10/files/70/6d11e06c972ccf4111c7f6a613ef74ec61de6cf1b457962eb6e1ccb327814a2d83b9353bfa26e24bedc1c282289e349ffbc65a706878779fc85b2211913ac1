import getCountryByNationalNumber from './getCountryByNationalNumber.js';
var USE_NON_GEOGRAPHIC_COUNTRY_CODE = false;
export default function getCountryByCallingCode(callingCode, _ref) {
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

  return getCountryByNationalNumber(nationalPhoneNumber, {
    countries: possibleCountries,
    defaultCountry: defaultCountry,
    metadata: metadata.metadata
  });
}
//# sourceMappingURL=getCountryByCallingCode.js.map