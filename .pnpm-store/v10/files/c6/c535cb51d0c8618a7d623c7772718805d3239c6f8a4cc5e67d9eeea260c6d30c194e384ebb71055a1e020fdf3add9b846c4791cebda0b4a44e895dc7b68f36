import Metadata from '../metadata.js'
import getNumberType from './getNumberType.js'

export default function getCountryByNationalNumber(nationalPhoneNumber, {
	countries,
	defaultCountry,
	metadata
}) {
	// Re-create `metadata` because it will be selecting a `country`.
	metadata = new Metadata(metadata)

	const matchingCountries = []

	for (const country of countries) {
		metadata.country(country)
		// "Leading digits" patterns are only defined for about 20% of all countries.
		// By definition, matching "leading digits" is a sufficient but not a necessary
		// condition for a phone number to belong to a country.
		// The point of "leading digits" check is that it's the fastest one to get a match.
		// https://gitlab.com/catamphetamine/libphonenumber-js/blob/master/METADATA.md#leading_digits
		// I'd suppose that "leading digits" patterns are mutually exclusive for different countries
		// because of the intended use of that feature.
		if (metadata.leadingDigits()) {
			if (nationalPhoneNumber &&
				nationalPhoneNumber.search(metadata.leadingDigits()) === 0) {
				return country
			}
		}
		// Else perform full validation with all of those
		// fixed-line/mobile/etc regular expressions.
		else if (getNumberType({ phone: nationalPhoneNumber, country }, undefined, metadata.metadata)) {
			// If the `defaultCountry` is among the `matchingCountries` then return it.
			if (defaultCountry) {
				if (country === defaultCountry) {
					return country
				}
				matchingCountries.push(country)
			} else {
				return country
			}
		}
	}

	// Return the first ("main") one of the `matchingCountries`.
	if (matchingCountries.length > 0) {
		return matchingCountries[0]
	}
}