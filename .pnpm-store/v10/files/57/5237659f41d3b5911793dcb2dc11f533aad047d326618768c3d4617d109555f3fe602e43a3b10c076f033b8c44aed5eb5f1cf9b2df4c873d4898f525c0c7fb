import compare from './tools/semver-compare.js'
import isObject from './helpers/isObject.js'

// Added "possibleLengths" and renamed
// "country_phone_code_to_countries" to "country_calling_codes".
const V2 = '1.0.18'

// Added "idd_prefix" and "default_idd_prefix".
const V3 = '1.2.0'

// Moved `001` country code to "nonGeographic" section of metadata.
const V4 = '1.7.35'

const DEFAULT_EXT_PREFIX = ' ext. '

const CALLING_CODE_REG_EXP = /^\d+$/

/**
 * See: https://gitlab.com/catamphetamine/libphonenumber-js/blob/master/METADATA.md
 */
export default class Metadata {
	constructor(metadata) {
		validateMetadata(metadata)
		this.metadata = metadata
		setVersion.call(this, metadata)
	}

	getCountries() {
		return Object.keys(this.metadata.countries).filter(_ => _ !== '001')
	}

	getCountryMetadata(countryCode) {
		return this.metadata.countries[countryCode]
	}

	nonGeographic() {
		if (this.v1 || this.v2 || this.v3) return
		// `nonGeographical` was a typo.
		// It's present in metadata generated from `1.7.35` to `1.7.37`.
		// The test case could be found by searching for "nonGeographical".
		return this.metadata.nonGeographic || this.metadata.nonGeographical
	}

	hasCountry(country) {
		return this.getCountryMetadata(country) !== undefined
	}

	hasCallingCode(callingCode) {
		if (this.getCountryCodesForCallingCode(callingCode)) {
			return true
		}
		if (this.nonGeographic()) {
			if (this.nonGeographic()[callingCode]) {
				return true
			}
		} else {
			// A hacky workaround for old custom metadata (generated before V4).
			const countryCodes = this.countryCallingCodes()[callingCode]
			if (countryCodes && countryCodes.length === 1 && countryCodes[0] === '001') {
				return true
			}
		}
	}

	isNonGeographicCallingCode(callingCode) {
		if (this.nonGeographic()) {
			return this.nonGeographic()[callingCode] ? true : false
		} else {
			return this.getCountryCodesForCallingCode(callingCode) ? false : true
		}
	}

	// Deprecated.
	country(countryCode) {
		return this.selectNumberingPlan(countryCode)
	}

	selectNumberingPlan(countryCode, callingCode) {
		// Supports just passing `callingCode` as the first argument.
		if (countryCode && CALLING_CODE_REG_EXP.test(countryCode)) {
			callingCode = countryCode
			countryCode = null
		}
		if (countryCode && countryCode !== '001') {
			if (!this.hasCountry(countryCode)) {
				throw new Error(`Unknown country: ${countryCode}`)
			}
			this.numberingPlan = new NumberingPlan(this.getCountryMetadata(countryCode), this)
		} else if (callingCode) {
			if (!this.hasCallingCode(callingCode)) {
				throw new Error(`Unknown calling code: ${callingCode}`)
			}
			this.numberingPlan = new NumberingPlan(this.getNumberingPlanMetadata(callingCode), this)
		} else {
			this.numberingPlan = undefined
		}
		return this
	}

	getCountryCodesForCallingCode(callingCode) {
		const countryCodes = this.countryCallingCodes()[callingCode]
		if (countryCodes) {
			// Metadata before V4 included "non-geographic entity" calling codes
			// inside `country_calling_codes` (for example, `"881":["001"]`).
			// Now the semantics of `country_calling_codes` has changed:
			// it's specifically for "countries" now.
			// Older versions of custom metadata will simply skip parsing
			// "non-geographic entity" phone numbers with new versions
			// of this library: it's not considered a bug,
			// because such numbers are extremely rare,
			// and developers extremely rarely use custom metadata.
			if (countryCodes.length === 1 && countryCodes[0].length === 3) {
				return
			}
			return countryCodes
		}
	}

