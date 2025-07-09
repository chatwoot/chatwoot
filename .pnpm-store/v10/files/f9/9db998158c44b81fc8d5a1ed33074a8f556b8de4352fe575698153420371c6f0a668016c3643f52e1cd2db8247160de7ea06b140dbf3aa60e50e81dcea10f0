// This is a port of Google Android `libphonenumber`'s
// `phonenumberutil.js` of December 31th, 2018.
//
// https://github.com/googlei18n/libphonenumber/commits/master/javascript/i18n/phonenumbers/phonenumberutil.js

import {
	VALID_DIGITS,
	PLUS_CHARS,
	MIN_LENGTH_FOR_NSN,
	MAX_LENGTH_FOR_NSN
} from './constants.js'

import ParseError from './ParseError.js'
import Metadata from './metadata.js'
import isViablePhoneNumber, { isViablePhoneNumberStart } from './helpers/isViablePhoneNumber.js'
import extractExtension from './helpers/extension/extractExtension.js'
import parseIncompletePhoneNumber from './parseIncompletePhoneNumber.js'
import getCountryCallingCode from './getCountryCallingCode.js'
import { isPossibleNumber } from './isPossible.js'
// import { parseRFC3966 } from './helpers/RFC3966.js'
import PhoneNumber from './PhoneNumber.js'
import matchesEntirely from './helpers/matchesEntirely.js'
import extractCountryCallingCode from './helpers/extractCountryCallingCode.js'
import extractNationalNumber from './helpers/extractNationalNumber.js'
import stripIddPrefix from './helpers/stripIddPrefix.js'
import getCountryByCallingCode from './helpers/getCountryByCallingCode.js'
import extractFormattedPhoneNumberFromPossibleRfc3966NumberUri from './helpers/extractFormattedPhoneNumberFromPossibleRfc3966NumberUri.js'

// We don't allow input strings for parsing to be longer than 250 chars.
// This prevents malicious input from consuming CPU.
const MAX_INPUT_STRING_LENGTH = 250

// This consists of the plus symbol, digits, and arabic-indic digits.
const PHONE_NUMBER_START_PATTERN = new RegExp('[' + PLUS_CHARS + VALID_DIGITS + ']')

// Regular expression of trailing characters that we want to remove.
// A trailing `#` is sometimes used when writing phone numbers with extensions in US.
// Example: "+1 (645) 123 1234-910#" number has extension "910".
const AFTER_PHONE_NUMBER_END_PATTERN = new RegExp('[^' + VALID_DIGITS + '#' + ']+$')

const USE_NON_GEOGRAPHIC_COUNTRY_CODE = false

// Examples:
//
// ```js
// parse('8 (800) 555-35-35', 'RU')
// parse('8 (800) 555-35-35', 'RU', metadata)
// parse('8 (800) 555-35-35', { country: { default: 'RU' } })
// parse('8 (800) 555-35-35', { country: { default: 'RU' } }, metadata)
// parse('+7 800 555 35 35')
// parse('+7 800 555 35 35', metadata)
// ```
//

/**
 * Parses a phone number.
 *
 * parse('123456789', { defaultCountry: 'RU', v2: true }, metadata)
 * parse('123456789', { defaultCountry: 'RU' }, metadata)
 * parse('123456789', undefined, metadata)
 *
 * @param  {string} input
 * @param  {object} [options]
 * @param  {object} metadata
 * @return {object|PhoneNumber?} If `options.v2: true` flag is passed, it returns a `PhoneNumber?` instance. Otherwise, returns an object of shape `{ phone: '...', country: '...' }` (or just `{}` if no phone number was parsed).
 */
