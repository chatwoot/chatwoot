import PhoneNumberMatcher from './PhoneNumberMatcher.js'
import normalizeArguments from './normalizeArguments.js'

export default function findPhoneNumbersInText() {
	const { text, options, metadata } = normalizeArguments(arguments)
	const matcher = new PhoneNumberMatcher(text, { ...options, v2: true }, metadata)
	const results = []
	while (matcher.hasNext()) {
		results.push(matcher.next())
	}
	return results
}