import PhoneNumberMatcher from '../PhoneNumberMatcher.js'
import normalizeArguments from '../normalizeArguments.js'

export default function findNumbers() {
	const { text, options, metadata } = normalizeArguments(arguments)
	const matcher = new PhoneNumberMatcher(text, options, metadata)
	const results = []
	while (matcher.hasNext()) {
		results.push(matcher.next())
	}
	return results
}