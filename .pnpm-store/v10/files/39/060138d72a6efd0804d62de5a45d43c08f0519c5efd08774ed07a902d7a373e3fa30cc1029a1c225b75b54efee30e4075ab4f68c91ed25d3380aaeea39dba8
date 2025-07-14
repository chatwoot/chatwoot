import metadata from '../../metadata.min.json' assert { type: 'json' }
import isValidNumberForRegionCustom from './isValidNumberForRegion.js'
import _isValidNumberForRegion from './isValidNumberForRegion_.js'

function isValidNumberForRegion(...parameters) {
	parameters.push(metadata)
	return isValidNumberForRegionCustom.apply(this, parameters)
}

describe('isValidNumberForRegion', () => {
	it('should detect if is valid number for region', () => {
		isValidNumberForRegion('07624369230', 'GB').should.equal(false)
		isValidNumberForRegion('07624369230', 'IM').should.equal(true)
	})

	it('should validate arguments', () => {
		expect(() => isValidNumberForRegion({ phone: '7624369230', country: 'GB' })).to.throw('number must be a string')
		expect(() => isValidNumberForRegion('7624369230')).to.throw('country must be a string')
	})

	it('should work in edge cases', () => {
		// Not a "viable" phone number.
		isValidNumberForRegion('7', 'GB').should.equal(false)

		// `options` argument `if/else` coverage.
		_isValidNumberForRegion('07624369230', 'GB', {}, metadata).should.equal(false)
	})
})