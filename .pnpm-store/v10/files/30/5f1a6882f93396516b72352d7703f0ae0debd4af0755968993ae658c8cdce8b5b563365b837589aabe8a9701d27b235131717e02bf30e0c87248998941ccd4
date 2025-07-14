import { parseRFC3966, formatRFC3966 } from './RFC3966.js'

describe('RFC3966', () => {
	it('should format', () => {
		expect(() => formatRFC3966({ number: '123' })).to.throw('expects "number" to be in E.164 format')
		formatRFC3966({}).should.equal('')
		formatRFC3966({ number: '+78005553535' }).should.equal('tel:+78005553535')
		formatRFC3966({ number: '+78005553535', ext: '123' }).should.equal('tel:+78005553535;ext=123')
	})

	it('should parse', () => {
		parseRFC3966('tel:+78005553535').should.deep.equal({
			number : '+78005553535'
		})

		parseRFC3966('tel:+78005553535;ext=123').should.deep.equal({
			number : '+78005553535',
			ext    : '123'
		})

		// With `phone-context`
		parseRFC3966('tel:8005553535;ext=123;phone-context=+7').should.deep.equal({
			number : '+78005553535',
			ext    : '123'
		})

		// "Domain contexts" are ignored
		parseRFC3966('tel:8005553535;ext=123;phone-context=www.leningrad.spb.ru').should.deep.equal({
			number : '8005553535',
			ext    : '123'
		})

		// Not a viable phone number.
		parseRFC3966('tel:3').should.deep.equal({})
	})
})
