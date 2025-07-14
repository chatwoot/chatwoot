import normalizeArguments from './normalizeArguments.js'
import parsePhoneNumber from './parsePhoneNumber_.js'

export default function isPossiblePhoneNumber() {
	let { text, options, metadata } = normalizeArguments(arguments)
	options = {
		...options,
		extract: false
	}
	const phoneNumber = parsePhoneNumber(text, options, metadata)
	return phoneNumber && phoneNumber.isPossible() || false
}