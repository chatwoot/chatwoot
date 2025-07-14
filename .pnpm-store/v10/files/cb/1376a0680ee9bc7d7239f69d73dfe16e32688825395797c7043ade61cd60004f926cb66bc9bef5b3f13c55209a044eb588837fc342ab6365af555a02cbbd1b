import parseIncompletePhoneNumber, { parsePhoneNumberCharacter } from './parseIncompletePhoneNumber.js'

describe('parseIncompletePhoneNumber', () => {
	it('should parse phone number character', () => {
		// Accepts leading `+`.
		parsePhoneNumberCharacter('+').should.equal('+')

		// Doesn't accept non-leading `+`.
		expect(parsePhoneNumberCharacter('+', '+')).to.be.undefined

		// Parses digits.
		parsePhoneNumberCharacter('1').should.equal('1')

		// Parses non-European digits.
		parsePhoneNumberCharacter('٤').should.equal('4')

		// Dismisses other characters.
		expect(parsePhoneNumberCharacter('-')).to.be.undefined
	})

	it('should parse incomplete phone number', () => {
		parseIncompletePhoneNumber('').should.equal('')

		// Doesn't accept non-leading `+`.
		parseIncompletePhoneNumber('++').should.equal('+')

		// Accepts leading `+`.
		parseIncompletePhoneNumber('+7 800 555').should.equal('+7800555')

		// Parses digits.
		parseIncompletePhoneNumber('8 (800) 555').should.equal('8800555')

		// Parses non-European digits.
		parseIncompletePhoneNumber('+٤٤٢٣٢٣٢٣٤').should.equal('+442323234')
	})

	it('should work with a new `context` argument in `parsePhoneNumberCharacter()` function (international number)', () => {
		let stopped = false

		const emit = (event) => {
			switch (event) {
				case 'end':
					stopped = true
					break
			}
		}

		parsePhoneNumberCharacter('+', undefined, emit).should.equal('+')
		expect(stopped).to.equal(false)

		parsePhoneNumberCharacter('1', '+', emit).should.equal('1')
		expect(stopped).to.equal(false)

		expect(parsePhoneNumberCharacter('+', '+1', emit)).to.equal(undefined)
		expect(stopped).to.equal(true)

		expect(parsePhoneNumberCharacter('2', '+1', emit)).to.equal('2')
		expect(stopped).to.equal(true)
	})

	it('should work with a new `context` argument in `parsePhoneNumberCharacter()` function (national number)', () => {
		let stopped = false

		const emit = (event) => {
			switch (event) {
				case 'end':
					stopped = true
					break
			}
		}

		parsePhoneNumberCharacter('2', undefined, emit).should.equal('2')
		expect(stopped).to.equal(false)

		expect(parsePhoneNumberCharacter('+', '2', emit)).to.equal(undefined)
		expect(stopped).to.equal(true)

		expect(parsePhoneNumberCharacter('1', '2', emit)).to.equal('1')
		expect(stopped).to.equal(true)
	})
})