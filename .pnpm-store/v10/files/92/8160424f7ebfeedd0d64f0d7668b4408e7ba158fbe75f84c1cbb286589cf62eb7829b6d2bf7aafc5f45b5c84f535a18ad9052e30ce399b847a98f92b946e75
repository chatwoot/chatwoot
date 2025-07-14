import findPhoneNumbersInText from './findPhoneNumbersInText.js'
import metadata from '../metadata.min.json' assert { type: 'json' }
import metadataMax from '../metadata.max.json' assert { type: 'json' }

function findPhoneNumbersInTextWithResults(input, options, metadata) {
	const results = findPhoneNumbersInText(input, options, metadata)
	return results.map((result) => {
		const { startsAt, endsAt, number } = result
		const data = {
			phone: number.nationalNumber,
			startsAt,
			endsAt
		}
		if (number.country) {
			data.country = number.country
		}
		if (number.ext) {
			data.ext = number.ext
		}
		return data
	})
}

describe('findPhoneNumbersInText', () => {
	it('should find phone numbers in text (with default country)', () => {
		findPhoneNumbersInText('+7 (800) 555-35-35', 'US', metadata)[0].number.number.should.equal('+78005553535')
	})

	it('should find phone numbers in text (with default country in options)', () => {
		findPhoneNumbersInText('+7 (800) 555-35-35', { defaultCountry: 'US' }, metadata)[0].number.number.should.equal('+78005553535')
	})

	it('should find phone numbers in text (with default country and options)', () => {
		findPhoneNumbersInText('+7 (800) 555-35-35', 'US', {}, metadata)[0].number.number.should.equal('+78005553535')
	})

	it('should find phone numbers in text (without default country, with options)', () => {
		findPhoneNumbersInText('+7 (800) 555-35-35', undefined, {}, metadata)[0].number.number.should.equal('+78005553535')
	})

	it('should find phone numbers in text (with default country, without options)', () => {
		findPhoneNumbersInText('+7 (800) 555-35-35', 'US', undefined, metadata)[0].number.number.should.equal('+78005553535')
	})

	it('should find phone numbers in text (with empty default country)', () => {
		findPhoneNumbersInText('+7 (800) 555-35-35', undefined, metadata)[0].number.number.should.equal('+78005553535')
	})

	it('should find phone numbers in text', () => {
		const NUMBERS = ['+78005553535', '+12133734253']
		const results = findPhoneNumbersInText('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', metadata)
		let i = 0
		while (i < results.length) {
			results[i].number.number.should.equal(NUMBERS[i])
			i++
		}
	})

	it('should find phone numbers in text (default country calling code)', () => {
		const NUMBERS = ['+870773111632']
		const results = findPhoneNumbersInText('The number is 773 111 632', { defaultCallingCode: '870' }, metadata)
		let i = 0
		while (i < results.length) {
			results[i].number.number.should.equal(NUMBERS[i])
			i++
		}
	})

	it('should find numbers', () => {
		findPhoneNumbersInTextWithResults('2133734253', { defaultCountry: 'US' }, metadata).should.deep.equal([{
			phone    : '2133734253',
			country  : 'US',
			startsAt : 0,
			endsAt   : 10
		}])

		findPhoneNumbersInTextWithResults('(213) 373-4253', { defaultCountry: 'US' }, metadata).should.deep.equal([{
			phone    : '2133734253',
			country  : 'US',
			startsAt : 0,
			endsAt   : 14
		}])

		findPhoneNumbersInTextWithResults('The number is +7 (800) 555-35-35 and not (213) 373-4253 as written in the document.', { defaultCountry: 'US' }, metadata).should.deep.equal([{
			phone    : '8005553535',
			country  : 'RU',
			startsAt : 14,
			endsAt   : 32
		}, {
			phone    : '2133734253',
			country  : 'US',
			startsAt : 41,
			endsAt   : 55
		}])

		// Opening parenthesis issue.
		// https://github.com/catamphetamine/libphonenumber-js/issues/252
		findPhoneNumbersInTextWithResults('The number is +7 (800) 555-35-35 and not (213) 373-4253 (that\'s not even in the same country!) as written in the document.', { defaultCountry: 'US' }, metadata).should.deep.equal([{
			phone    : '8005553535',
			country  : 'RU',
			startsAt : 14,
			endsAt   : 32
		}, {
			phone    : '2133734253',
			country  : 'US',
			startsAt : 41,
			endsAt   : 55
		}])

		// No default country.
		findPhoneNumbersInTextWithResults('The number is +7 (800) 555-35-35 as written in the document.', undefined, metadata).should.deep.equal([{
			phone    : '8005553535',
			country  : 'RU',
			startsAt : 14,
			endsAt   : 32
		}])

		// Passing `options` and default country.
		findPhoneNumbersInTextWithResults('The number is +7 (800) 555-35-35 as written in the document.', { defaultCountry: 'US', leniency: 'VALID' }, metadata).should.deep.equal([{
			phone    : '8005553535',
			country  : 'RU',
			startsAt : 14,
			endsAt   : 32
		}])

		// Passing `options`.
		findPhoneNumbersInTextWithResults('The number is +7 (800) 555-35-35 as written in the document.', { leniency: 'VALID' }, metadata).should.deep.equal([{
			phone    : '8005553535',
			country  : 'RU',
			startsAt : 14,
			endsAt   : 32
		}])

		// Not a phone number and a phone number.
		findPhoneNumbersInTextWithResults('Digits 12 are not a number, but +7 (800) 555-35-35 is.', { leniency: 'VALID' }, metadata).should.deep.equal([{
			phone    : '8005553535',
			country  : 'RU',
			startsAt : 32,
			endsAt   : 50
		}])

		// Phone number extension.
		findPhoneNumbersInTextWithResults('Date 02/17/2018 is not a number, but +7 (800) 555-35-35 ext. 123 is.', { leniency: 'VALID' }, metadata).should.deep.equal([{
			phone    : '8005553535',
			country  : 'RU',
			ext      : '123',
			startsAt : 37,
			endsAt   : 64
		}])
	})

	it('should find numbers (v2)', () => {
		const phoneNumbers = findPhoneNumbersInText('The number is +7 (800) 555-35-35 ext. 1234 and not (213) 373-4253 as written in the document.', { defaultCountry: 'US', v2: true }, metadata)

		phoneNumbers.length.should.equal(2)

		phoneNumbers[0].startsAt.should.equal(14)
		phoneNumbers[0].endsAt.should.equal(42)

		phoneNumbers[0].number.number.should.equal('+78005553535')
		phoneNumbers[0].number.nationalNumber.should.equal('8005553535')
		phoneNumbers[0].number.country.should.equal('RU')
		phoneNumbers[0].number.countryCallingCode.should.equal('7')
		phoneNumbers[0].number.ext.should.equal('1234')

		phoneNumbers[1].startsAt.should.equal(51)
		phoneNumbers[1].endsAt.should.equal(65)

		phoneNumbers[1].number.number.should.equal('+12133734253')
		phoneNumbers[1].number.nationalNumber.should.equal('2133734253')
		phoneNumbers[1].number.country.should.equal('US')
		phoneNumbers[1].number.countryCallingCode.should.equal('1')
	})

	it('shouldn\'t find non-valid numbers', () => {
		// Not a valid phone number for US.
		findPhoneNumbersInTextWithResults('1111111111', { defaultCountry: 'US' }, metadata).should.deep.equal([])
	})

	it('should find non-European digits', () => {
		// E.g. in Iraq they don't write `+442323234` but rather `+٤٤٢٣٢٣٢٣٤`.
		findPhoneNumbersInTextWithResults('العَرَبِيَّة‎ +٤٤٣٣٣٣٣٣٣٣٣٣عَرَبِيّ‎', undefined, metadata).should.deep.equal([{
			country  : 'GB',
			phone    : '3333333333',
			startsAt : 14,
			endsAt   : 27
		}])
	})

	it('should work in edge cases', () => {
		let thrower

		// No input
		findPhoneNumbersInTextWithResults('', undefined, metadata).should.deep.equal([])

		// // No country metadata for this `require` country code
		// thrower = () => findPhoneNumbersInTextWithResults('123', { defaultCountry: 'ZZ' }, metadata)
		// thrower.should.throw('Unknown country')

		// Numerical `value`
		thrower = () => findPhoneNumbersInTextWithResults(2141111111, { defaultCountry: 'US' })
		thrower.should.throw('A text for parsing must be a string.')

		// // No metadata
		// thrower = () => findPhoneNumbersInTextWithResults('')
		// thrower.should.throw('`metadata` argument not passed')

		// No metadata, no default country, no phone numbers.
		findPhoneNumbersInTextWithResults('').should.deep.equal([])
	})

	it('should find international numbers when passed a non-existent default country', () => {
		const numbers = findPhoneNumbersInText('Phone: +7 (800) 555 35 35. National: 8 (800) 555-55-55', { defaultCountry: 'XX', v2: true }, metadata)
		numbers.length.should.equal(1)
		numbers[0].number.nationalNumber.should.equal('8005553535')
	})

	it('shouldn\'t find phone numbers which are not phone numbers', () => {
		// A timestamp.
		findPhoneNumbersInTextWithResults('2012-01-02 08:00', { defaultCountry: 'US' }, metadata).should.deep.equal([])

		// A valid number (not a complete timestamp).
		findPhoneNumbersInTextWithResults('2012-01-02 08', { defaultCountry: 'US' }, metadata).should.deep.equal([{
			country  : 'US',
			phone    : '2012010208',
			startsAt : 0,
			endsAt   : 13
		}])

		// Invalid parens.
		findPhoneNumbersInTextWithResults('213(3734253', { defaultCountry: 'US' }, metadata).should.deep.equal([])

		// Letters after phone number.
		findPhoneNumbersInTextWithResults('2133734253a', { defaultCountry: 'US' }, metadata).should.deep.equal([])

		// Valid phone (same as the one found in the UUID below).
		findPhoneNumbersInTextWithResults('The phone number is 231354125.', { defaultCountry: 'FR' }, metadata).should.deep.equal([{
			country  : 'FR',
			phone    : '231354125',
			startsAt : 20,
			endsAt   : 29
		}])

		// Not a phone number (part of a UUID).
		// Should parse in `{ extended: true }` mode.
		const possibleNumbers = findPhoneNumbersInTextWithResults('The UUID is CA801c26f98cd16e231354125ad046e40b.', { defaultCountry: 'FR', extended: true }, metadata)
		possibleNumbers.length.should.equal(1)
		possibleNumbers[0].country.should.equal('FR')
		possibleNumbers[0].phone.should.equal('231354125')

		// Not a phone number (part of a UUID).
		// Shouldn't parse by default.
		findPhoneNumbersInTextWithResults('The UUID is CA801c26f98cd16e231354125ad046e40b.', { defaultCountry: 'FR' }, metadata).should.deep.equal([])
	})

	// https://gitlab.com/catamphetamine/libphonenumber-js/-/merge_requests/4
	it('should return correct `startsAt` and `endsAt` when matching "inner" candidates in a could-be-a-candidate substring', () => {
		findPhoneNumbersInTextWithResults('39945926 77200596 16533084', { defaultCountry: 'ID' }, metadataMax)
			.should
			.deep
			.equal([{
				country: 'ID',
				phone: '77200596',
				startsAt: 9,
				endsAt: 17
			}])
	})
})