import _parsePhoneNumber from './parsePhoneNumber.js'
import metadata from '../metadata.min.json' assert { type: 'json' }

function parsePhoneNumber(...parameters) {
	parameters.push(metadata)
	return _parsePhoneNumber.apply(this, parameters)
}

const USE_NON_GEOGRAPHIC_COUNTRY_CODE = false

describe('parsePhoneNumber', () => {
	it('should parse phone numbers from string', () => {
		parsePhoneNumber('Phone: 8 (800) 555 35 35.', 'RU').nationalNumber.should.equal('8005553535')
		expect(parsePhoneNumber('3', 'RU')).to.be.undefined
	})

	it('should work in edge cases', () => {
		expect(parsePhoneNumber('')).to.be.undefined
	})

	it('should parse phone numbers when invalid country code is passed', () => {
		parsePhoneNumber('Phone: +7 (800) 555 35 35.', 'XX').nationalNumber.should.equal('8005553535')
		expect(parsePhoneNumber('Phone: 8 (800) 555-35-35.', 'XX')).to.be.undefined
	})


	it('should parse non-geographic numbering plan phone numbers (extended)', () => {
		const phoneNumber = parsePhoneNumber('+870773111632')
		phoneNumber.number.should.equal('+870773111632')
		if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
			phoneNumber.country.should.equal('001')
		} else {
			expect(phoneNumber.country).to.be.undefined
		}
		phoneNumber.countryCallingCode.should.equal('870')
	})

	it('should parse non-geographic numbering plan phone numbers (default country code) (extended)', () => {
		const phoneNumber = parsePhoneNumber('773111632', { defaultCallingCode: '870' })
		phoneNumber.number.should.equal('+870773111632')
		if (USE_NON_GEOGRAPHIC_COUNTRY_CODE) {
			phoneNumber.country.should.equal('001')
		} else {
			expect(phoneNumber.country).to.be.undefined
		}
		phoneNumber.countryCallingCode.should.equal('870')
	})

	it('should determine the possibility of non-geographic phone numbers', () => {
		const phoneNumber = parsePhoneNumber('+870773111632')
		phoneNumber.isPossible().should.equal(true)
		const phoneNumber2 = parsePhoneNumber('+8707731116321')
		phoneNumber2.isPossible().should.equal(false)
	})

	it('should support `extract: false` flag', () => {
		const testCorrectness = (number, expectedResult) => {
			const result = expect(parsePhoneNumber(number, { extract: false, defaultCountry: 'US' }))
			if (expectedResult) {
				result.to.not.be.undefined
			} else {
				result.to.be.undefined
			}
		}
		testCorrectness('Call: (213) 373-4253', false)
		testCorrectness('(213) 373-4253x', false)
		testCorrectness('(213) 373-4253', true)
		testCorrectness('- (213) 373-4253 -', true)
		testCorrectness('+1 (213) 373-4253', true)
		testCorrectness(' +1 (213) 373-4253', false)
	})

	it('should not prematurely strip a possible national prefix from Chinese numbers', () => {
		// https://gitlab.com/catamphetamine/libphonenumber-js/-/issues/57
		const phoneNumber = parsePhoneNumber('+86123456789')
		phoneNumber.isPossible().should.equal(true)
		phoneNumber.isValid().should.equal(false)
		phoneNumber.nationalNumber.should.equal('123456789')
	})
})
