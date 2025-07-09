import metadata from '../metadata.min.json' assert { type: 'json' }
import _isPossibleNumber from './isPossible.js'
import parsePhoneNumber from './parsePhoneNumber.js'

function isPossibleNumber(...parameters) {
	let v2
	if (parameters.length < 1) {
		// `input` parameter.
		parameters.push(undefined)
	} else {
		// Convert string `input` to a `PhoneNumber` instance.
		if (typeof parameters[0] === 'string') {
			v2 = true
			parameters[0] = parsePhoneNumber(parameters[0], {
				...parameters[1],
				extract: false
			}, metadata)
		}
	}
	if (parameters.length < 2) {
		// `options` parameter.
		parameters.push(undefined)
	}
	// Set `v2` flag.
	parameters[1] = {
		v2,
		...parameters[1]
	}
	// Add `metadata` parameter.
	parameters.push(metadata)
	// Call the function.
	return _isPossibleNumber.apply(this, parameters)
}

describe('isPossible', () => {
	it('should work', function()
	{
		isPossibleNumber('+79992223344').should.equal(true)

		isPossibleNumber({ phone: '1112223344', country: 'RU' }).should.equal(true)
		isPossibleNumber({ phone: '111222334', country: 'RU' }).should.equal(false)
		isPossibleNumber({ phone: '11122233445', country: 'RU' }).should.equal(false)

		isPossibleNumber({ phone: '1112223344', countryCallingCode: 7 }).should.equal(true)
	})

	it('should work v2', () => {
		isPossibleNumber({ nationalNumber: '111222334', countryCallingCode: 7 }, { v2: true }).should.equal(false)
		isPossibleNumber({ nationalNumber: '1112223344', countryCallingCode: 7 }, { v2: true }).should.equal(true)
		isPossibleNumber({ nationalNumber: '11122233445', countryCallingCode: 7 }, { v2: true }).should.equal(false)
	})

	it('should work in edge cases', () => {
		// Invalid `PhoneNumber` argument.
		expect(() => isPossibleNumber({}, { v2: true })).to.throw('Invalid phone number object passed')

		// Empty input is passed.
		// This is just to support `isValidNumber({})`
		// for cases when `parseNumber()` returns `{}`.
		isPossibleNumber({}).should.equal(false)
		expect(() => isPossibleNumber({ phone: '1112223344' })).to.throw('Invalid phone number object passed')

		// Incorrect country.
		expect(() => isPossibleNumber({ phone: '1112223344', country: 'XX' })).to.throw('Unknown country')
	})
})