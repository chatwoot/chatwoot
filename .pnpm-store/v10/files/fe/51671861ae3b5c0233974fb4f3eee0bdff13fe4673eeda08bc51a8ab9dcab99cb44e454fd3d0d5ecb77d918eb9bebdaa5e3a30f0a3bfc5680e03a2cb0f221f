import PhoneNumberMatcher from './PhoneNumberMatcher.js'
import metadata from '../metadata.min.json' assert { type: 'json' }

function test(text, defaultCountry, expectedNumbers) {
	if (typeof expectedNumbers === 'string') {
		expectedNumbers = [{
			nationalNumber: expectedNumbers
		}]
	}
	const matcher = new PhoneNumberMatcher(text, { defaultCountry, v2: true }, metadata)
	while (matcher.hasNext()) {
		const number = matcher.next()
		const phoneNumber = expectedNumbers.shift()
		if (phoneNumber.startsAt !== undefined) {
			number.startsAt.should.equal(phoneNumber.startsAt)
		}
		if (phoneNumber.endsAt !== undefined) {
			number.endsAt.should.equal(phoneNumber.endsAt)
		}
		number.number.country.should.equal(phoneNumber.country || defaultCountry)
		number.number.nationalNumber.should.equal(phoneNumber.nationalNumber)
	}
	expectedNumbers.length.should.equal(0)
}

describe('PhoneNumberMatcher', () => {
	it('should find phone numbers', () => {
		test(
			'The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.',
			'US',
			[{
				country: 'RU',
				nationalNumber: '8005553535',
				startsAt: 14,
				endsAt: 32
			}, {
				country: 'US',
				nationalNumber: '2133734253',
				startsAt: 41,
				endsAt: 55
			}]
		)
	})

	it('should find phone numbers from Mexico', () => {
		// Test parsing fixed-line numbers of Mexico.
		test('+52 (449)978-0001', 'MX', '4499780001')
		test('01 (449)978-0001', 'MX', '4499780001')
		test('(449)978-0001', 'MX', '4499780001')

		// "Dialling tokens 01, 02, 044, 045 and 1 are removed as they are
		//  no longer valid since August 2019."
		// // Test parsing mobile numbers of Mexico.
		// test('+52 1 33 1234-5678', 'MX', '3312345678')
		// test('044 (33) 1234-5678', 'MX', '3312345678')
		// test('045 33 1234-5678', 'MX', '3312345678')
	})

	it('should find phone numbers from Argentina', () => {
		// Test parsing mobile numbers of Argentina.
		test('+54 9 343 555 1212', 'AR', '93435551212')
		test('0343 15-555-1212', 'AR', '93435551212')

		test('+54 9 3715 65 4320', 'AR', '93715654320')
		test('03715 15 65 4320', 'AR', '93715654320')

		// Test parsing fixed-line numbers of Argentina.
		test('+54 11 3797 0000', 'AR', '1137970000')
		test('011 3797 0000', 'AR', '1137970000')

		test('+54 3715 65 4321', 'AR', '3715654321')
		test('03715 65 4321', 'AR', '3715654321')

		test('+54 23 1234 0000', 'AR', '2312340000')
		test('023 1234 0000', 'AR', '2312340000')
	})

	it('should only support the supported leniency values', function() {
		expect(() => new PhoneNumberMatcher('+54 23 1234 0000', { leniency: 'STRICT_GROUPING', v2: true }, metadata)).to.throw('Supported values: "POSSIBLE", "VALID".')
	})
})