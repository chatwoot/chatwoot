import extractPhoneContext, {
	isPhoneContextValid,
	PLUS_SIGN,
	RFC3966_PREFIX_,
	RFC3966_PHONE_CONTEXT_,
	RFC3966_ISDN_SUBADDRESS_
} from './extractPhoneContext.js'

import ParseError from '../ParseError.js'

/**
 * @param  {string} numberToParse
 * @param  {string} nationalNumber
 * @return {}
 */
export default function extractFormattedPhoneNumberFromPossibleRfc3966NumberUri(numberToParse, {
	extractFormattedPhoneNumber
}) {
	const phoneContext = extractPhoneContext(numberToParse)
	if (!isPhoneContextValid(phoneContext)) {
		throw new ParseError('NOT_A_NUMBER')
	}

	let phoneNumberString

	if (phoneContext === null) {
		// Extract a possible number from the string passed in.
		// (this strips leading characters that could not be the start of a phone number)
		phoneNumberString = extractFormattedPhoneNumber(numberToParse) || ''
	} else {
		phoneNumberString = ''

		// If the phone context contains a phone number prefix, we need to capture
		// it, whereas domains will be ignored.
		if (phoneContext.charAt(0) === PLUS_SIGN) {
			phoneNumberString += phoneContext
		}

		// Now append everything between the "tel:" prefix and the phone-context.
		// This should include the national number, an optional extension or
		// isdn-subaddress component. Note we also handle the case when "tel:" is
		// missing, as we have seen in some of the phone number inputs.
		// In that case, we append everything from the beginning.
		const indexOfRfc3966Prefix = numberToParse.indexOf(RFC3966_PREFIX_)
		let indexOfNationalNumber
		// RFC 3966 "tel:" prefix is preset at this stage because
		// `isPhoneContextValid()` requires it to be present.
		/* istanbul ignore else */
		if (indexOfRfc3966Prefix >= 0) {
			indexOfNationalNumber = indexOfRfc3966Prefix + RFC3966_PREFIX_.length
		} else {
			indexOfNationalNumber = 0
		}
		const indexOfPhoneContext = numberToParse.indexOf(RFC3966_PHONE_CONTEXT_)
		phoneNumberString += numberToParse.substring(indexOfNationalNumber, indexOfPhoneContext)
	}

	// Delete the isdn-subaddress and everything after it if it is present.
	// Note extension won't appear at the same time with isdn-subaddress
	// according to paragraph 5.3 of the RFC3966 spec.
	const indexOfIsdn = phoneNumberString.indexOf(RFC3966_ISDN_SUBADDRESS_)
	if (indexOfIsdn > 0) {
		phoneNumberString = phoneNumberString.substring(0, indexOfIsdn)
	}
	// If both phone context and isdn-subaddress are absent but other
	// parameters are present, the parameters are left in nationalNumber.
	// This is because we are concerned about deleting content from a potential
	// number string when there is no strong evidence that the number is
	// actually written in RFC3966.

	if (phoneNumberString !== '') {
		return phoneNumberString
	}
}