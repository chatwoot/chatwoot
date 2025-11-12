import _isValidPhoneNumber from './isValidPhoneNumber.js'
import metadata from '../metadata.min.json' assert { type: 'json' }

function isValidPhoneNumber(...parameters) {
	parameters.push(metadata)
	return _isValidPhoneNumber.apply(this, parameters)
}

describe('isValidPhoneNumber', () => {
	it('should detect whether a phone number is valid', () => {
		isValidPhoneNumber('8 (800) 555 35 35', 'RU').should.equal(true)
		isValidPhoneNumber('8 (800) 555 35 35 0', 'RU').should.equal(false)
		isValidPhoneNumber('Call: 8 (800) 555 35 35', 'RU').should.equal(false)
		isValidPhoneNumber('8 (800) 555 35 35', { defaultCountry: 'RU' }).should.equal(true)
		isValidPhoneNumber('+7 (800) 555 35 35').should.equal(true)
		isValidPhoneNumber('+7 1 (800) 555 35 35').should.equal(false)
		isValidPhoneNumber(' +7 (800) 555 35 35').should.equal(false)
		isValidPhoneNumber(' ').should.equal(false)
	})
})