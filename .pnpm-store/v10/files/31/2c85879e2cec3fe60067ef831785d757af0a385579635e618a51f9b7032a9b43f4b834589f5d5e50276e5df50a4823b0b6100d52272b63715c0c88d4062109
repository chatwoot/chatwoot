/**
 * Strips any national prefix (such as 0, 1) present in a
 * (possibly incomplete) number provided.
 * "Carrier codes" are only used  in Colombia and Brazil,
 * and only when dialing within those countries from a mobile phone to a fixed line number.
 * Sometimes it won't actually strip national prefix
 * and will instead prepend some digits to the `number`:
 * for example, when number `2345678` is passed with `VI` country selected,
 * it will return `{ number: "3402345678" }`, because `340` area code is prepended.
 * @param {string} number — National number digits.
 * @param {object} metadata — Metadata with country selected.
 * @return {object} `{ nationalNumber: string, nationalPrefix: string? carrierCode: string? }`. Even if a national prefix was extracted, it's not necessarily present in the returned object, so don't rely on its presence in the returned object in order to find out whether a national prefix has been extracted or not.
 */
export default function extractNationalNumberFromPossiblyIncompleteNumber(number, metadata) {
	if (number && metadata.numberingPlan.nationalPrefixForParsing()) {
		// See METADATA.md for the description of
		// `national_prefix_for_parsing` and `national_prefix_transform_rule`.
		// Attempt to parse the first digits as a national prefix.
		const prefixPattern = new RegExp('^(?:' + metadata.numberingPlan.nationalPrefixForParsing() + ')')
		const prefixMatch = prefixPattern.exec(number)
		if (prefixMatch) {
			let nationalNumber
			let carrierCode
			// https://gitlab.com/catamphetamine/libphonenumber-js/-/blob/master/METADATA.md#national_prefix_for_parsing--national_prefix_transform_rule
			// If a `national_prefix_for_parsing` has any "capturing groups"
			// then it means that the national (significant) number is equal to
			// those "capturing groups" transformed via `national_prefix_transform_rule`,
			// and nothing could be said about the actual national prefix:
			// what is it and was it even there.
			// If a `national_prefix_for_parsing` doesn't have any "capturing groups",
			// then everything it matches is a national prefix.
			// To determine whether `national_prefix_for_parsing` matched any
			// "capturing groups", the value of the result of calling `.exec()`
			// is looked at, and if it has non-undefined values where there're
			// "capturing groups" in the regular expression, then it means
			// that "capturing groups" have been matched.
			// It's not possible to tell whether there'll be any "capturing gropus"
			// before the matching process, because a `national_prefix_for_parsing`
			// could exhibit both behaviors.
			const capturedGroupsCount = prefixMatch.length - 1
			const hasCapturedGroups = capturedGroupsCount > 0 && prefixMatch[capturedGroupsCount]
			if (metadata.nationalPrefixTransformRule() && hasCapturedGroups) {
				nationalNumber = number.replace(
					prefixPattern,
					metadata.nationalPrefixTransformRule()
				)
				// If there's more than one captured group,
				// then carrier code is the second one.
				if (capturedGroupsCount > 1) {
					carrierCode = prefixMatch[1]
				}
			}
			// If there're no "capturing groups",
			// or if there're "capturing groups" but no
			// `national_prefix_transform_rule`,
			// then just strip the national prefix from the number,
			// and possibly a carrier code.
			// Seems like there could be more.
			else {
				// `prefixBeforeNationalNumber` is the whole substring matched by
				// the `national_prefix_for_parsing` regular expression.
				// There seem to be no guarantees that it's just a national prefix.
				// For example, if there's a carrier code, it's gonna be a
				// part of `prefixBeforeNationalNumber` too.
				const prefixBeforeNationalNumber = prefixMatch[0]
				nationalNumber = number.slice(prefixBeforeNationalNumber.length)
				// If there's at least one captured group,
				// then carrier code is the first one.
				if (hasCapturedGroups) {
					carrierCode = prefixMatch[1]
				}
			}
			// Tries to guess whether a national prefix was present in the input.
			// This is not something copy-pasted from Google's library:
			// they don't seem to have an equivalent for that.
			// So this isn't an "officially approved" way of doing something like that.
			// But since there seems no other existing method, this library uses it.
			let nationalPrefix
			if (hasCapturedGroups) {
				const possiblePositionOfTheFirstCapturedGroup = number.indexOf(prefixMatch[1])
				const possibleNationalPrefix = number.slice(0, possiblePositionOfTheFirstCapturedGroup)
				// Example: an Argentinian (AR) phone number `0111523456789`.
				// `prefixMatch[0]` is `01115`, and `$1` is `11`,
				// and the rest of the phone number is `23456789`.
				// The national number is transformed via `9$1` to `91123456789`.
				// National prefix `0` is detected being present at the start.
				// if (possibleNationalPrefix.indexOf(metadata.numberingPlan.nationalPrefix()) === 0) {
				if (possibleNationalPrefix === metadata.numberingPlan.nationalPrefix()) {
					nationalPrefix = metadata.numberingPlan.nationalPrefix()
				}
			} else {
				nationalPrefix = prefixMatch[0]
			}
			return {
				nationalNumber,
				nationalPrefix,
				carrierCode
			}
		}
	}
   return {
   	nationalNumber: number
   }
}