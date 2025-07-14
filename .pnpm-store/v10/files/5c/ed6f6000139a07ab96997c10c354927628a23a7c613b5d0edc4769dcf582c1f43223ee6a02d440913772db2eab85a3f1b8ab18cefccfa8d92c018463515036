import searchPhoneNumbersInText from './searchPhoneNumbersInText.js'
import metadata from '../metadata.min.json' assert { type: 'json' }

describe('searchPhoneNumbersInText', () => {
	it('should find phone numbers (with default country)', () => {
		const NUMBERS = ['+78005553535', '+12133734253']
		for (const number of searchPhoneNumbersInText('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', 'US', metadata)) {
			number.number.number.should.equal(NUMBERS[0])
			NUMBERS.shift()
		}
	})

	it('should find phone numbers', () => {
		const NUMBERS = ['+78005553535', '+12133734253']
		for (const number of searchPhoneNumbersInText('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', metadata)) {
			number.number.number.should.equal(NUMBERS[0])
			NUMBERS.shift()
		}
	})

	it('should find phone numbers in text', () => {
		const expectedNumbers = [{
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

		for (const number of searchPhoneNumbersInText('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', 'US', metadata)) {
			const expected = expectedNumbers.shift()
			number.startsAt.should.equal(expected.startsAt)
			number.endsAt.should.equal(expected.endsAt)
			number.number.nationalNumber.should.equal(expected.nationalNumber)
			number.number.country.should.equal(expected.country)
		}

		expectedNumbers.length.should.equal(0)
	})
})