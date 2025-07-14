import Metadata from '../metadata.js'
import matchesEntirely from './matchesEntirely.js'
import extractNationalNumber from './extractNationalNumber.js'
import checkNumberLength from './checkNumberLength.js'
import getCountryCallingCode from '../getCountryCallingCode.js'

/**
 * Sometimes some people incorrectly input international phone numbers
 * without the leading `+`. This function corrects such input.
 * @param  {string} number — Phone number digits.
 * @param  {string?} country
 * @param  {string?} callingCode
 * @param  {object} metadata
 * @return {object} `{ countryCallingCode: string?, number: string }`.
 */
export default function extractCountryCallingCodeFromInternationalNumberWithoutPlusSign(
	number,
	country,
	callingCode,
	metadata
) {
	const countryCallingCode = country ? getCountryCallingCode(country, metadata) : callingCode
	if (number.indexOf(countryCallingCode) === 0) {
		metadata = new Metadata(metadata)
		metadata.selectNumberingPlan(country, callingCode)
		const possibleShorterNumber = number.slice(countryCallingCode.length)
		const {
			nationalNumber: possibleShorterNationalNumber,
		} = extractNationalNumber(
			possibleShorterNumber,
			metadata
		)
		const {
			nationalNumber
		} = extractNationalNumber(
			number,
			metadata
		)
		// If the number was not valid before but is valid now,
		// or if it was too long before, we consider the number
		// with the country calling code stripped to be a better result
		// and keep that instead.
		// For example, in Germany (+49), `49` is a valid area code,
		// so if a number starts with `49`, it could be both a valid
		// national German number or an international number without
		// a leading `+`.
		if (
			(
				!matchesEntirely(nationalNumber, metadata.nationalNumberPattern())
				&&
				matchesEntirely(possibleShorterNationalNumber, metadata.nationalNumberPattern())
			)
			||
			checkNumberLength(nationalNumber, metadata) === 'TOO_LONG'
		) {
			return {
				countryCallingCode,
				number: possibleShorterNumber
			}
		}
	}
	return { number }
}