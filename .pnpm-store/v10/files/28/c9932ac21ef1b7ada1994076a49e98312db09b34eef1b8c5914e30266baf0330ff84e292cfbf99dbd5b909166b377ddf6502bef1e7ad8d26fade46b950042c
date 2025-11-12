import Metadata from '../metadata.js'
import { VALID_DIGITS } from '../constants.js'

const CAPTURING_DIGIT_PATTERN = new RegExp('([' + VALID_DIGITS + '])')

export default function stripIddPrefix(number, country, callingCode, metadata) {
	if (!country) {
		return
	}
	// Check if the number is IDD-prefixed.
	const countryMetadata = new Metadata(metadata)
	countryMetadata.selectNumberingPlan(country, callingCode)
	const IDDPrefixPattern = new RegExp(countryMetadata.IDDPrefix())
	if (number.search(IDDPrefixPattern) !== 0) {
		return
	}
	// Strip IDD prefix.
	number = number.slice(number.match(IDDPrefixPattern)[0].length)
	// If there're any digits after an IDD prefix,
	// then those digits are a country calling code.
	// Since no country code starts with a `0`,
	// the code below validates that the next digit (if present) is not `0`.
	const matchedGroups = number.match(CAPTURING_DIGIT_PATTERN)
	if (matchedGroups && matchedGroups[1] != null && matchedGroups[1].length > 0) {
		if (matchedGroups[1] === '0') {
			return
		}
	}
	return number
}