import metadata from '../../metadata.min.json' assert { type: 'json' }
import _formatNumber from './format.js'

function formatNumber(...parameters) {
	parameters.push(metadata)
	return _formatNumber.apply(this, parameters)
}

describe('format', () => {
	it('should work with the first argument being a E.164 number', () => {
		formatNumber('+12133734253', 'NATIONAL').should.equal('(213) 373-4253')
		formatNumber('+12133734253', 'INTERNATIONAL').should.equal('+1 213 373 4253')

		// Invalid number.
		formatNumber('+12111111111', 'NATIONAL').should.equal('(211) 111-1111')

		// Formatting invalid E.164 numbers.
		formatNumber('+11111', 'INTERNATIONAL').should.equal('+1 1111')
		formatNumber('+11111', 'NATIONAL').should.equal('1111')
	})

	it('should work with the first object argument expanded', () => {
		formatNumber('2133734253', 'US', 'NATIONAL').should.equal('(213) 373-4253')
		formatNumber('2133734253', 'US', 'INTERNATIONAL').should.equal('+1 213 373 4253')
	})

	it('should support legacy "National" / "International" formats', () => {
		formatNumber('2133734253', 'US', 'National').should.equal('(213) 373-4253')
		formatNumber('2133734253', 'US', 'International').should.equal('+1 213 373 4253')
	})

	it('should format using formats with no leading digits (`format.leadingDigitsPatterns().length === 0`)', () => {
		formatNumber({ phone: '12345678901', countryCallingCode: 888 }, 'INTERNATIONAL').should.equal('+888 123 456 78901')
	})

	it('should sort out the arguments', () => {
		const options = {
			formatExtension: (number, extension) => `${number} доб. ${extension}`
		}

		formatNumber({
			phone   : '8005553535',
			country : 'RU',
			ext     : '123'
		},
		'NATIONAL', options).should.equal('8 (800) 555-35-35 доб. 123')

		// Parse number from string.
		formatNumber('+78005553535', 'NATIONAL', options).should.equal('8 (800) 555-35-35')
		formatNumber('8005553535', 'RU', 'NATIONAL', options).should.equal('8 (800) 555-35-35')
	})

	it('should format with national prefix when specifically instructed', () => {
		// With national prefix.
		formatNumber('88005553535', 'RU', 'NATIONAL').should.equal('8 (800) 555-35-35')
		// Without national prefix via an explicitly set option.
		formatNumber('88005553535', 'RU', 'NATIONAL', { nationalPrefix: false }).should.equal('800 555-35-35')
	})

	it('should format valid phone numbers', () => {
		// Switzerland
		formatNumber({ country: 'CH', phone: '446681800' }, 'INTERNATIONAL').should.equal('+41 44 668 18 00')
		formatNumber({ country: 'CH', phone: '446681800' }, 'E.164').should.equal('+41446681800')
		formatNumber({ country: 'CH', phone: '446681800' }, 'RFC3966').should.equal('tel:+41446681800')
		formatNumber({ country: 'CH', phone: '446681800' }, 'NATIONAL').should.equal('044 668 18 00')

		// France
		formatNumber({ country: 'FR', phone: '169454850' }, 'NATIONAL').should.equal('01 69 45 48 50')

		// Kazakhstan
		formatNumber('+7 702 211 1111', 'NATIONAL').should.deep.equal('8 (702) 211 1111')
	})

	it('should format national numbers with national prefix even if it\'s optional', () => {
		// Russia
		formatNumber({ country: 'RU', phone: '9991234567' }, 'NATIONAL').should.equal('8 (999) 123-45-67')
	})

	it('should work in edge cases', () => {
		let thrower

		// No phone number
		formatNumber('', 'RU', 'INTERNATIONAL').should.equal('')
		formatNumber('', 'RU', 'NATIONAL').should.equal('')

		formatNumber({ country: 'RU', phone: '' }, 'INTERNATIONAL').should.equal('+7')
		formatNumber({ country: 'RU', phone: '' }, 'NATIONAL').should.equal('')

		// No suitable format
		formatNumber('+121337342530', 'US', 'NATIONAL').should.equal('21337342530')
		// No suitable format (leading digits mismatch)
		formatNumber('28199999', 'AD', 'NATIONAL').should.equal('28199999')

		// Numerical `value`
		thrower = () => formatNumber(89150000000, 'RU', 'NATIONAL')
		thrower.should.throw('A phone number must either be a string or an object of shape { phone, [country] }.')

		// No metadata for country
		expect(() => formatNumber('+121337342530', 'USA', 'NATIONAL')).to.throw('Unknown country')
		expect(() => formatNumber('21337342530', 'USA', 'NATIONAL')).to.throw('Unknown country')

		// No format type
		thrower = () => formatNumber('+123')
		thrower.should.throw('`format` argument not passed')

		// Unknown format type
		thrower = () => formatNumber('123', 'US', 'Gay')
		thrower.should.throw('Unknown "format" argument')

		// No metadata
		thrower = () => _formatNumber('123', 'US', 'E.164')
		thrower.should.throw('`metadata`')

		// No formats
		formatNumber('012345', 'AC', 'NATIONAL').should.equal('012345')

		// No `fromCountry` for `IDD` format.
		expect(formatNumber('+78005553535', 'IDD')).to.be.undefined

		// `fromCountry` has no default IDD prefix.
		expect(formatNumber('+78005553535', 'IDD', { fromCountry: 'BO' })).to.be.undefined

		// No such country.
		expect(() => formatNumber({ phone: '123', country: 'USA' }, 'NATIONAL')).to.throw('Unknown country')
	})

	it('should format phone number extensions', () => {
		// National
		formatNumber({
			country: 'US',
			phone: '2133734253',
			ext: '123'
		},
		'NATIONAL').should.equal('(213) 373-4253 ext. 123')

		// International
		formatNumber({
			country : 'US',
			phone   : '2133734253',
			ext     : '123'
		},
		'INTERNATIONAL').should.equal('+1 213 373 4253 ext. 123')

		// International
		formatNumber({
			country : 'US',
			phone   : '2133734253',
			ext     : '123'
		},
		'INTERNATIONAL').should.equal('+1 213 373 4253 ext. 123')

		// E.164
		formatNumber({
			country : 'US',
			phone   : '2133734253',
			ext     : '123'
		},
		'E.164').should.equal('+12133734253')

		// RFC3966
		formatNumber({
			country : 'US',
			phone   : '2133734253',
			ext     : '123'
		},
		'RFC3966').should.equal('tel:+12133734253;ext=123')

		// Custom ext prefix.
		formatNumber({
			country : 'GB',
			phone   : '7912345678',
			ext     : '123'
		},
		'INTERNATIONAL').should.equal('+44 7912 345678 x123')
	})

	it('should work with Argentina numbers', () => {
		// The same mobile number is written differently
		// in different formats in Argentina:
		// `9` gets prepended in international format.
		formatNumber({ country: 'AR', phone: '3435551212' }, 'INTERNATIONAL')
			.should.equal('+54 3435 55 1212')
		formatNumber({ country: 'AR', phone: '3435551212' }, 'NATIONAL')
			.should.equal('03435 55-1212')
	})

	it('should work with Mexico numbers', () => {
		// Fixed line.
		formatNumber({ country: 'MX', phone: '4499780001' }, 'INTERNATIONAL')
			.should.equal('+52 449 978 0001')
		formatNumber({ country: 'MX', phone: '4499780001' }, 'NATIONAL')
			.should.equal('449 978 0001')
			// or '(449)978-0001'.
		// Mobile.
		// `1` is prepended before area code to mobile numbers in international format.
		formatNumber({ country: 'MX', phone: '3312345678' }, 'INTERNATIONAL')
			.should.equal('+52 33 1234 5678')
		formatNumber({ country: 'MX', phone: '3312345678' }, 'NATIONAL')
			.should.equal('33 1234 5678')
			// or '045 33 1234-5678'.
	})

	it('should format possible numbers', () => {
		formatNumber({ countryCallingCode: '7', phone: '1111111111' }, 'E.164')
			.should.equal('+71111111111')

		formatNumber({ countryCallingCode: '7', phone: '1111111111' }, 'NATIONAL')
			.should.equal('1111111111')

		formatNumber({ countryCallingCode: '7', phone: '1111111111' }, 'INTERNATIONAL')
			.should.equal('+7 1111111111')
	})

	it('should format IDD-prefixed number', () => {
		// No `fromCountry`.
		expect(formatNumber('+78005553535', 'IDD')).to.be.undefined

		// No default IDD prefix.
		expect(formatNumber('+78005553535', 'IDD', { fromCountry: 'BO' })).to.be.undefined

		// Same country calling code.
		formatNumber('+12133734253', 'IDD', { fromCountry: 'CA', humanReadable: true }).should.equal('1 (213) 373-4253')
		formatNumber('+78005553535', 'IDD', { fromCountry: 'KZ', humanReadable: true }).should.equal('8 (800) 555-35-35')

		// formatNumber('+78005553535', 'IDD', { fromCountry: 'US' }).should.equal('01178005553535')
		formatNumber('+78005553535', 'IDD', { fromCountry: 'US', humanReadable: true }).should.equal('011 7 800 555 35 35')
	})

	it('should format non-geographic numbering plan phone numbers', () => {
		// https://github.com/catamphetamine/libphonenumber-js/issues/323
		formatNumber('+870773111632', 'INTERNATIONAL').should.equal('+870 773 111 632')
		formatNumber('+870773111632', 'NATIONAL').should.equal('773 111 632')
	})

	it('should use the default IDD prefix when formatting a phone number', () => {
		// Testing preferred international prefixes with ~ are supported.
		// ("~" designates waiting on a line until proceeding with the input).
		formatNumber('+390236618300', 'IDD', { fromCountry: 'BY' }).should.equal('8~10 39 02 3661 8300')
	})
})