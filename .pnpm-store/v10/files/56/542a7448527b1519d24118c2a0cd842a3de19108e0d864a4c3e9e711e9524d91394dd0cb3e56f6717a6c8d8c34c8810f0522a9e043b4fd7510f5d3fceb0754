// The `/custom` export has been long deprecated: use `/core` export instead.

'use strict'

var parsePhoneNumberFromString = require('./build/parsePhoneNumber.js').default

// ES5 `require()` "default" "interoperability" hack.
// https://github.com/babel/babel/issues/2212#issuecomment-131827986
// An alternative approach:
// https://www.npmjs.com/package/babel-plugin-add-module-exports
exports = module.exports = parsePhoneNumberFromString
exports['default'] = parsePhoneNumberFromString

exports.ParseError = require('./build/ParseError.js').default
var parsePhoneNumberWithError = require('./build/parsePhoneNumberWithError.js').default
// `parsePhoneNumber()` named export has been renamed to `parsePhoneNumberWithError()`.
exports.parsePhoneNumber = parsePhoneNumberWithError
exports.parsePhoneNumberWithError = parsePhoneNumberWithError

// `parsePhoneNumberFromString()` named export is now considered legacy:
// it has been promoted to a default export due to being too verbose.
exports.parsePhoneNumberFromString = parsePhoneNumberFromString

// Deprecated: remove `parse()` export in 2.0.0.
// (renamed to `parseNumber()`)
exports.parse              = require('./build/legacy/parse.js').default
exports.parseNumber        = require('./build/legacy/parse.js').default
// Deprecated: remove `format()` export in 2.0.0.
// (renamed to `formatNumber()`)
exports.format             = require('./build/legacy/format.js').default
exports.formatNumber       = require('./build/legacy/format.js').default
exports.getNumberType      = require('./build/legacy/getNumberType.js').default
exports.isValidNumber      = require('./build/legacy/isValidNumber.js').default
exports.isValidNumberForRegion = require('./build/legacy/isValidNumberForRegion.js').default

// Deprecated.
exports.isPossibleNumber   = require('./build/legacy/isPossibleNumber.js').default
exports.findNumbers        = require('./build/legacy/findNumbers.js').default
exports.searchNumbers      = require('./build/legacy/searchNumbers.js').default
exports.findPhoneNumbers   = require('./build/legacy/findPhoneNumbers.js').default
exports.searchPhoneNumbers = require('./build/legacy/findPhoneNumbers.js').searchPhoneNumbers
exports.PhoneNumberSearch  = require('./build/legacy/findPhoneNumbersInitialImplementation.js').PhoneNumberSearch

exports.getExampleNumber   = require('./build/getExampleNumber.js').default

exports.findPhoneNumbersInText = require('./build/findPhoneNumbersInText.js').default
exports.searchPhoneNumbersInText = require('./build/searchPhoneNumbersInText.js').default
exports.PhoneNumberMatcher = require('./build/PhoneNumberMatcher.js').default

exports.AsYouType = require('./build/AsYouType.js').default

exports.formatIncompletePhoneNumber = require('./build/formatIncompletePhoneNumber.js').default
exports.parseIncompletePhoneNumber  = require('./build/parseIncompletePhoneNumber.js').default
exports.parsePhoneNumberCharacter   = require('./build/parseIncompletePhoneNumber.js').parsePhoneNumberCharacter
exports.parseDigits   = require('./build/helpers/parseDigits.js').default

// Deprecated: `DIGITS` were used by `react-phone-number-input`.
// Replaced by `parseDigits()`.
//
// Deprecated: `DIGIT_PLACEHOLDER` was used by `react-phone-number-input`.
// Not used anymore.
//
exports.DIGITS            = require('./build/helpers/parseDigits.js').DIGITS
exports.DIGIT_PLACEHOLDER = require('./build/AsYouTypeFormatter.js').DIGIT_PLACEHOLDER

exports.getCountries = require('./build/getCountries.js').default
exports.getCountryCallingCode = require('./build/getCountryCallingCode.js').default
// `getPhoneCode` name is deprecated, use `getCountryCallingCode` instead.
exports.getPhoneCode = exports.getCountryCallingCode

exports.Metadata = require('./build/metadata.js').default
exports.isSupportedCountry = require('./build/metadata.js').isSupportedCountry
exports.getExtPrefix = require('./build/metadata.js').getExtPrefix

exports.parseRFC3966 = require('./build/helpers/RFC3966.js').parseRFC3966
exports.formatRFC3966 = require('./build/helpers/RFC3966.js').formatRFC3966

// exports['default'] = ...