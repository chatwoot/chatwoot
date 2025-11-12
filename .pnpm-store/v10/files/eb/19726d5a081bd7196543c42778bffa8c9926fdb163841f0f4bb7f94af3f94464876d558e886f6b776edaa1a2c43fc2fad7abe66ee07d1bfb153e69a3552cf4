import AsYouType from './AsYouType.js'

/**
 * Formats a (possibly incomplete) phone number.
 * The phone number can be either in E.164 format
 * or in a form of national number digits.
 * @param {string} value - A possibly incomplete phone number. Either in E.164 format or in a form of national number digits.
 * @param {string|object} [optionsOrDefaultCountry] - A two-letter ("ISO 3166-1 alpha-2") country code, or an object of shape `{ defaultCountry?: string, defaultCallingCode?: string }`.
 * @return {string} Formatted (possibly incomplete) phone number.
 */
export default function formatIncompletePhoneNumber(value, optionsOrDefaultCountry, metadata) {
	if (!metadata) {
		metadata = optionsOrDefaultCountry
		optionsOrDefaultCountry = undefined
	}
	return new AsYouType(optionsOrDefaultCountry, metadata).input(value)
}