export default class PatternParser {
	parse(pattern) {
		this.context = [{
			or: true,
			instructions: []
		}]

		this.parsePattern(pattern)

		if (this.context.length !== 1) {
			throw new Error('Non-finalized contexts left when pattern parse ended')
		}

		const { branches, instructions } = this.context[0]

		if (branches) {
			return {
				op: '|',
				args: branches.concat([
					expandSingleElementArray(instructions)
				])
			}
		}

		/* istanbul ignore if */
		if (instructions.length === 0) {
			throw new Error('Pattern is required')
		}

		if (instructions.length === 1) {
			return instructions[0]
		}

		return instructions
	}

	startContext(context) {
		this.context.push(context)
	}

	endContext() {
		this.context.pop()
	}

	getContext() {
		return this.context[this.context.length - 1]
	}

	parsePattern(pattern) {
		if (!pattern) {
			throw new Error('Pattern is required')
		}

		const match = pattern.match(OPERATOR)
		if (!match) {
			if (ILLEGAL_CHARACTER_REGEXP.test(pattern)) {
				throw new Error(`Illegal characters found in a pattern: ${pattern}`)
			}
			this.getContext().instructions = this.getContext().instructions.concat(
				pattern.split('')
			)
			return
		}

		const operator = match[1]
		const before = pattern.slice(0, match.index)
		const rightPart = pattern.slice(match.index + operator.length)

		switch (operator) {
			case '(?:':
				if (before) {
					this.parsePattern(before)
				}
				this.startContext({
					or: true,
					instructions: [],
					branches: []
				})
				break

			case ')':
				if (!this.getContext().or) {
					throw new Error('")" operator must be preceded by "(?:" operator')
				}
				if (before) {
					this.parsePattern(before)
				}
				if (this.getContext().instructions.length === 0) {
					throw new Error('No instructions found after "|" operator in an "or" group')
				}
				const { branches } = this.getContext()
				branches.push(
					expandSingleElementArray(
						this.getContext().instructions
					)
				)
				this.endContext()
				this.getContext().instructions.push({
					op: '|',
					args: branches
				})
				break

			case '|':
				if (!this.getContext().or) {
					throw new Error('"|" operator can only be used inside "or" groups')
				}
				if (before) {
					this.parsePattern(before)
				}
				// The top-level is an implicit "or" group, if required.
				if (!this.getContext().branches) {
					// `branches` are not defined only for the root implicit "or" operator.
					/* istanbul ignore else */
					if (this.context.length === 1) {
						this.getContext().branches = []
					} else {
						throw new Error('"branches" not found in an "or" group context')
					}
				}
				this.getContext().branches.push(
					expandSingleElementArray(
						this.getContext().instructions
					)
				)
				this.getContext().instructions = []
				break

			case '[':
				if (before) {
					this.parsePattern(before)
				}
				this.startContext({
					oneOfSet: true
				})
				break

			case ']':
				if (!this.getContext().oneOfSet) {
					throw new Error('"]" operator must be preceded by "[" operator')
				}
				this.endContext()
				this.getContext().instructions.push({
					op: '[]',
					args: parseOneOfSet(before)
				})
				break

			/* istanbul ignore next */
			default:
				throw new Error(`Unknown operator: ${operator}`)
		}

		if (rightPart) {
			this.parsePattern(rightPart)
		}
	}
}

function parseOneOfSet(pattern) {
	const values = []
	let i = 0
	while (i < pattern.length) {
		if (pattern[i] === '-') {
			if (i === 0 || i === pattern.length - 1) {
				throw new Error(`Couldn't parse a one-of set pattern: ${pattern}`)
			}
			const prevValue = pattern[i - 1].charCodeAt(0) + 1
			const nextValue = pattern[i + 1].charCodeAt(0) - 1
			let value = prevValue
			while (value <= nextValue) {
				values.push(String.fromCharCode(value))
				value++
			}
		} else {
			values.push(pattern[i])
		}
		i++
	}
	return values
}

const ILLEGAL_CHARACTER_REGEXP = /[\(\)\[\]\?\:\|]/

const OPERATOR = new RegExp(
	// any of:
	'(' +
		// or operator
		'\\|' +
		// or
		'|' +
		// or group start
		'\\(\\?\\:' +
		// or
		'|' +
		// or group end
		'\\)' +
		// or
		'|' +
		// one-of set start
		'\\[' +
		// or
		'|' +
		// one-of set end
		'\\]' +
	')'
)

function expandSingleElementArray(array) {
	if (array.length === 1) {
		return array[0]
	}
	return array
}