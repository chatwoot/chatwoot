import parseComponent from './parseComponent'

/**
 * Determines if the given code is a VueSfc file
 * It does not throw if the code is invalid, just returns `false`
 * @param code JavaScript or vue code to analyze
 */
export default function isCodeVueSfc(code: string): boolean {
	const parts = parseComponent(code)
	return !!parts.script || !!parts.template
}
