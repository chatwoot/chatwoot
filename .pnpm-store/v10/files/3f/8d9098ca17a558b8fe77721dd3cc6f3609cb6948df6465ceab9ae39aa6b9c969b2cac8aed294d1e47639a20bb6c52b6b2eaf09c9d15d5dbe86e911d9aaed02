import PhoneNumberMatcher from './PhoneNumberMatcher.js'
import normalizeArguments from './normalizeArguments.js'

export default function searchPhoneNumbersInText() {
	const { text, options, metadata } = normalizeArguments(arguments)
	const matcher = new PhoneNumberMatcher(text, { ...options, v2: true }, metadata)
	return  {
		[Symbol.iterator]() {
			return {
	    		next: () => {
	    			if (matcher.hasNext()) {
						return {
							done: false,
							value: matcher.next()
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