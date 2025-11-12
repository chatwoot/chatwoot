import { parseDigit } from './helpers/parseDigits.js'

/**
 * Parses phone number characters from a string.
 * Drops all punctuation leaving only digits and the leading `+` sign (if any).
 * Also converts wide-ascii and arabic-indic numerals to conventional numerals.
 * E.g. in Iraq they don't write `+442323234` but rather `+٤٤٢٣٢٣٢٣٤`.
 * @param  {string} string
 * @return {string}
 * @example
 * ```js
 * // Outputs '8800555'.
 * parseIncompletePhoneNumber('8 (800) 555')
 * // Outputs '+7800555'.
 * parseIncompletePhoneNumber('+7 800 555')
 * ```
 */
export default function parseIncompletePhoneNumber(string) {
	let result = ''
	// Using `.split('')` here instead of normal `for ... of`
	// because the importing application doesn't neccessarily include an ES6 polyfill.
	// The `.split('')` approach discards "exotic" UTF-8 characters
	// (the ones consisting of four bytes) but digits
	// (including non-European ones) don't fall into that range
	// so such "exotic" characters would be discarded anyway.
	for (const character of string.split('')) {
		result += parsePhoneNumberCharacter(character, result) || ''
	}
	return result
}

/**
 * Parses next character while parsing phone number digits (including a `+`)
 * from text: discards everything except `+` and digits, and `+` is only allowed
 * at the start of a phone number.
 * For example, is used in `react-phone-number-input` where it uses
 * [`input-format`](https://gitlab.com/catamphetamine/input-format).
 * @param  {string} character - Yet another character from raw input string.
 * @param  {string?} prevParsedCharacters - Previous parsed characters.
 * @param  {function?} emitEvent - An optional "emit event" function.
 * @return {string?} The parsed character.
 */
export function parsePhoneNumberCharacter(character, prevParsedCharacters, emitEvent) {
	// Only allow a leading `+`.
	if (character === '+') {
		// If this `+` is not the first parsed character
		// then discard it.
		if (prevParsedCharacters) {
			// `emitEvent` argument was added to this `export`ed function on Dec 26th, 2023.
			// Any 3rd-party code that used to `import` and call this function before that
			// won't be passing any `emitEvent` argument.
			//
			// The addition of the `emitEvent` argument was to fix the slightly-weird behavior
			// of parsing an input string when the user inputs something like `"2+7"
			// https://github.com/catamphetamine/react-phone-number-input/issues/437
			//
			// If the parser encounters an unexpected `+` in a string being parsed
			// then it simply discards that out-of-place `+` and any following characters.
			//
			if (typeof emitEvent === 'function') {
				emitEvent('end')
			}
			return
		}
		return '+'
	}
	// Allow digits.
	return parseDigit(character)
}