	getCountryCodeForCallingCode(callingCode) {
		const countryCodes = this.getCountryCodesForCallingCode(callingCode)
		if (countryCodes) {
			return countryCodes[0]
		}
	}

	getNumberingPlanMetadata(callingCode) {
		const countryCode = this.getCountryCodeForCallingCode(callingCode)
		if (countryCode) {
			return this.getCountryMetadata(countryCode)
		}
		if (this.nonGeographic()) {
			const metadata = this.nonGeographic()[callingCode]
			if (metadata) {
				return metadata
			}
		} else {
			// A hacky workaround for old custom metadata (generated before V4).
			// In that metadata, there was no concept of "non-geographic" metadata
			// so metadata for `001` country code was stored along with other countries.
			// The test case can be found by searching for:
			// "should work around `nonGeographic` metadata not existing".
			const countryCodes = this.countryCallingCodes()[callingCode]
			if (countryCodes && countryCodes.length === 1 && countryCodes[0] === '001') {
				return this.metadata.countries['001']
			}
		}
	}

	// Deprecated.
	countryCallingCode() {
		return this.numberingPlan.callingCode()
	}

	// Deprecated.
	IDDPrefix() {
		return this.numberingPlan.IDDPrefix()
	}

	// Deprecated.
	defaultIDDPrefix() {
		return this.numberingPlan.defaultIDDPrefix()
	}

	// Deprecated.
	nationalNumberPattern() {
		return this.numberingPlan.nationalNumberPattern()
	}

	// Deprecated.
	possibleLengths() {
		return this.numberingPlan.possibleLengths()
	}

	// Deprecated.
	formats() {
		return this.numberingPlan.formats()
	}

	// Deprecated.
	nationalPrefixForParsing() {
		return this.numberingPlan.nationalPrefixForParsing()
	}

	// Deprecated.
	nationalPrefixTransformRule() {
		return this.numberingPlan.nationalPrefixTransformRule()
	}

	// Deprecated.
	leadingDigits() {
		return this.numberingPlan.leadingDigits()
	}

	// Deprecated.
	hasTypes() {
		return this.numberingPlan.hasTypes()
	}

	// Deprecated.
	type(type) {
		return this.numberingPlan.type(type)
	}

	// Deprecated.
	ext() {
		return this.numberingPlan.ext()
	}

	countryCallingCodes() {
		if (this.v1) return this.metadata.country_phone_code_to_countries
		return this.metadata.country_calling_codes
	}

	// Deprecated.
	chooseCountryByCountryCallingCode(callingCode) {
		return this.selectNumberingPlan(callingCode)
	}

	hasSelectedNumberingPlan() {
		return this.numberingPlan !== undefined
	}
}

class NumberingPlan {
	constructor(metadata, globalMetadataObject) {
		this.globalMetadataObject = globalMetadataObject
		this.metadata = metadata
		setVersion.call(this, globalMetadataObject.metadata)
	}

	callingCode() {
		return this.metadata[0]
	}

	// Formatting information for regions which share
	// a country calling code is contained by only one region
	// for performance reasons. For example, for NANPA region
	// ("North American Numbering Plan Administration",
	//  which includes USA, Canada, Cayman Islands, Bahamas, etc)
	// it will be contained in the metadata for `US`.
	getDefaultCountryMetadataForRegion() {
		return this.globalMetadataObject.getNumberingPlanMetadata(this.callingCode())
	}

	// Is always present.
	IDDPrefix() {
		if (this.v1 || this.v2) return
		return this.metadata[1]
	}

	// Is only present when a country supports multiple IDD prefixes.
	defaultIDDPrefix() {
		if (this.v1 || this.v2) return
		return this.metadata[12]
	}

	nationalNumberPattern() {
		if (this.v1 || this.v2) return this.metadata[1]
		return this.metadata[2]
	}

	// "possible length" data is always present in Google's metadata.
	possibleLengths() {
		if (this.v1) return
		return this.metadata[this.v2 ? 2 : 3]
	}

	_getFormats(metadata) {
		return metadata[this.v1 ? 2 : this.v2 ? 3 : 4]
	}

	// For countries of the same region (e.g. NANPA)
	// formats are all stored in the "main" country for that region.
	// E.g. "RU" and "KZ", "US" and "CA".
	formats() {
		const formats = this._getFormats(this.metadata) || this._getFormats(this.getDefaultCountryMetadataForRegion()) || []
		return formats.map(_ => new Format(_, this))
	}

