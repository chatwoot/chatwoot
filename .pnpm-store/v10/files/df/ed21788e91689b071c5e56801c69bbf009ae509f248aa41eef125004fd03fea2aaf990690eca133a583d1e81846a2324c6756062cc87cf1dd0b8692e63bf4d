'use strict'

var parsePhoneNumberFromString = require('../build/parsePhoneNumber.js').default

// ES5 `require()` "default" "interoperability" hack.
// https://github.com/babel/babel/issues/2212#issuecomment-131827986
// An alternative approach:
// https://www.npmjs.com/package/babel-plugin-add-module-exports
exports = module.exports = parsePhoneNumberFromString
exports['default'] = parsePhoneNumberFromString

exports.ParseError = require('../build/ParseError.js').default
var parsePhoneNumberWithError = require('../build/parsePhoneNumberWithError.js').default
// `parsePhoneNumber()` named export has been renamed to `parsePhoneNumberWithError()`.
exports.parsePhoneNumberWithError = parsePhoneNumberWithError
exports.parsePhoneNumber = parsePhoneNumberWithError

// `parsePhoneNumberFromString()` named export is now considered legacy:
// it has been promoted to a default export due to being too verbose.
exports.parsePhoneNumberFromString = parsePhoneNumberFromString

exports.isValidPhoneNumber = require('../build/isValidPhoneNumber.js').default
exports.isPossiblePhoneNumber = require('../build/isPossiblePhoneNumber.js').default
exports.validatePhoneNumberLength = require('../build/validatePhoneNumberLength.js').default

exports.findNumbers = require('../build/legacy/findNumbers.js').default
exports.searchNumbers = require('../build/legacy/searchNumbers.js').default

exports.findPhoneNumbersInText = require('../build/findPhoneNumbersInText.js').default
exports.searchPhoneNumbersInText = require('../build/searchPhoneNumbersInText.js').default
exports.PhoneNumberMatcher = require('../build/PhoneNumberMatcher.js').default

exports.AsYouType = require('../build/AsYouType.js').default

exports.Metadata = require('../build/metadata.js').default
exports.isSupportedCountry = require('../build/metadata.js').isSupportedCountry
exports.getCountries = require('../build/getCountries.js').default
exports.getCountryCallingCode = require('../build/metadata.js').getCountryCallingCode
exports.getExtPrefix = require('../build/metadata.js').getExtPrefix

exports.getExampleNumber = require('../build/getExampleNumber.js').default

exports.formatIncompletePhoneNumber = require('../build/formatIncompletePhoneNumber.js').default

exports.parseIncompletePhoneNumber = require('../build/parseIncompletePhoneNumber.js').default
exports.parsePhoneNumberCharacter = require('../build/parseIncompletePhoneNumber.js').parsePhoneNumberCharacter
exports.parseDigits = require('../build/helpers/parseDigits.js').default
exports.DIGIT_PLACEHOLDER = require('../build/AsYouTypeFormatter.js').DIGIT_PLACEHOLDER

exports.parseRFC3966 = require('../build/helpers/RFC3966.js').parseRFC3966
exports.formatRFC3966 = require('../build/helpers/RFC3966.js').formatRFC3966