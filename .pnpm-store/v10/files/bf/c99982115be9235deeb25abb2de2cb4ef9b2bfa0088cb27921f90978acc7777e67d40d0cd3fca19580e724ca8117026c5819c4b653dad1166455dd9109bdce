// This is a legacy function.
// Use `findNumbers()` instead.

import _findPhoneNumbers, { searchPhoneNumbers as _searchPhoneNumbers } from './findPhoneNumbersInitialImplementation.js'
import normalizeArguments from '../normalizeArguments.js'

export default function findPhoneNumbers()
{
	const { text, options, metadata } = normalizeArguments(arguments)
	return _findPhoneNumbers(text, options, metadata)
}

/**
 * @return ES6 `for ... of` iterator.
 */
export function searchPhoneNumbers()
{
	const { text, options, metadata } = normalizeArguments(arguments)
	return _searchPhoneNumbers(text, options, metadata)
}