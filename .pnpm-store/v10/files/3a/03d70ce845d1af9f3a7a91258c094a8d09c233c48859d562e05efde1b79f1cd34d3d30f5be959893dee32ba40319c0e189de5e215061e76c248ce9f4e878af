import metadata from '../metadata.min.json' assert { type: 'json' }
import PhoneNumber from './PhoneNumber.js'

describe('PhoneNumber', () => {
	it('should validate constructor arguments', () => {
		expect(() => new PhoneNumber()).to.throw('`countryCallingCode` not passed')
		expect(() => new PhoneNumber('7')).to.throw('`nationalNumber` not passed')
		expect(() => new PhoneNumber('7', '8005553535')).to.throw('`metadata` not passed')
	})

	it('should accept country code argument', () => {
		const phoneNumber = new PhoneNumber('RU', '8005553535', metadata)
		phoneNumber.countryCallingCode.should.equal('7')
		phoneNumber.country.should.equal('RU')
		phoneNumber.number.should.equal('+78005553535')
	})

	it('should format number with options', () => {
		const phoneNumber = new PhoneNumber('7', '8005553535', metadata)
		phoneNumber.ext = '123'
		phoneNumber.format('NATIONAL', {
			formatExtension: (number, extension) => `${number} доб. ${extension}`
		})
		.should.equal('8 (800) 555-35-35 доб. 123')
	})

	it('should compare phone numbers', () => {
		new PhoneNumber('RU', '8005553535', metadata).isEqual(new PhoneNumber('RU', '8005553535', metadata)).should.equal(true)
		new PhoneNumber('RU', '8005553535', metadata).isEqual(new PhoneNumber('7', '8005553535', metadata)).should.equal(true)
		new PhoneNumber('RU', '8005553535', metadata).isEqual(new PhoneNumber('RU', '8005553536', metadata)).should.equal(false)
	})

	it('should tell if a number is non-geographic', () => {
		new PhoneNumber('7', '8005553535', metadata).isNonGeographic().should.equal(false)
		new PhoneNumber('870', '773111632', metadata).isNonGeographic().should.equal(true)
	})

	it('should allow setting extension', () => {
		const phoneNumber = new PhoneNumber('1', '2133734253', metadata)
		phoneNumber.setExt('1234')
		phoneNumber.ext.should.equal('1234')
		phoneNumber.formatNational().should.equal('(213) 373-4253 ext. 1234')
	})

	it('should return possible countries', () => {
      // "599": [
      //    "CW", //  "possible_lengths": [7, 8]
      //    "BQ" //  "possible_lengths": [7]
      // ]

		let phoneNumber = new PhoneNumber('599', '123456', metadata)
		expect(phoneNumber.country).to.be.undefined
		phoneNumber.getPossibleCountries().should.deep.equal([])

		phoneNumber = new PhoneNumber('599', '1234567', metadata)
		expect(phoneNumber.country).to.be.undefined
		phoneNumber.getPossibleCountries().should.deep.equal(['CW', 'BQ'])

		phoneNumber = new PhoneNumber('599', '12345678', metadata)
		expect(phoneNumber.country).to.be.undefined
		phoneNumber.getPossibleCountries().should.deep.equal(['CW'])

		phoneNumber = new PhoneNumber('599', '123456789', metadata)
		expect(phoneNumber.country).to.be.undefined
		phoneNumber.getPossibleCountries().should.deep.equal([])
	})

	it('should return possible countries in case of ambiguity', () => {
		const phoneNumber = new PhoneNumber('1', '2223334444', metadata)
		expect(phoneNumber.country).to.be.undefined
		phoneNumber.getPossibleCountries().indexOf('US').should.equal(0)
		phoneNumber.getPossibleCountries().length.should.equal(25)
	})

	// it('should return empty possible countries when no national number has been input', () => {
	// 	const phoneNumber = new PhoneNumber('1', '', metadata)
	// 	expect(phoneNumber.country).to.be.undefined
	// 	phoneNumber.getPossibleCountries().should.deep.equal([])
	// })

	it('should return empty possible countries when not enough national number digits have been input', () => {
		const phoneNumber = new PhoneNumber('1', '222', metadata)
		expect(phoneNumber.country).to.be.undefined
		phoneNumber.getPossibleCountries().should.deep.equal([])
	})

	it('should return possible countries in case of no ambiguity', () => {
		const phoneNumber = new PhoneNumber('US', '2133734253', metadata)
		phoneNumber.country.should.equal('US')
		phoneNumber.getPossibleCountries().should.deep.equal(['US'])
	})

	it('should return empty possible countries in case of an unknown calling code', () => {
		const phoneNumber = new PhoneNumber('777', '123', metadata)
		expect(phoneNumber.country).to.be.undefined
		phoneNumber.getPossibleCountries().should.deep.equal([])
	})

	// it('should validate phone number length', () => {
	// 	const phoneNumber = new PhoneNumber('RU', '800', metadata)
	// 	expect(phoneNumber.validateLength()).to.equal('TOO_SHORT')
	//
	// 	const phoneNumberValid = new PhoneNumber('RU', '8005553535', metadata)
	// 	expect(phoneNumberValid.validateLength()).to.be.undefined
	// })
})