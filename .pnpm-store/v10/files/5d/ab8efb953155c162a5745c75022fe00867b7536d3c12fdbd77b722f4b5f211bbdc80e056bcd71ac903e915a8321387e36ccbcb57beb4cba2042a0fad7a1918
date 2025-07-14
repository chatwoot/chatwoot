import stripIddPrefix from './stripIddPrefix.js'
import extractCountryCallingCodeFromInternationalNumberWithoutPlusSign from './extractCountryCallingCodeFromInternationalNumberWithoutPlusSign.js'
import Metadata from '../metadata.js'
import { MAX_LENGTH_COUNTRY_CODE } from '../constants.js'

/**
 * Converts a phone number digits (possibly with a `+`)
 * into a calling code and the rest phone number digits.
 * The "rest phone number digits" could include
 * a national prefix, carrier code, and national
 * (significant) number.
 * @param  {string} number — Phone number digits (possibly with a `+`).
 * @param  {string} [country] — Default country.
 * @param  {string} [callingCode] — Default calling code (some phone numbering plans are non-geographic).
 * @param  {object} metadata
 * @return {object} `{ countryCallingCodeSource: string?, countryCallingCode: string?, number: string }`
 * @example
 * // Returns `{ countryCallingCode: "1", number: "2133734253" }`.
 * extractCountryCallingCode('2133734253', 'US', null, metadata)
 * extractCountryCallingCode('2133734253', null, '1', metadata)
 * extractCountryCallingCode('+12133734253', null, null, metadata)
 * extractCountryCallingCode('+12133734253', 'RU', null, metadata)
 */
export default function extractCountryCallingCode(
	number,
	country,
	callingCode,
	metadata
) {
	if (!number) {
		return {}
	}

	let isNumberWithIddPrefix

	// If this is not an international phone number,
	// then either extract an "IDD" prefix, or extract a
	// country calling code from a number by autocorrecting it
	// by prepending a leading `+` in cases when it starts
	// with the country calling code.
	// https://wikitravel.org/en/International_dialling_prefix
	// https://github.com/catamphetamine/libphonenumber-js/issues/376
	if (number[0] !== '+') {
		// Convert an "out-of-country" dialing phone number
		// to a proper international phone number.
		const numberWithoutIDD = stripIddPrefix(number, country, callingCode, metadata)
		// If an IDD prefix was stripped then
		// convert the number to international one
		// for subsequent parsing.
		if (numberWithoutIDD && numberWithoutIDD !== number) {
			isNumberWithIddPrefix = true
			number = '+' + numberWithoutIDD
		} else {
			// Check to see if the number starts with the country calling code
			// for the default country. If so, we remove the country calling code,
			// and do some checks on the validity of the number before and after.
			// https://github.com/catamphetamine/libphonenumber-js/issues/376
			if (country || callingCode) {
				const {
					countryCallingCode,
					number: shorterNumber
				} = extractCountryCallingCodeFromInternationalNumberWithoutPlusSign(
					number,
					country,
					callingCode,
					metadata
				)
				if (countryCallingCode) {
					return {
						countryCallingCodeSource: 'FROM_NUMBER_WITHOUT_PLUS_SIGN',
						countryCallingCode,
						number: shorterNumber
					}
				}
			}
			return {
				// No need to set it to `UNSPECIFIED`. It can be just `undefined`.
				// countryCallingCodeSource: 'UNSPECIFIED',
				number
			}
		}
	}

	// Fast abortion: country codes do not begin with a '0'
	if (number[1] === '0') {
		return {}
	}

	metadata = new Metadata(metadata)

	// The thing with country phone codes
	// is that they are orthogonal to each other
	// i.e. there's no such country phone code A
	// for which country phone code B exists
	// where B starts with A.
	// Therefore, while scanning digits,
	// if a valid country code is found,
	// that means that it is the country code.
	//
	let i = 2
	while (i - 1 <= MAX_LENGTH_COUNTRY_CODE && i <= number.length) {
		const countryCallingCode = number.slice(1, i)
		if (metadata.hasCallingCode(countryCallingCode)) {
			metadata.selectNumberingPlan(countryCallingCode)
			return {
				countryCallingCodeSource: isNumberWithIddPrefix ? 'FROM_NUMBER_WITH_IDD' : 'FROM_NUMBER_WITH_PLUS_SIGN',
				countryCallingCode,
				number: number.slice(i)
			}
		}
		i++
	}

	return {}
}

// The possible values for the returned `countryCallingCodeSource` are:
//
// Copy-pasted from:
// https://github.com/google/libphonenumber/blob/master/resources/phonenumber.proto
//
// // The source from which the country_code is derived. This is not set in the
// // general parsing method, but in the method that parses and keeps raw_input.
// // New fields could be added upon request.
// enum CountryCodeSource {
//  // Default value returned if this is not set, because the phone number was
//  // created using parse, not parseAndKeepRawInput. hasCountryCodeSource will
//  // return false if this is the case.
//  UNSPECIFIED = 0;
//
//  // The country_code is derived based on a phone number with a leading "+",
//  // e.g. the French number "+33 1 42 68 53 00".
//  FROM_NUMBER_WITH_PLUS_SIGN = 1;
//
//  // The country_code is derived based on a phone number with a leading IDD,
//  // e.g. the French number "011 33 1 42 68 53 00", as it is dialled from US.
//  FROM_NUMBER_WITH_IDD = 5;
//
//  // The country_code is derived based on a phone number without a leading
//  // "+", e.g. the French number "33 1 42 68 53 00" when defaultCountry is
//  // supplied as France.
//  FROM_NUMBER_WITHOUT_PLUS_SIGN = 10;
//
//  // The country_code is derived NOT based on the phone number itself, but
//  // from the defaultCountry parameter provided in the parsing function by the
//  // clients. This happens mostly for numbers written in the national format
//  // (without country code). For example, this would be set when parsing the
//  // French number "01 42 68 53 00", when defaultCountry is supplied as
//  // France.
//  FROM_DEFAULT_COUNTRY = 20;
// }