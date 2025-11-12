// This is a legacy function.
// Use `findNumbers()` instead.

import {
	PLUS_CHARS,
	VALID_PUNCTUATION,
	VALID_DIGITS,
	WHITESPACE
} from '../constants.js'

import parse from '../parse.js'
import { VALID_PHONE_NUMBER_WITH_EXTENSION } from '../helpers/isViablePhoneNumber.js'
import createExtensionPattern from '../helpers/extension/createExtensionPattern.js'

import parsePreCandidate from '../findNumbers/parsePreCandidate.js'
import isValidPreCandidate from '../findNumbers/isValidPreCandidate.js'
import isValidCandidate from '../findNumbers/isValidCandidate.js'

/**
 * Regexp of all possible ways to write extensions, for use when parsing. This
 * will be run as a case-insensitive regexp match. Wide character versions are
 * also provided after each ASCII version. There are three regular expressions
 * here. The first covers RFC 3966 format, where the extension is added using
 * ';ext='. The second more generic one starts with optional white space and
 * ends with an optional full stop (.), followed by zero or more spaces/tabs
 * /commas and then the numbers themselves. The other one covers the special
 * case of American numbers where the extension is written with a hash at the
 * end, such as '- 503#'. Note that the only capturing groups should be around
 * the digits that you want to capture as part of the extension, or else parsing
 * will fail! We allow two options for representing the accented o - the
 * character itself, and one in the unicode decomposed form with the combining
 * acute accent.
 */
export const EXTN_PATTERNS_FOR_PARSING = createExtensionPattern('parsing')

const WHITESPACE_IN_THE_BEGINNING_PATTERN = new RegExp('^[' + WHITESPACE + ']+')
const PUNCTUATION_IN_THE_END_PATTERN = new RegExp('[' + VALID_PUNCTUATION + ']+$')

// // Regular expression for getting opening brackets for a valid number
// // found using `PHONE_NUMBER_START_PATTERN` for prepending those brackets to the number.
// const BEFORE_NUMBER_DIGITS_PUNCTUATION = new RegExp('[' + OPENING_BRACKETS + ']+' + '[' + WHITESPACE + ']*' + '$')

const VALID_PRECEDING_CHARACTER_PATTERN = /[^a-zA-Z0-9]/

export default function findPhoneNumbers(text, options, metadata) {
	/* istanbul ignore if */
	if (options === undefined) {
		options = {}
	}
	const search = new PhoneNumberSearch(text, options, metadata)
	const phones = []
	while (search.hasNext()) {
		phones.push(search.next())
	}
	return phones
}

/**
 * @return ES6 `for ... of` iterator.
 */
export function searchPhoneNumbers(text, options, metadata) {
	/* istanbul ignore if */
	if (options === undefined) {
		options = {}
	}
	const search = new PhoneNumberSearch(text, options, metadata)
	return  {
		[Symbol.iterator]() {
			return {
	    		next: () => {
	    			if (search.hasNext()) {
						return {
							done: false,
							value: search.next()
						}
					}
					return {
						done: true
					}
	    		}
			}
		}
	}
}

/**
 * Extracts a parseable phone number including any opening brackets, etc.
 * @param  {string} text - Input.
 * @return {object} `{ ?number, ?startsAt, ?endsAt }`.
 */
export class PhoneNumberSearch {
	constructor(text, options, metadata) {
		this.text = text
		// If assigning the `{}` default value is moved to the arguments above,
		// code coverage would decrease for some weird reason.
		this.options = options || {}
		this.metadata = metadata

		// Iteration tristate.
		this.state = 'NOT_READY'

		this.regexp = new RegExp(VALID_PHONE_NUMBER_WITH_EXTENSION, 'ig')
	}

	find() {
		const matches = this.regexp.exec(this.text)
		if (!matches) {
			return
		}

		let number = matches[0]
		let startsAt = matches.index

		number = number.replace(WHITESPACE_IN_THE_BEGINNING_PATTERN, '')
		startsAt += matches[0].length - number.length
		// Fixes not parsing numbers with whitespace in the end.
		// Also fixes not parsing numbers with opening parentheses in the end.
		// https://github.com/catamphetamine/libphonenumber-js/issues/252
		number = number.replace(PUNCTUATION_IN_THE_END_PATTERN, '')

		number = parsePreCandidate(number)

		const result = this.parseCandidate(number, startsAt)
		if (result) {
			return result
		}

		// Tail recursion.
		// Try the next one if this one is not a valid phone number.
		return this.find()
	}

	parseCandidate(number, startsAt) {
		if (!isValidPreCandidate(number, startsAt, this.text)) {
			return
		}

		// Don't parse phone numbers which are non-phone numbers
		// due to being part of something else (e.g. a UUID).
		// https://github.com/catamphetamine/libphonenumber-js/issues/213
		// Copy-pasted from Google's `PhoneNumberMatcher.js` (`.parseAndValidate()`).
		if (!isValidCandidate(number, startsAt, this.text, this.options.extended ? 'POSSIBLE' : 'VALID')) {
			return
		}

		// // Prepend any opening brackets left behind by the
		// // `PHONE_NUMBER_START_PATTERN` regexp.
		// const text_before_number = text.slice(this.searching_from, startsAt)
		// const full_number_starts_at = text_before_number.search(BEFORE_NUMBER_DIGITS_PUNCTUATION)
		// if (full_number_starts_at >= 0)
		// {
		// 	number   = text_before_number.slice(full_number_starts_at) + number
		// 	startsAt = full_number_starts_at
		// }
		//
		// this.searching_from = matches.lastIndex

		const result = parse(number, this.options, this.metadata)
		if (!result.phone) {
			return
		}

		result.startsAt = startsAt
		result.endsAt = startsAt + number.length
		return result
	}

	hasNext() {
		if (this.state === 'NOT_READY') {
			this.last_match = this.find()
			if (this.last_match) {
				this.state = 'READY'
			} else {
				this.state = 'DONE'
			}
		}
		return this.state === 'READY'
	}

	next() {
		// Check the state and find the next match as a side-effect if necessary.
		if (!this.hasNext()) {
			throw new Error('No next element')
		}
		// Don't retain that memory any longer than necessary.
		const result = this.last_match
		this.last_match = null
		this.state = 'NOT_READY'
		return result
	}
}