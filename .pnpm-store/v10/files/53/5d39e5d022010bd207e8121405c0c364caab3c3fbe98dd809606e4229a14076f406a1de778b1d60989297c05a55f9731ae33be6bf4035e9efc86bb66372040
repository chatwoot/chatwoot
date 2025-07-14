import extractNationalNumber from './extractNationalNumber.js'

import Metadata from '../metadata.js'
import oldMetadata from '../../test/metadata/1.0.0/metadata.min.json' assert { type: 'json' }

describe('extractNationalNumber', function() {
	it('should extract a national number when using old metadata', function() {
		const _oldMetadata = new Metadata(oldMetadata)
		_oldMetadata.selectNumberingPlan('RU')
		extractNationalNumber('88005553535', _oldMetadata).should.deep.equal({
			nationalNumber: '8005553535',
			carrierCode: undefined
		})
	})
})