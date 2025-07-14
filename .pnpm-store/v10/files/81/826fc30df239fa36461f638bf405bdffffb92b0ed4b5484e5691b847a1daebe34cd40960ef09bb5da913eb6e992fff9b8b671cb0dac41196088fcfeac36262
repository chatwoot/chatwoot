import PatternParser from './AsYouTypeFormatter.PatternParser.js'

export default class PatternMatcher {
	constructor(pattern) {
		this.matchTree = new PatternParser().parse(pattern)
	}

	match(string, { allowOverflow } = {}) {
		if (!string) {
			throw new Error('String is required')
		}
		const result = match(string.split(''), this.matchTree, true)
		if (result && result.match) {
			delete result.matchedChars
		}
		if (result && result.overflow) {
			if (!allowOverflow) {
				return
			}
		}
		return result
	}
}

/**
 * Matches `characters` against a pattern compiled into a `tree`.
 * @param  {string[]} characters
 * @param  {Tree} tree — A pattern compiled into a `tree`. See the `*.d.ts` file for the description of the `tree` structure.
 * @param  {boolean} last — Whether it's the last (rightmost) subtree on its level of the match tree.
 * @return {object} See the `*.d.ts` file for the description of the result object.
 */
function match(characters, tree, last) {
	// If `tree` is a string, then `tree` is a single character.
	// That's because when a pattern is parsed, multi-character-string parts
	// of a pattern are compiled into arrays of single characters.
	// I still wrote this piece of code for a "general" hypothetical case
	// when `tree` could be a string of several characters, even though
	// such case is not possible with the current implementation.
	if (typeof tree === 'string') {
		const characterString = characters.join('')
		if (tree.indexOf(characterString) === 0) {
			// `tree` is always a single character.
			// If `tree.indexOf(characterString) === 0`
			// then `characters.length === tree.length`.
			/* istanbul ignore else */
			if (characters.length === tree.length) {
				return {
					match: true,
					matchedChars: characters
				}
			}
			// `tree` is always a single character.
			// If `tree.indexOf(characterString) === 0`
			// then `characters.length === tree.length`.
			/* istanbul ignore next */
			return {
				partialMatch: true,
				// matchedChars: characters
			}
		}
		if (characterString.indexOf(tree) === 0) {
			if (last) {
				// The `else` path is not possible because `tree` is always a single character.
				// The `else` case for `characters.length > tree.length` would be
				// `characters.length <= tree.length` which means `characters.length <= 1`.
				// `characters` array can't be empty, so that means `characters === [tree]`,
				// which would also mean `tree.indexOf(characterString) === 0` and that'd mean
				// that the `if (tree.indexOf(characterString) === 0)` condition before this
				// `if` condition would be entered, and returned from there, not reaching this code.
				/* istanbul ignore else */
				if (characters.length > tree.length) {
					return {
						overflow: true
					}
				}
			}
			return {
				match: true,
				matchedChars: characters.slice(0, tree.length)
			}
		}
		return
	}

	if (Array.isArray(tree)) {
		let restCharacters = characters.slice()
		let i = 0
		while (i < tree.length) {
			const subtree = tree[i]
			const result = match(restCharacters, subtree, last && (i === tree.length - 1))
			if (!result) {
				return
			} else if (result.overflow) {
				return result
			} else if (result.match) {
				// Continue with the next subtree with the rest of the characters.
				restCharacters = restCharacters.slice(result.matchedChars.length)
				if (restCharacters.length === 0) {
					if (i === tree.length - 1) {
						return {
							match: true,
							matchedChars: characters
						}
					} else {
						return {
							partialMatch: true,
							// matchedChars: characters
						}
					}
				}
			} else {
				/* istanbul ignore else */
				if (result.partialMatch) {
					return {
						partialMatch: true,
						// matchedChars: characters
					}
				} else {
					throw new Error(`Unsupported match result:\n${JSON.stringify(result, null, 2)}`)
				}
			}
			i++
		}
		// If `last` then overflow has already been checked
		// by the last element of the `tree` array.
		/* istanbul ignore if */
		if (last) {
			return {
				overflow: true
			}
		}
		return {
			match: true,
			matchedChars: characters.slice(0, characters.length - restCharacters.length)
		}
	}

	switch (tree.op) {
		case '|':
			let partialMatch
			for (const branch of tree.args) {
				const result = match(characters, branch, last)
				if (result) {
					if (result.overflow) {
						return result
					} else if (result.match) {
						return {
							match: true,
							matchedChars: result.matchedChars
						}
					} else {
						/* istanbul ignore else */
						if (result.partialMatch) {
							partialMatch = true
						} else {
							throw new Error(`Unsupported match result:\n${JSON.stringify(result, null, 2)}`)
						}
					}
				}
			}
			if (partialMatch) {
				return {
					partialMatch: true,
					// matchedChars: ...
				}
			}
			// Not even a partial match.
			return

		case '[]':
			for (const char of tree.args) {
				if (characters[0] === char) {
					if (characters.length === 1) {
						return {
							match: true,
							matchedChars: characters
						}
					}
					if (last) {
						return {
							overflow: true
						}
					}
					return {
						match: true,
						matchedChars: [char]
					}
				}
			}
			// No character matches.
			return

		/* istanbul ignore next */
		default:
			throw new Error(`Unsupported instruction tree: ${tree}`)
	}
}