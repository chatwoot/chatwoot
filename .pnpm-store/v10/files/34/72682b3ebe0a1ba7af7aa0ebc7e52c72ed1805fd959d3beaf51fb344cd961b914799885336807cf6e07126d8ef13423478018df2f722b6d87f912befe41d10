import getNumberType from './getNumberType.js'

import oldMetadata from '../../test/metadata/1.0.0/metadata.min.json' assert { type: 'json' }

import Metadata from '../metadata.js'

describe('getNumberType', function() {
	it('should get number type when using old metadata', function() {
		getNumberType(
			{
				nationalNumber: '2133734253',
				country: 'US'
			},
			{ v2: true },
			oldMetadata
		).should.equal('FIXED_LINE_OR_MOBILE')
	})

	it('should return `undefined` when the phone number is a malformed one', function() {
		expect(getNumberType(
			{},
			{ v2: true },
			oldMetadata
		)).to.equal(undefined)
	})
})