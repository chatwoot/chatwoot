import Metadata from '../metadata.js'
import metadata from '../../metadata.min.json' assert { type: 'json' }
import extractNationalNumberFromPossiblyIncompleteNumber from './extractNationalNumberFromPossiblyIncompleteNumber.js'

describe('extractNationalNumberFromPossiblyIncompleteNumber', () => {
	it('should parse a carrier code when there is no national prefix transform rule', () => {
		const meta = new Metadata(metadata)
		meta.country('AU')
		extractNationalNumberFromPossiblyIncompleteNumber('18311800123', meta).should.deep.equal({
			nationalPrefix: undefined,
			carrierCode: '1831',
			nationalNumber: '1800123'
		})
	})
})