export default function parse(text, options, metadata) {
	// If assigning the `{}` default value is moved to the arguments above,
	// code coverage would decrease for some weird reason.
	options = options || {}

	metadata = new Metadata(metadata)

	// Validate `defaultCountry`.
	if (options.defaultCountry && !metadata.hasCountry(options.defaultCountry)) {
		if (options.v2) {
			throw new ParseError('INVALID_COUNTRY')
		}
		throw new Error(`Unknown country: ${options.defaultCountry}`)
	}

	// Parse the phone number.
	const { number: formattedPhoneNumber, ext, error } = parseInput(text, options.v2, options.extract)

	// If the phone number is not viable then return nothing.
	if (!formattedPhoneNumber) {
		if (options.v2) {
			if (error === 'TOO_SHORT') {
				throw new ParseError('TOO_SHORT')
			}
			throw new ParseError('NOT_A_NUMBER')
		}
		return {}
	}

	const {
		country,
		nationalNumber,
		countryCallingCode,
		countryCallingCodeSource,
		carrierCode
	} = parsePhoneNumber(
		formattedPhoneNumber,
		options.defaultCountry,
		options.defaultCallingCode,
		metadata
	)

	if (!metadata.hasSelectedNumberingPlan()) {
		if (options.v2) {
			throw new ParseError('INVALID_COUNTRY')
		}
		return {}
	}

	// Validate national (significant) number length.
	if (!nationalNumber || nationalNumber.length < MIN_LENGTH_FOR_NSN) {
		// Won't throw here because the regexp already demands length > 1.
		/* istanbul ignore if */
		if (options.v2) {
			throw new ParseError('TOO_SHORT')
		}
		// Google's demo just throws an error in this case.
		return {}
	}

	// Validate national (significant) number length.
	//
	// A sidenote:
	//
	// They say that sometimes national (significant) numbers
	// can be longer than `MAX_LENGTH_FOR_NSN` (e.g. in Germany).
	// https://github.com/googlei18n/libphonenumber/blob/7e1748645552da39c4e1ba731e47969d97bdb539/resources/phonenumber.proto#L36
	// Such numbers will just be discarded.
	//
	if (nationalNumber.length > MAX_LENGTH_FOR_NSN) {
		if (options.v2) {
			throw new ParseError('TOO_LONG')
		}
		// Google's demo just throws an error in this case.
		return {}
	}

	if (options.v2) {
		const phoneNumber = new PhoneNumber(
			countryCallingCode,
			nationalNumber,
			metadata.metadata
		)
		if (country) {
			phoneNumber.country = country
		}
		if (carrierCode) {
			phoneNumber.carrierCode = carrierCode
		}
		if (ext) {
			phoneNumber.ext = ext
		}
		phoneNumber.__countryCallingCodeSource = countryCallingCodeSource
		return phoneNumber
	}

	// Check if national phone number pattern matches the number.
	// National number pattern is different for each country,
	// even for those ones which are part of the "NANPA" group.
	const valid = (options.extended ? metadata.hasSelectedNumberingPlan() : country) ?
		matchesEntirely(nationalNumber, metadata.nationalNumberPattern()) :
		false

	if (!options.extended) {
		return valid ? result(country, nationalNumber, ext) : {}
	}

	// isInternational: countryCallingCode !== undefined

	return {
		country,
		countryCallingCode,
		carrierCode,
		valid,
		possible: valid ? true : (
			options.extended === true &&
			metadata.possibleLengths() &&
			isPossibleNumber(nationalNumber, metadata) ? true : false
		),
		phone: nationalNumber,
		ext
	}
}

/**
 * Extracts a formatted phone number from text.
 * Doesn't guarantee that the extracted phone number
 * is a valid phone number (for example, doesn't validate its length).
 * @param  {string} text
 * @param  {boolean} [extract] — If `false`, then will parse the entire `text` as a phone number.
 * @param  {boolean} [throwOnError] — By default, it won't throw if the text is too long.
 * @return {string}
 * @example
 * // Returns "(213) 373-4253".
 * extractFormattedPhoneNumber("Call (213) 373-4253 for assistance.")
 */
function extractFormattedPhoneNumber(text, extract, throwOnError) {
	if (!text) {
		return
	}
	if (text.length > MAX_INPUT_STRING_LENGTH) {
		if (throwOnError) {
			throw new ParseError('TOO_LONG')
		}
		return
	}
	if (extract === false) {
		return text
	}
	// Attempt to extract a possible number from the string passed in
	const startsAt = text.search(PHONE_NUMBER_START_PATTERN)
	if (startsAt < 0) {
		return
	}
	return text
		// Trim everything to the left of the phone number
		.slice(startsAt)
		// Remove trailing non-numerical characters
		.replace(AFTER_PHONE_NUMBER_END_PATTERN, '')
}

