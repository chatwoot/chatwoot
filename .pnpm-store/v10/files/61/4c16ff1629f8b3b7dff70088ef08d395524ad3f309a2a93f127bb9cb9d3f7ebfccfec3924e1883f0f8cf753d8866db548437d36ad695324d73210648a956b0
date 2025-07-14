import _isValidNumber from '../isValid.js'
import { normalizeArguments } from './getNumberType.js'

// Finds out national phone number type (fixed line, mobile, etc)
export default function isValidNumber() {
	const { input, options, metadata } = normalizeArguments(arguments)
	// `parseNumber()` would return `{}` when no phone number could be parsed from the input.
	if (!input.phone) {
		return false
	}
	return _isValidNumber(input, options, metadata)
}