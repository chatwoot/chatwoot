import normalizeArguments from './normalizeArguments.js'
import parsePhoneNumber from './parsePhoneNumber_.js'

export default function isValidPhoneNumber() {
	let { text, options, metadata } = normalizeArguments(arguments)
	options = {
		...options,
		extract: false
	}
	const phoneNumber = parsePhoneNumber(text, options, metadata)
	return phoneNumber && phoneNumber.isValid() || false
}