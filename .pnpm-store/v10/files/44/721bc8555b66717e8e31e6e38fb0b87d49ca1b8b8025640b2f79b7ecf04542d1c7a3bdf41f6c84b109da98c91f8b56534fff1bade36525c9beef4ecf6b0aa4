import normalizeArguments from '../normalizeArguments.js'
import PhoneNumberMatcher from '../PhoneNumberMatcher.js'

/**
 * @return ES6 `for ... of` iterator.
 */
export default function searchNumbers()
{
	const { text, options, metadata } = normalizeArguments(arguments)

	const matcher = new PhoneNumberMatcher(text, options, metadata)

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
