import parsePhoneNumberWithError from './parsePhoneNumberWithError_.js'
import ParseError from './ParseError.js'
import { isSupportedCountry } from './metadata.js'

export default function parsePhoneNumber(text, options, metadata) {
	// Validate `defaultCountry`.
	if (options && options.defaultCountry && !isSupportedCountry(options.defaultCountry, metadata)) {
		options = {
			...options,
			defaultCountry: undefined
		}
	}
	// Parse phone number.
	try {
		return parsePhoneNumberWithError(text, options, metadata)
	} catch (error) {
		/* istanbul ignore else */
		if (error instanceof ParseError) {
			//
		} else {
			throw error
		}
	}
}
