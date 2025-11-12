import matchesEntirely from './matchesEntirely.js'

describe('matchesEntirely', () => {
	it('should work in edge cases', () => {
		// No text.
		matchesEntirely(undefined, '').should.equal(true)

		// "OR" in regexp.
		matchesEntirely('911231231', '4\d{8}|[1-9]\d{7}').should.equal(false)
	})
})