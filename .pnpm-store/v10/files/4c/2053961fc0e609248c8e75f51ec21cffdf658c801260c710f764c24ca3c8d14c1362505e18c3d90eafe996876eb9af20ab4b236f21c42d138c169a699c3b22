// This function is copy-pasted from
// https://github.com/googlei18n/libphonenumber/blob/master/javascript/i18n/phonenumbers/phonenumberutil.js
// It hasn't been tested. It's not currently exported.
// Carriers codes aren't part of this library.
// Send a PR if you want to add them.

import Metadata from './metadata.js'
import format from './format.js'
import getNumberType from './helpers/getNumberType.js'
import checkNumberLength from './helpers/checkNumberLength.js'
import getCountryCallingCode from './getCountryCallingCode.js'

const REGION_CODE_FOR_NON_GEO_ENTITY = '001'

/**
 * Returns a number formatted in such a way that it can be dialed from a mobile
 * phone in a specific region. If the number cannot be reached from the region
 * (e.g. some countries block toll-free numbers from being called outside of the
 * country), the method returns an empty string.
 *
 * @param {object} number - a `parse()`d phone number to be formatted.
 * @param {string} from_country - the region where the call is being placed.
 * @param {boolean} with_formatting - whether the number should be returned with
 *     formatting symbols, such as spaces and dashes.
 * @return {string}
 */
export default function(number, from_country, with_formatting, metadata) {
	metadata = new Metadata(metadata)

	// Validate `from_country`.
	if (!metadata.hasCountry(from_country)) {
		throw new Error(`Unknown country: ${from_country}`)
	}

	// Not using the extension, as that part cannot normally be dialed
	// together with the main number.
	number = {
		phone: number.phone,
		country: number.country
	}

	const number_type = getNumberType(number, undefined, metadata.metadata)
	const is_valid_number = number_type === number

	let formatted_number

	if (country === from_country) {
		const is_fixed_line_or_mobile =
			number_type === 'FIXED_LINE' ||
			number_type === 'MOBILE' ||
			number_type === 'FIXED_LINE_OR_MOBILE'

		// Carrier codes may be needed in some countries. We handle this here.
		if (country == 'BR' && is_fixed_line_or_mobile) {
			formatted_number =
				carrierCode ?
				formatNationalNumberWithPreferredCarrierCode(number) :
				// Brazilian fixed line and mobile numbers need to be dialed with a
				// carrier code when called within Brazil. Without that, most of the
				// carriers won't connect the call. Because of that, we return an
				// empty string here.
				''
		} else if (getCountryCallingCode(country, metadata.metadata) === '1') {
			// For NANPA countries, we output international format for numbers that
			// can be dialed internationally, since that always works, except for
			// numbers which might potentially be short numbers, which are always
			// dialled in national format.

			// Select country for `checkNumberLength()`.
			metadata.country(country)

			if (can_be_internationally_dialled(number) &&
				checkNumberLength(number.phone, metadata) !== 'TOO_SHORT') {
				formatted_number = format(number, 'INTERNATIONAL', metadata.metadata)
			}
			else {
				formatted_number = format(number, 'NATIONAL', metadata.metadata)
			}
		}
		else {
			// For non-geographic countries, Mexican and Chilean fixed line and
			// mobile numbers, we output international format for numbers that can be
			// dialed internationally, as that always works.
			if (
				(
					country === REGION_CODE_FOR_NON_GEO_ENTITY
					||
					// MX fixed line and mobile numbers should always be formatted in
					// international format, even when dialed within MX. For national
					// format to work, a carrier code needs to be used, and the correct
					// carrier code depends on if the caller and callee are from the
					// same local area. It is trickier to get that to work correctly than
					// using international format, which is tested to work fine on all
					// carriers.
					//
					// CL fixed line numbers need the national prefix when dialing in the
					// national format, but don't have it when used for display. The
					// reverse is true for mobile numbers. As a result, we output them in
					// the international format to make it work.
					//
					// UZ mobile and fixed-line numbers have to be formatted in
					// international format or prefixed with special codes like 03, 04
					// (for fixed-line) and 05 (for mobile) for dialling successfully
					// from mobile devices. As we do not have complete information on
					// special codes and to be consistent with formatting across all
					// phone types we return the number in international format here.
					//
					((country === 'MX' || country === 'CL' || country == 'UZ') && is_fixed_line_or_mobile)
				)
				&&
				can_be_internationally_dialled(number)
			) {
				formatted_number = format(number, 'INTERNATIONAL')
			}
			else {
				formatted_number = format(number, 'NATIONAL')
			}
		}
	}
	else if (is_valid_number && can_be_internationally_dialled(number)) {
		// We assume that short numbers are not diallable from outside their region,
		// so if a number is not a valid regular length phone number, we treat it as
		// if it cannot be internationally dialled.
		return with_formatting ?
			format(number, 'INTERNATIONAL', metadata.metadata) :
			format(number, 'E.164', metadata.metadata)
	}

	if (!with_formatting) {
		return diallable_chars(formatted_number)
	}

	return formatted_number
}

function can_be_internationally_dialled(number) {
	return true
}

/**
 * A map that contains characters that are essential when dialling. That means
 * any of the characters in this map must not be removed from a number when
 * dialling, otherwise the call will not reach the intended destination.
 */
const DIALLABLE_CHARACTERS = {
	'0': '0',
	'1': '1',
	'2': '2',
	'3': '3',
	'4': '4',
	'5': '5',
	'6': '6',
	'7': '7',
	'8': '8',
	'9': '9',
	'+': '+',
	'*': '*',
	'#': '#'
}

function diallable_chars(formatted_number) {
	let result = ''

	let i = 0
	while (i < formatted_number.length) {
		const character = formatted_number[i]
		if (DIALLABLE_CHARACTERS[character]) {
			result += character
		}
		i++
	}

	return result
}

function getPreferredDomesticCarrierCodeOrDefault() {
	throw new Error('carrier codes are not part of this library')
}

function formatNationalNumberWithCarrierCode() {
	throw new Error('carrier codes are not part of this library')
}

/**
 * Formats a phone number in national format for dialing using the carrier as
 * specified in the preferred_domestic_carrier_code field of the PhoneNumber
 * object passed in. If that is missing, use the {@code fallbackCarrierCode}
 * passed in instead. If there is no {@code preferred_domestic_carrier_code},
 * and the {@code fallbackCarrierCode} contains an empty string, return the
 * number in national format without any carrier code.
 *
 * <p>Use {@link #formatNationalNumberWithCarrierCode} instead if the carrier
 * code passed in should take precedence over the number's
 * {@code preferred_domestic_carrier_code} when formatting.
 *
 * @param {i18n.phonenumbers.PhoneNumber} number the phone number to be
 *     formatted.
 * @param {string} fallbackCarrierCode the carrier selection code to be used, if
 *     none is found in the phone number itself.
 * @return {string} the formatted phone number in national format for dialing
 *     using the number's preferred_domestic_carrier_code, or the
 *     {@code fallbackCarrierCode} passed in if none is found.
 */
function formatNationalNumberWithPreferredCarrierCode(number) {
	return formatNationalNumberWithCarrierCode(
		number,
		carrierCode
	);
}