	nationalPrefix() {
		return this.metadata[this.v1 ? 3 : this.v2 ? 4 : 5]
	}

	_getNationalPrefixFormattingRule(metadata) {
		return metadata[this.v1 ? 4 : this.v2 ? 5 : 6]
	}

	// For countries of the same region (e.g. NANPA)
	// national prefix formatting rule is stored in the "main" country for that region.
	// E.g. "RU" and "KZ", "US" and "CA".
	nationalPrefixFormattingRule() {
		return this._getNationalPrefixFormattingRule(this.metadata) || this._getNationalPrefixFormattingRule(this.getDefaultCountryMetadataForRegion())
	}

	_nationalPrefixForParsing() {
		return this.metadata[this.v1 ? 5 : this.v2 ? 6 : 7]
	}

	nationalPrefixForParsing() {
		// If `national_prefix_for_parsing` is not set explicitly,
		// then infer it from `national_prefix` (if any)
		return this._nationalPrefixForParsing() || this.nationalPrefix()
	}

	nationalPrefixTransformRule() {
		return this.metadata[this.v1 ? 6 : this.v2 ? 7 : 8]
	}

	_getNationalPrefixIsOptionalWhenFormatting() {
		return !!this.metadata[this.v1 ? 7 : this.v2 ? 8 : 9]
	}

	// For countries of the same region (e.g. NANPA)
	// "national prefix is optional when formatting" flag is
	// stored in the "main" country for that region.
	// E.g. "RU" and "KZ", "US" and "CA".
	nationalPrefixIsOptionalWhenFormattingInNationalFormat() {
		return this._getNationalPrefixIsOptionalWhenFormatting(this.metadata) ||
			this._getNationalPrefixIsOptionalWhenFormatting(this.getDefaultCountryMetadataForRegion())
	}

	leadingDigits() {
		return this.metadata[this.v1 ? 8 : this.v2 ? 9 : 10]
	}

	types() {
		return this.metadata[this.v1 ? 9 : this.v2 ? 10 : 11]
	}

	hasTypes() {
		// Versions 1.2.0 - 1.2.4: can be `[]`.
		/* istanbul ignore next */
		if (this.types() && this.types().length === 0) {
			return false
		}
		// Versions <= 1.2.4: can be `undefined`.
		// Version >= 1.2.5: can be `0`.
		return !!this.types()
	}

	type(type) {
		if (this.hasTypes() && getType(this.types(), type)) {
			return new Type(getType(this.types(), type), this)
		}
	}

	ext() {
		if (this.v1 || this.v2) return DEFAULT_EXT_PREFIX
		return this.metadata[13] || DEFAULT_EXT_PREFIX
	}
}

class Format {
	constructor(format, metadata) {
		this._format = format
		this.metadata = metadata
	}

	pattern() {
		return this._format[0]
	}

	format() {
		return this._format[1]
	}

	leadingDigitsPatterns() {
		return this._format[2] || []
	}

	nationalPrefixFormattingRule() {
		return this._format[3] || this.metadata.nationalPrefixFormattingRule()
	}

	nationalPrefixIsOptionalWhenFormattingInNationalFormat() {
		return !!this._format[4] || this.metadata.nationalPrefixIsOptionalWhenFormattingInNationalFormat()
	}

	nationalPrefixIsMandatoryWhenFormattingInNationalFormat() {
		// National prefix is omitted if there's no national prefix formatting rule
		// set for this country, or when the national prefix formatting rule
		// contains no national prefix itself, or when this rule is set but
		// national prefix is optional for this phone number format
		// (and it is not enforced explicitly)
		return this.usesNationalPrefix() && !this.nationalPrefixIsOptionalWhenFormattingInNationalFormat()
	}

	// Checks whether national prefix formatting rule contains national prefix.
	usesNationalPrefix() {
		return this.nationalPrefixFormattingRule() &&
			// Check that national prefix formatting rule is not a "dummy" one.
			!FIRST_GROUP_ONLY_PREFIX_PATTERN.test(this.nationalPrefixFormattingRule())
			// In compressed metadata, `this.nationalPrefixFormattingRule()` is `0`
			// when `national_prefix_formatting_rule` is not present.
			// So, `true` or `false` are returned explicitly here, so that
			// `0` number isn't returned.
			? true
			: false
	}

