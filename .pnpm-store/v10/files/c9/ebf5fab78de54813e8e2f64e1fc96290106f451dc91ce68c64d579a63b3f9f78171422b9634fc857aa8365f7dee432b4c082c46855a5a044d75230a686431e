// This "state" object simply holds the state of the "AsYouType" parser:
//
// * `country?: string`
// * `callingCode?: string`
// * `digits: string`
// * `international: boolean`
// * `missingPlus: boolean`
// * `IDDPrefix?: string`
// * `carrierCode?: string`
// * `nationalPrefix?: string`
// * `nationalSignificantNumber?: string`
// * `nationalSignificantNumberMatchesInput: boolean`
// * `complexPrefixBeforeNationalSignificantNumber?: string`
//
// `state.country` and `state.callingCode` aren't required to be in sync.
// For example, `state.country` could be `"AR"` and `state.callingCode` could be `undefined`.
// So `state.country` and `state.callingCode` are totally independent.
//
export default class AsYouTypeState {
	constructor({ onCountryChange, onCallingCodeChange }) {
		this.onCountryChange = onCountryChange
		this.onCallingCodeChange = onCallingCodeChange
	}

	reset({ country, callingCode }) {
		this.international = false
		this.missingPlus = false
		this.IDDPrefix = undefined
		this.callingCode = undefined
		this.digits = ''
		this.resetNationalSignificantNumber()
		this.initCountryAndCallingCode(country, callingCode)
	}

	resetNationalSignificantNumber() {
		this.nationalSignificantNumber = this.getNationalDigits()
		this.nationalSignificantNumberMatchesInput = true
		this.nationalPrefix = undefined
		this.carrierCode = undefined
		this.complexPrefixBeforeNationalSignificantNumber = undefined
	}

	update(properties) {
		for (const key of Object.keys(properties)) {
			this[key] = properties[key]
		}
	}

	initCountryAndCallingCode(country, callingCode) {
		this.setCountry(country)
		this.setCallingCode(callingCode)
	}

	setCountry(country) {
		this.country = country
		this.onCountryChange(country)
	}

	setCallingCode(callingCode) {
		this.callingCode = callingCode
		this.onCallingCodeChange(callingCode, this.country)
	}

	startInternationalNumber(country, callingCode) {
		// Prepend the `+` to parsed input.
		this.international = true
		// If a default country was set then reset it
		// because an explicitly international phone
		// number is being entered.
		this.initCountryAndCallingCode(country, callingCode)
	}

	appendDigits(nextDigits) {
		this.digits += nextDigits
	}

	appendNationalSignificantNumberDigits(nextDigits) {
		this.nationalSignificantNumber += nextDigits
	}

	/**
	 * Returns the part of `this.digits` that corresponds to the national number.
	 * Basically, all digits that have been input by the user, except for the
	 * international prefix and the country calling code part
	 * (if the number is an international one).
	 * @return {string}
	 */
	getNationalDigits() {
		if (this.international) {
			return this.digits.slice(
				(this.IDDPrefix ? this.IDDPrefix.length : 0) +
				(this.callingCode ? this.callingCode.length : 0)
			)
		}
		return this.digits
	}

	getDigitsWithoutInternationalPrefix() {
		if (this.international) {
			if (this.IDDPrefix) {
				return this.digits.slice(this.IDDPrefix.length)
			}
		}
		return this.digits
	}
}