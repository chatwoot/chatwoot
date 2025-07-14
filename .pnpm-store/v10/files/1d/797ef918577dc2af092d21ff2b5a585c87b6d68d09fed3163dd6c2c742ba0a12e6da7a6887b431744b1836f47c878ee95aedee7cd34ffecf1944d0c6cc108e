import LRUCache from './LRUCache.js'

// A cache for frequently used country-specific regular expressions. Set to 32 to cover ~2-3
// countries being used for the same doc with ~10 patterns for each country. Some pages will have
// a lot more countries in use, but typically fewer numbers for each so expanding the cache for
// that use-case won't have a lot of benefit.
export default class RegExpCache {
	constructor(size) {
		this.cache = new LRUCache(size)
	}

	getPatternForRegExp(pattern) {
		let regExp = this.cache.get(pattern)
		if (!regExp) {
			regExp = new RegExp('^' + pattern)
			this.cache.put(pattern, regExp)
		}
		return regExp
	}
}