	internationalFormat() {
		return this._format[5] || this.format()
	}
}

/**
 * A pattern that is used to determine if the national prefix formatting rule
 * has the first group only, i.e., does not start with the national prefix.
 * Note that the pattern explicitly allows for unbalanced parentheses.
 */
const FIRST_GROUP_ONLY_PREFIX_PATTERN = /^\(?\$1\)?$/

class Type {
	constructor(type, metadata) {
		this.type = type
		this.metadata = metadata
	}

	pattern() {
		if (this.metadata.v1) return this.type
		return this.type[0]
	}

	possibleLengths() {
		if (this.metadata.v1) return
		return this.type[1] || this.metadata.possibleLengths()
	}
}

function getType(types, type) {
	switch (type) {
		case 'FIXED_LINE':
			return types[0]
		case 'MOBILE':
			return types[1]
		case 'TOLL_FREE':
			return types[2]
		case 'PREMIUM_RATE':
			return types[3]
		case 'PERSONAL_NUMBER':
			return types[4]
		case 'VOICEMAIL':
			return types[5]
		case 'UAN':
			return types[6]
		case 'PAGER':
			return types[7]
		case 'VOIP':
			return types[8]
		case 'SHARED_COST':
			return types[9]
	}
}

export function validateMetadata(metadata) {
	if (!metadata) {
		throw new Error('[libphonenumber-js] `metadata` argument not passed. Check your arguments.')
	}

	// `country_phone_code_to_countries` was renamed to
	// `country_calling_codes` in `1.0.18`.
	if (!isObject(metadata) || !isObject(metadata.countries)) {
		throw new Error(`[libphonenumber-js] \`metadata\` argument was passed but it's not a valid metadata. Must be an object having \`.countries\` child object property. Got ${isObject(metadata) ? 'an object of shape: { ' + Object.keys(metadata).join(', ') + ' }' : 'a ' + typeOf(metadata) + ': ' + metadata}.`)
	}
}

// Babel transforms `typeof` into some "branches"
// so istanbul will show this as "branch not covered".
/* istanbul ignore next */
const typeOf = _ => typeof _

/**
 * Returns extension prefix for a country.
 * @param  {string} country
 * @param  {object} metadata
 * @return {string?}
 * @example
 * // Returns " ext. "
 * getExtPrefix("US")
 */
export function getExtPrefix(country, metadata) {
	metadata = new Metadata(metadata)
	if (metadata.hasCountry(country)) {
		return metadata.country(country).ext()
	}
	return DEFAULT_EXT_PREFIX
}

/**
 * Returns "country calling code" for a country.
 * Throws an error if the country doesn't exist or isn't supported by this library.
 * @param  {string} country
 * @param  {object} metadata
 * @return {string}
 * @example
 * // Returns "44"
 * getCountryCallingCode("GB")
 */
export function getCountryCallingCode(country, metadata) {
	metadata = new Metadata(metadata)
	if (metadata.hasCountry(country)) {
		return metadata.country(country).countryCallingCode()
	}
	throw new Error(`Unknown country: ${country}`)
}

export function isSupportedCountry(country, metadata) {
	// metadata = new Metadata(metadata)
	// return metadata.hasCountry(country)
	return metadata.countries.hasOwnProperty(country)
}

function setVersion(metadata) {
	const { version } = metadata
	if (typeof version === 'number') {
		this.v1 = version === 1
		this.v2 = version === 2
		this.v3 = version === 3
		this.v4 = version === 4
	} else {
		if (!version) {
			this.v1 = true
		} else if (compare(version, V3) === -1) {
			this.v2 = true
		} else if (compare(version, V4) === -1) {
			this.v3 = true
		} else {
			this.v4 = true
		}
	}
}

// const ISO_COUNTRY_CODE = /^[A-Z]{2}$/
// function isCountryCode(countryCode) {
// 	return ISO_COUNTRY_CODE.test(countryCodeOrCountryCallingCode)
// }