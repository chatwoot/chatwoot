import metadata from '../metadata.min.json' assert { type: 'json' }

import getCountries from './getCountries.js'

describe('getCountries', () => {
	it('should get countries list', () => {
		expect(getCountries(metadata).indexOf('RU') > 0).to.be.true;
	})
})