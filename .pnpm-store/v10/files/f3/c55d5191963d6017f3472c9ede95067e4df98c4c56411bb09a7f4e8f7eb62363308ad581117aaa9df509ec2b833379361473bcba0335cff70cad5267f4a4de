// Should be the same as `DIGIT_PLACEHOLDER` in `libphonenumber-metadata-generator`.
export const DIGIT_PLACEHOLDER = 'x' // '\u2008' (punctuation space)
const DIGIT_PLACEHOLDER_MATCHER = new RegExp(DIGIT_PLACEHOLDER)

// Counts all occurences of a symbol in a string.
// Unicode-unsafe (because using `.split()`).
export function countOccurences(symbol, string) {
	let count = 0
	// Using `.split('')` to iterate through a string here
	// to avoid requiring `Symbol.iterator` polyfill.
	// `.split('')` is generally not safe for Unicode,
	// but in this particular case for counting brackets it is safe.
	// for (const character of string)
	for (const character of string.split('')) {
		if (character === symbol) {
			count++
		}
	}
	return count
}

// Repeats a string (or a symbol) N times.
// http://stackoverflow.com/questions/202605/repeat-string-javascript
export function repeat(string, times) {
	if (times < 1) {
		return ''
	}
	let result = ''
	while (times > 1) {
		if (times & 1) {
			result += string
		}
		times >>= 1
		string += string
	}
	return result + string
}

export function cutAndStripNonPairedParens(string, cutBeforeIndex) {
	if (string[cutBeforeIndex] === ')') {
		cutBeforeIndex++
	}
	return stripNonPairedParens(string.slice(0, cutBeforeIndex))
}

export function closeNonPairedParens(template, cut_before) {
	const retained_template = template.slice(0, cut_before)
	const opening_braces = countOccurences('(', retained_template)
	const closing_braces = countOccurences(')', retained_template)
	let dangling_braces = opening_braces - closing_braces
	while (dangling_braces > 0 && cut_before < template.length) {
		if (template[cut_before] === ')') {
			dangling_braces--
		}
		cut_before++
	}
	return template.slice(0, cut_before)
}

export function stripNonPairedParens(string) {
	const dangling_braces =[]
	let i = 0
	while (i < string.length) {
		if (string[i] === '(') {
			dangling_braces.push(i)
		}
		else if (string[i] === ')') {
			dangling_braces.pop()
		}
		i++
	}
	let start = 0
	let cleared_string = ''
	dangling_braces.push(string.length)
	for (const index of dangling_braces) {
		cleared_string += string.slice(start, index)
		start = index + 1
	}
	return cleared_string
}

export function populateTemplateWithDigits(template, position, digits) {
	// Using `.split('')` to iterate through a string here
	// to avoid requiring `Symbol.iterator` polyfill.
	// `.split('')` is generally not safe for Unicode,
	// but in this particular case for `digits` it is safe.
	// for (const digit of digits)
	for (const digit of digits.split('')) {
		// If there is room for more digits in current `template`,
		// then set the next digit in the `template`,
		// and return the formatted digits so far.
		// If more digits are entered than the current format could handle.
		if (template.slice(position + 1).search(DIGIT_PLACEHOLDER_MATCHER) < 0) {
			return
		}
		position = template.search(DIGIT_PLACEHOLDER_MATCHER)
		template = template.replace(DIGIT_PLACEHOLDER_MATCHER, digit)
	}
	return [template, position]
}