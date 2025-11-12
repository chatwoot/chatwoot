import metadata from '../metadata.min.json' assert { type: 'json' }
import metadataV1 from '../test/metadata/1.0.0/metadata.min.json' assert { type: 'json' }
import metadataV2 from '../test/metadata/1.1.11/metadata.min.json' assert { type: 'json' }
import metadataV3 from '../test/metadata/1.7.34/metadata.min.json' assert { type: 'json' }
import metadataV4 from '../test/metadata/1.7.37/metadata.min.json' assert { type: 'json' }

import Metadata, { validateMetadata, getExtPrefix, isSupportedCountry } from './metadata.js'

describe('metadata', () => {
	it('should return undefined for non-defined types', () => {
		const FR = new Metadata(metadata).country('FR')
		type(FR.type('FIXED_LINE')).should.equal('undefined')
	})

	it('should validate country', () => {
		const thrower = () => new Metadata(metadata).country('RUS')
		thrower.should.throw('Unknown country')
	})

	it('should tell if a country is supported', () => {
		isSupportedCountry('RU', metadata).should.equal(true)
		isSupportedCountry('XX', metadata).should.equal(false)
	})

	it('should return ext prefix for a country', () => {
		getExtPrefix('US', metadata).should.equal(' ext. ')
		getExtPrefix('CA', metadata).should.equal(' ext. ')
		getExtPrefix('GB', metadata).should.equal(' x')
		// expect(getExtPrefix('XX', metadata)).to.equal(undefined)
		getExtPrefix('XX', metadata).should.equal(' ext. ')
	})

	it('should cover non-occuring edge cases', () => {
		new Metadata(metadata).getNumberingPlanMetadata('999')
	})

	it('should support deprecated methods', () => {
		new Metadata(metadata).country('US').nationalPrefixForParsing().should.equal('1')
		new Metadata(metadata).chooseCountryByCountryCallingCode('1').nationalPrefixForParsing().should.equal('1')
	})

	it('should tell if a national prefix is mandatory when formatting a national number', () => {
		const meta = new Metadata(metadata)
		// No "national_prefix_formatting_rule".
		// "national_prefix_is_optional_when_formatting": true
		meta.country('US')
		meta.numberingPlan.formats()[0].nationalPrefixIsMandatoryWhenFormattingInNationalFormat().should.equal(false)
		// "national_prefix_formatting_rule": "8 ($1)"
		// "national_prefix_is_optional_when_formatting": true
		meta.country('RU')
		meta.numberingPlan.formats()[0].nationalPrefixIsMandatoryWhenFormattingInNationalFormat().should.equal(false)
		// "national_prefix": "0"
		// "national_prefix_formatting_rule": "0 $1"
		meta.country('FR')
		meta.numberingPlan.formats()[0].nationalPrefixIsMandatoryWhenFormattingInNationalFormat().should.equal(true)
	})

	it('should validate metadata', () => {
		let thrower = () => validateMetadata()
		thrower.should.throw('`metadata` argument not passed')

		thrower = () => validateMetadata(123)
		thrower.should.throw('Got a number: 123.')

		thrower = () => validateMetadata('abc')
		thrower.should.throw('Got a string: abc.')

		thrower = () => validateMetadata({ a: true, b: 2 })
		thrower.should.throw('Got an object of shape: { a, b }.')

		thrower = () => validateMetadata({ a: true, countries: 2 })
		thrower.should.throw('Got an object of shape: { a, countries }.')

		thrower = () => validateMetadata({ country_calling_codes: true, countries: 2 })
		thrower.should.throw('Got an object of shape')

		thrower = () => validateMetadata({ country_calling_codes: {}, countries: 2 })
		thrower.should.throw('Got an object of shape')

		validateMetadata({ country_calling_codes: {}, countries: {}, b: 3 })
	})

	it('should work around `nonGeographical` typo in metadata generated from `1.7.35` to `1.7.37`', function() {
		const meta = new Metadata(metadataV4)
		meta.selectNumberingPlan('888')
		type(meta.nonGeographic()).should.equal('object')
	})

	it('should work around `nonGeographic` metadata not existing before `1.7.35`', function() {
		const meta = new Metadata(metadataV3)
		type(meta.getNumberingPlanMetadata('800')).should.equal('object')
		type(meta.getNumberingPlanMetadata('000')).should.equal('undefined')
	})

	it('should work with metadata from version `1.1.11`', function() {
		const meta = new Metadata(metadataV2)

		meta.selectNumberingPlan('US')
		meta.numberingPlan.possibleLengths().should.deep.equal([10])
		meta.numberingPlan.formats().length.should.equal(1)
		meta.numberingPlan.nationalPrefix().should.equal('1')
		meta.numberingPlan.nationalPrefixForParsing().should.equal('1')
		meta.numberingPlan.type('MOBILE').pattern().should.equal('')

		meta.selectNumberingPlan('AG')
		meta.numberingPlan.leadingDigits().should.equal('268')
		// Should've been "268$1" but apparently there was a bug in metadata generator
		// and no national prefix transform rules were written.
		expect(meta.numberingPlan.nationalPrefixTransformRule()).to.be.null

		meta.selectNumberingPlan('AF')
		meta.numberingPlan.formats()[0].nationalPrefixFormattingRule().should.equal('0$1')

		meta.selectNumberingPlan('RU')
		meta.numberingPlan.formats()[0].nationalPrefixIsOptionalWhenFormattingInNationalFormat().should.equal(true)
	})

	it('should work with metadata from version `1.0.0`', function() {
		const meta = new Metadata(metadataV1)

		meta.selectNumberingPlan('US')
		meta.numberingPlan.formats().length.should.equal(1)
		meta.numberingPlan.nationalPrefix().should.equal('1')
		meta.numberingPlan.nationalPrefixForParsing().should.equal('1')
		type(meta.numberingPlan.type('MOBILE')).should.equal('undefined')

		meta.selectNumberingPlan('AG')
		meta.numberingPlan.leadingDigits().should.equal('268')
		// Should've been "268$1" but apparently there was a bug in metadata generator
		// and no national prefix transform rules were written.
		expect(meta.numberingPlan.nationalPrefixTransformRule()).to.be.null

		meta.selectNumberingPlan('AF')
		meta.numberingPlan.formats()[0].nationalPrefixFormattingRule().should.equal('0$1')

		meta.selectNumberingPlan('RU')
		meta.numberingPlan.formats()[0].nationalPrefixIsOptionalWhenFormattingInNationalFormat().should.equal(true)
	})

	it('should work around "ext" data not present in metadata from version `1.0.0`', function() {
		const meta = new Metadata(metadataV1)
		meta.selectNumberingPlan('GB')
		meta.ext().should.equal(' ext. ')

		const metaNew = new Metadata(metadata)
		metaNew.selectNumberingPlan('GB')
		metaNew.ext().should.equal(' x')
	})

	it('should work around "default IDD prefix" data not present in metadata from version `1.0.0`', function() {
		const meta = new Metadata(metadataV1)
		meta.selectNumberingPlan('AU')
		type(meta.defaultIDDPrefix()).should.equal('undefined')

		const metaNew = new Metadata(metadata)
		metaNew.selectNumberingPlan('AU')
		metaNew.defaultIDDPrefix().should.equal('0011')
	})
})

function type(something) {
	return typeof something
}