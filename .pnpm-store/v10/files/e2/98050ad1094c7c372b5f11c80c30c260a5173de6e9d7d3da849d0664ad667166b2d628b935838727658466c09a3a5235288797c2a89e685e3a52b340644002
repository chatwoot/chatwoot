import Metadata from '../metadata.js'
import matchesEntirely from './matchesEntirely.js'

const NON_FIXED_LINE_PHONE_TYPES = [
	'MOBILE',
	'PREMIUM_RATE',
	'TOLL_FREE',
	'SHARED_COST',
	'VOIP',
	'PERSONAL_NUMBER',
	'PAGER',
	'UAN',
	'VOICEMAIL'
]

// Finds out national phone number type (fixed line, mobile, etc)
export default function getNumberType(input, options, metadata)
{
	// If assigning the `{}` default value is moved to the arguments above,
	// code coverage would decrease for some weird reason.
	options = options || {}

	// When `parse()` returns an empty object — `{}` —
	// that means that the phone number is malformed,
	// so it can't possibly be valid.
	if (!input.country && !input.countryCallingCode) {
		return
	}

	metadata = new Metadata(metadata)

	metadata.selectNumberingPlan(input.country, input.countryCallingCode)

	const nationalNumber = options.v2 ? input.nationalNumber : input.phone

	// The following is copy-pasted from the original function:
	// https://github.com/googlei18n/libphonenumber/blob/3ea547d4fbaa2d0b67588904dfa5d3f2557c27ff/javascript/i18n/phonenumbers/phonenumberutil.js#L2835

	// Is this national number even valid for this country
	if (!matchesEntirely(nationalNumber, metadata.nationalNumberPattern())) {
		return
	}

	// Is it fixed line number
	if (isNumberTypeEqualTo(nationalNumber, 'FIXED_LINE', metadata)) {
		// Because duplicate regular expressions are removed
		// to reduce metadata size, if "mobile" pattern is ""
		// then it means it was removed due to being a duplicate of the fixed-line pattern.
		//
		if (metadata.type('MOBILE') && metadata.type('MOBILE').pattern() === '') {
			return 'FIXED_LINE_OR_MOBILE'
		}

		// `MOBILE` type pattern isn't included if it matched `FIXED_LINE` one.
		// For example, for "US" country.
		// Old metadata (< `1.0.18`) had a specific "types" data structure
		// that happened to be `undefined` for `MOBILE` in that case.
		// Newer metadata (>= `1.0.18`) has another data structure that is
		// not `undefined` for `MOBILE` in that case (it's just an empty array).
		// So this `if` is just for backwards compatibility with old metadata.
		if (!metadata.type('MOBILE')) {
			return 'FIXED_LINE_OR_MOBILE'
		}

		// Check if the number happens to qualify as both fixed line and mobile.
		// (no such country in the minimal metadata set)
		/* istanbul ignore if */
		if (isNumberTypeEqualTo(nationalNumber, 'MOBILE', metadata)) {
			return 'FIXED_LINE_OR_MOBILE'
		}

		return 'FIXED_LINE'
	}

	for (const type of NON_FIXED_LINE_PHONE_TYPES) {
		if (isNumberTypeEqualTo(nationalNumber, type, metadata)) {
			return type
		}
	}
}

export function isNumberTypeEqualTo(nationalNumber, type, metadata) {
	type = metadata.type(type)
	if (!type || !type.pattern()) {
		return false
	}
	// Check if any possible number lengths are present;
	// if so, we use them to avoid checking
	// the validation pattern if they don't match.
	// If they are absent, this means they match
	// the general description, which we have
	// already checked before a specific number type.
	if (type.possibleLengths() &&
		type.possibleLengths().indexOf(nationalNumber.length) < 0) {
		return false
	}
	return matchesEntirely(nationalNumber, type.pattern())
}