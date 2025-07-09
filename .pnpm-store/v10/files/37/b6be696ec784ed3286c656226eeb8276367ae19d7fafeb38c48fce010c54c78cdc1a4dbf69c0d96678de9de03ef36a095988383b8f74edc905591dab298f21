import normalizeArguments from './normalizeArguments.js'
import parsePhoneNumberWithError from './parsePhoneNumberWithError_.js'
import ParseError from './ParseError.js'
import Metadata from './metadata.js'
import checkNumberLength from './helpers/checkNumberLength.js'

export default function validatePhoneNumberLength() {
	let { text, options, metadata } = normalizeArguments(arguments)
	options = {
		...options,
		extract: false
	}

	// Parse phone number.
	try {
		const phoneNumber = parsePhoneNumberWithError(text, options, metadata)
		metadata = new Metadata(metadata)
		metadata.selectNumberingPlan(phoneNumber.countryCallingCode)
		const result = checkNumberLength(phoneNumber.nationalNumber, metadata)
		if (result !== 'IS_POSSIBLE') {
			return result
		}
	} catch (error) {
		/* istanbul ignore else */
		if (error instanceof ParseError) {
			return error.message
		} else {
			throw error
		}
	}
}