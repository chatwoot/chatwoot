import checkNumberLength from './helpers/checkNumberLength.js';
import parseDigits from './helpers/parseDigits.js';
import formatNationalNumberUsingFormat from './helpers/formatNationalNumberUsingFormat.js';
export default function formatCompleteNumber(state, format, _ref) {
  var metadata = _ref.metadata,
      shouldTryNationalPrefixFormattingRule = _ref.shouldTryNationalPrefixFormattingRule,
      getSeparatorAfterNationalPrefix = _ref.getSeparatorAfterNationalPrefix;
  var matcher = new RegExp("^(?:".concat(format.pattern(), ")$"));

  if (matcher.test(state.nationalSignificantNumber)) {
    return formatNationalNumberWithAndWithoutNationalPrefixFormattingRule(state, format, {
      metadata: metadata,
      shouldTryNationalPrefixFormattingRule: shouldTryNationalPrefixFormattingRule,
      getSeparatorAfterNationalPrefix: getSeparatorAfterNationalPrefix
    });
  }
}
export function canFormatCompleteNumber(nationalSignificantNumber, metadata) {
  return checkNumberLength(nationalSignificantNumber, metadata) === 'IS_POSSIBLE';
}

function formatNationalNumberWithAndWithoutNationalPrefixFormattingRule(state, format, _ref2) {
  var metadata = _ref2.metadata,
      shouldTryNationalPrefixFormattingRule = _ref2.shouldTryNationalPrefixFormattingRule,
      getSeparatorAfterNationalPrefix = _ref2.getSeparatorAfterNationalPrefix;
  // `format` has already been checked for `nationalPrefix` requirement.
  var nationalSignificantNumber = state.nationalSignificantNumber,
      international = state.international,
      nationalPrefix = state.nationalPrefix,
      carrierCode = state.carrierCode; // Format the number with using `national_prefix_formatting_rule`.
  // If the resulting formatted number is a valid formatted number, then return it.
  //
  // Google's AsYouType formatter is different in a way that it doesn't try
  // to format using the "national prefix formatting rule", and instead it
  // simply prepends a national prefix followed by a " " character.
  // This code does that too, but as a fallback.
  // The reason is that "national prefix formatting rule" may use parentheses,
  // which wouldn't be included has it used the simpler Google's way.
  //

  if (shouldTryNationalPrefixFormattingRule(format)) {
    var formattedNumber = formatNationalNumber(state, format, {
      useNationalPrefixFormattingRule: true,
      getSeparatorAfterNationalPrefix: getSeparatorAfterNationalPrefix,
      metadata: metadata
    });

    if (formattedNumber) {
      return formattedNumber;
    }
  } // Format the number without using `national_prefix_formatting_rule`.


  return formatNationalNumber(state, format, {
    useNationalPrefixFormattingRule: false,
    getSeparatorAfterNationalPrefix: getSeparatorAfterNationalPrefix,
    metadata: metadata
  });
}

function formatNationalNumber(state, format, _ref3) {
  var metadata = _ref3.metadata,
      useNationalPrefixFormattingRule = _ref3.useNationalPrefixFormattingRule,
      getSeparatorAfterNationalPrefix = _ref3.getSeparatorAfterNationalPrefix;
  var formattedNationalNumber = formatNationalNumberUsingFormat(state.nationalSignificantNumber, format, {
    carrierCode: state.carrierCode,
    useInternationalFormat: state.international,
    withNationalPrefix: useNationalPrefixFormattingRule,
    metadata: metadata
  });

  if (!useNationalPrefixFormattingRule) {
    if (state.nationalPrefix) {
      // If a national prefix was extracted, then just prepend it,
      // followed by a " " character.
      formattedNationalNumber = state.nationalPrefix + getSeparatorAfterNationalPrefix(format) + formattedNationalNumber;
    } else if (state.complexPrefixBeforeNationalSignificantNumber) {
      formattedNationalNumber = state.complexPrefixBeforeNationalSignificantNumber + ' ' + formattedNationalNumber;
    }
  }

  if (isValidFormattedNationalNumber(formattedNationalNumber, state)) {
    return formattedNationalNumber;
  }
} // Check that the formatted phone number contains exactly
// the same digits that have been input by the user.
// For example, when "0111523456789" is input for `AR` country,
// the extracted `this.nationalSignificantNumber` is "91123456789",
// which means that the national part of `this.digits` isn't simply equal to
// `this.nationalPrefix` + `this.nationalSignificantNumber`.
//
// Also, a `format` can add extra digits to the `this.nationalSignificantNumber`
// being formatted via `metadata[country].national_prefix_transform_rule`.
// For example, for `VI` country, it prepends `340` to the national number,
// and if this check hasn't been implemented, then there would be a bug
// when `340` "area coude" is "duplicated" during input for `VI` country:
// https://github.com/catamphetamine/libphonenumber-js/issues/318
//
// So, all these "gotchas" are filtered out.
//
// In the original Google's code, the comments say:
// "Check that we didn't remove nor add any extra digits when we matched
// this formatting pattern. This usually happens after we entered the last
// digit during AYTF. Eg: In case of MX, we swallow mobile token (1) when
// formatted but AYTF should retain all the number entered and not change
// in order to match a format (of same leading digits and length) display
// in that way."
// "If it's the same (i.e entered number and format is same), then it's
// safe to return this in formatted number as nothing is lost / added."
// Otherwise, don't use this format.
// https://github.com/google/libphonenumber/commit/3e7c1f04f5e7200f87fb131e6f85c6e99d60f510#diff-9149457fa9f5d608a11bb975c6ef4bc5
// https://github.com/google/libphonenumber/commit/3ac88c7106e7dcb553bcc794b15f19185928a1c6#diff-2dcb77e833422ee304da348b905cde0b
//


function isValidFormattedNationalNumber(formattedNationalNumber, state) {
  return parseDigits(formattedNationalNumber) === state.getNationalDigits();
}
//# sourceMappingURL=AsYouTypeFormatter.complete.js.map