/**
 * @param  {string} text - Input.
 * @param  {boolean} v2 - Legacy API functions don't pass `v2: true` flag.
 * @param  {boolean} [extract] - Whether to extract a phone number from `text`, or attempt to parse the entire text as a phone number.
 * @return {object} `{ ?number, ?ext }`.
 */
function parseInput(text, v2, extract) {
	// // Parse RFC 3966 phone number URI.
	// if (text && text.indexOf('tel:') === 0) {
	// 	return parseRFC3966(text)
	// }
	// let number = extractFormattedPhoneNumber(text, extract, v2)
	let number = extractFormattedPhoneNumberFromPossibleRfc3966NumberUri(text, {
		extractFormattedPhoneNumber: (text) => extractFormattedPhoneNumber(text, extract, v2)
	})
	// If the phone number is not viable, then abort.
	if (!number) {
		return {}
	}
	if (!isViablePhoneNumber(number)) {
		if (isViablePhoneNumberStart(number)) {
			return { error: 'TOO_SHORT' }
		}
		return {}
	}
	// Attempt to parse extension first, since it doesn't require region-specific
	// data and we want to have the non-normalised number here.
	const withExtensionStripped = extractExtension(number)
	if (withExtensionStripped.ext) {
		return withExtensionStripped
	}
	return { number }
}

/**
 * Creates `parse()` result object.
 */
function result(country, nationalNumber, ext) {
	const result = {
		country,
		phone: nationalNumber
	}
	if (ext) {
		result.ext = ext
	}
	return result
}

/**
 * Parses a viable phone number.
 * @param {string} formattedPhoneNumber — Example: "(213) 373-4253".
 * @param {string} [defaultCountry]
 * @param {string} [defaultCallingCode]
 * @param {Metadata} metadata
 * @return {object} Returns `{ country: string?, countryCallingCode: string?, nationalNumber: string? }`.
 */
function parsePhoneNumber(
	formattedPhoneNumber,
	defaultCountry,
	defaultCallingCode,
	metadata
) {
	// Extract calling code from phone number.
	let { countryCallingCodeSource, countryCallingCode, number } = extractCountryCallingCode(
		parseIncompletePhoneNumber(formattedPhoneNumber),
		defaultCountry,
		defaultCallingCode,
		metadata.metadata
	)

	// Choose a country by `countryCallingCode`.
	let country
	if (countryCallingCode) {
		metadata.selectNumberingPlan(countryCallingCode)
	}
	// If `formattedPhoneNumber` is passed in "national" format
	// then `number` is defined and `countryCallingCode` is `undefined`.
	else if (number && (defaultCountry || defaultCallingCode)) {
		metadata.selectNumberingPlan(defaultCountry, defaultCallingCode)
		if (defaultCountry) {
			country = defaultCountry
		} else {
			/* istanbul ignore if */
			if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
				if (metadata.isNonGeographicCallingCode(defaultCallingCode)) {
					country = '001'
				}
			}
		}
		countryCallingCode = defaultCallingCode || getCountryCallingCode(defaultCountry, metadata.metadata)
	}
	else return {}

	if (!number) {
		return {
			countryCallingCodeSource,
			countryCallingCode
		}
	}

	const {
		nationalNumber,
		carrierCode
	} = extractNationalNumber(
		parseIncompletePhoneNumber(number),
		metadata
	)

	// Sometimes there are several countries
	// corresponding to the same country phone code
	// (e.g. NANPA countries all having `1` country phone code).
	// Therefore, to reliably determine the exact country,
	// national (significant) number should have been parsed first.
	//
	// When `metadata.json` is generated, all "ambiguous" country phone codes
	// get their countries populated with the full set of
	// "phone number type" regular expressions.
	//
	const exactCountry = getCountryByCallingCode(countryCallingCode, {
		nationalNumber,
		defaultCountry,
		metadata
	})
	if (exactCountry) {
		country = exactCountry
		/* istanbul ignore if */
		if (exactCountry === '001') {
			// Can't happen with `USE_NON_GEOGRAPHIC_COUNTRY_CODE` being `false`.
			// If `USE_NON_GEOGRAPHIC_COUNTRY_CODE` is set to `true` for some reason,
			// then remove the "istanbul ignore if".
		} else {
			metadata.country(country)
		}
	}

	return {
		country,
		countryCallingCode,
		countryCallingCodeSource,
		nationalNumber,
		carrierCode
	}
}