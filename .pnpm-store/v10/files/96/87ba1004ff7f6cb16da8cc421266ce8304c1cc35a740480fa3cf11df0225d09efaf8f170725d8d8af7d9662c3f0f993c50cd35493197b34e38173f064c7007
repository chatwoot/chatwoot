function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

import _extractCountryCallingCode from './helpers/extractCountryCallingCode.js';
import extractCountryCallingCodeFromInternationalNumberWithoutPlusSign from './helpers/extractCountryCallingCodeFromInternationalNumberWithoutPlusSign.js';
import extractNationalNumberFromPossiblyIncompleteNumber from './helpers/extractNationalNumberFromPossiblyIncompleteNumber.js';
import stripIddPrefix from './helpers/stripIddPrefix.js';
import parseDigits from './helpers/parseDigits.js';
import { VALID_DIGITS, VALID_PUNCTUATION, PLUS_CHARS } from './constants.js';
var VALID_FORMATTED_PHONE_NUMBER_DIGITS_PART = '[' + VALID_PUNCTUATION + VALID_DIGITS + ']+';
var VALID_FORMATTED_PHONE_NUMBER_DIGITS_PART_PATTERN = new RegExp('^' + VALID_FORMATTED_PHONE_NUMBER_DIGITS_PART + '$', 'i');
var VALID_FORMATTED_PHONE_NUMBER_PART = '(?:' + '[' + PLUS_CHARS + ']' + '[' + VALID_PUNCTUATION + VALID_DIGITS + ']*' + '|' + '[' + VALID_PUNCTUATION + VALID_DIGITS + ']+' + ')';
var AFTER_PHONE_NUMBER_DIGITS_END_PATTERN = new RegExp('[^' + VALID_PUNCTUATION + VALID_DIGITS + ']+' + '.*' + '$'); // Tests whether `national_prefix_for_parsing` could match
// different national prefixes.
// Matches anything that's not a digit or a square bracket.

var COMPLEX_NATIONAL_PREFIX = /[^\d\[\]]/;

var AsYouTypeParser = /*#__PURE__*/function () {
  function AsYouTypeParser(_ref) {
    var defaultCountry = _ref.defaultCountry,
        defaultCallingCode = _ref.defaultCallingCode,
        metadata = _ref.metadata,
        onNationalSignificantNumberChange = _ref.onNationalSignificantNumberChange;

    _classCallCheck(this, AsYouTypeParser);

    this.defaultCountry = defaultCountry;
    this.defaultCallingCode = defaultCallingCode;
    this.metadata = metadata;
    this.onNationalSignificantNumberChange = onNationalSignificantNumberChange;
  }

  _createClass(AsYouTypeParser, [{
    key: "input",
    value: function input(text, state) {
      var _extractFormattedDigi = extractFormattedDigitsAndPlus(text),
          _extractFormattedDigi2 = _slicedToArray(_extractFormattedDigi, 2),
          formattedDigits = _extractFormattedDigi2[0],
          hasPlus = _extractFormattedDigi2[1];

      var digits = parseDigits(formattedDigits); // Checks for a special case: just a leading `+` has been entered.

      var justLeadingPlus;

      if (hasPlus) {
        if (!state.digits) {
          state.startInternationalNumber();

          if (!digits) {
            justLeadingPlus = true;
          }
        }
      }

      if (digits) {
        this.inputDigits(digits, state);
      }

      return {
        digits: digits,
        justLeadingPlus: justLeadingPlus
      };
    }
    /**
     * Inputs "next" phone number digits.
     * @param  {string} digits
     * @return {string} [formattedNumber] Formatted national phone number (if it can be formatted at this stage). Returning `undefined` means "don't format the national phone number at this stage".
     */

  }, {
    key: "inputDigits",
    value: function inputDigits(nextDigits, state) {
      var digits = state.digits;
      var hasReceivedThreeLeadingDigits = digits.length < 3 && digits.length + nextDigits.length >= 3; // Append phone number digits.

      state.appendDigits(nextDigits); // Attempt to extract IDD prefix:
      // Some users input their phone number in international format,
      // but in an "out-of-country" dialing format instead of using the leading `+`.
      // https://github.com/catamphetamine/libphonenumber-js/issues/185
      // Detect such numbers as soon as there're at least 3 digits.
      // Google's library attempts to extract IDD prefix at 3 digits,
      // so this library just copies that behavior.
      // I guess that's because the most commot IDD prefixes are
      // `00` (Europe) and `011` (US).
      // There exist really long IDD prefixes too:
      // for example, in Australia the default IDD prefix is `0011`,
      // and it could even be as long as `14880011`.
      // An IDD prefix is extracted here, and then every time when
      // there's a new digit and the number couldn't be formatted.

      if (hasReceivedThreeLeadingDigits) {
        this.extractIddPrefix(state);
      }

      if (this.isWaitingForCountryCallingCode(state)) {
        if (!this.extractCountryCallingCode(state)) {
          return;
        }
      } else {
        state.appendNationalSignificantNumberDigits(nextDigits);
      } // If a phone number is being input in international format,
      // then it's not valid for it to have a national prefix.
      // Still, some people incorrectly input such numbers with a national prefix.
      // In such cases, only attempt to strip a national prefix if the number becomes too long.
      // (but that is done later, not here)


      if (!state.international) {
        if (!this.hasExtractedNationalSignificantNumber) {
          this.extractNationalSignificantNumber(state.getNationalDigits(), function (stateUpdate) {
            return state.update(stateUpdate);
          });
        }
      }
    }
  }, {
    key: "isWaitingForCountryCallingCode",
    value: function isWaitingForCountryCallingCode(_ref2) {
      var international = _ref2.international,
          callingCode = _ref2.callingCode;
      return international && !callingCode;
    } // Extracts a country calling code from a number
    // being entered in internatonal format.

  }, {
    key: "extractCountryCallingCode",
    value: function extractCountryCallingCode(state) {
      var _extractCountryCallin = _extractCountryCallingCode('+' + state.getDigitsWithoutInternationalPrefix(), this.defaultCountry, this.defaultCallingCode, this.metadata.metadata),
          countryCallingCode = _extractCountryCallin.countryCallingCode,
          number = _extractCountryCallin.number;

      if (countryCallingCode) {
        state.setCallingCode(countryCallingCode);
        state.update({
          nationalSignificantNumber: number
        });
        return true;
      }
    }
  }, {
    key: "reset",
    value: function reset(numberingPlan) {
      if (numberingPlan) {
        this.hasSelectedNumberingPlan = true;

        var nationalPrefixForParsing = numberingPlan._nationalPrefixForParsing();

        this.couldPossiblyExtractAnotherNationalSignificantNumber = nationalPrefixForParsing && COMPLEX_NATIONAL_PREFIX.test(nationalPrefixForParsing);
      } else {
        this.hasSelectedNumberingPlan = undefined;
        this.couldPossiblyExtractAnotherNationalSignificantNumber = undefined;
      }
    }
    /**
     * Extracts a national (significant) number from user input.
     * Google's library is different in that it only applies `national_prefix_for_parsing`
     * and doesn't apply `national_prefix_transform_rule` after that.
     * https://github.com/google/libphonenumber/blob/a3d70b0487875475e6ad659af404943211d26456/java/libphonenumber/src/com/google/i18n/phonenumbers/AsYouTypeFormatter.java#L539
     * @return {boolean} [extracted]
     */

  }, {
    key: "extractNationalSignificantNumber",
    value: function extractNationalSignificantNumber(nationalDigits, setState) {
      if (!this.hasSelectedNumberingPlan) {
        return;
      }

      var _extractNationalNumbe = extractNationalNumberFromPossiblyIncompleteNumber(nationalDigits, this.metadata),
          nationalPrefix = _extractNationalNumbe.nationalPrefix,
          nationalNumber = _extractNationalNumbe.nationalNumber,
          carrierCode = _extractNationalNumbe.carrierCode;

      if (nationalNumber === nationalDigits) {
        return;
      }

      this.onExtractedNationalNumber(nationalPrefix, carrierCode, nationalNumber, nationalDigits, setState);
      return true;
    }
    /**
     * In Google's code this function is called "attempt to extract longer NDD".
     * "Some national prefixes are a substring of others", they say.
     * @return {boolean} [result] — Returns `true` if extracting a national prefix produced different results from what they were.
     */

  }, {
    key: "extractAnotherNationalSignificantNumber",
    value: function extractAnotherNationalSignificantNumber(nationalDigits, prevNationalSignificantNumber, setState) {
      if (!this.hasExtractedNationalSignificantNumber) {
        return this.extractNationalSignificantNumber(nationalDigits, setState);
      }

      if (!this.couldPossiblyExtractAnotherNationalSignificantNumber) {
        return;
      }

      var _extractNationalNumbe2 = extractNationalNumberFromPossiblyIncompleteNumber(nationalDigits, this.metadata),
          nationalPrefix = _extractNationalNumbe2.nationalPrefix,
          nationalNumber = _extractNationalNumbe2.nationalNumber,
          carrierCode = _extractNationalNumbe2.carrierCode; // If a national prefix has been extracted previously,
      // then it's always extracted as additional digits are added.
      // That's assuming `extractNationalNumberFromPossiblyIncompleteNumber()`
      // doesn't do anything different from what it currently does.
      // So, just in case, here's this check, though it doesn't occur.

      /* istanbul ignore if */


      if (nationalNumber === prevNationalSignificantNumber) {
        return;
      }

      this.onExtractedNationalNumber(nationalPrefix, carrierCode, nationalNumber, nationalDigits, setState);
      return true;
    }
  }, {
    key: "onExtractedNationalNumber",
    value: function onExtractedNationalNumber(nationalPrefix, carrierCode, nationalSignificantNumber, nationalDigits, setState) {
      var complexPrefixBeforeNationalSignificantNumber;
      var nationalSignificantNumberMatchesInput; // This check also works with empty `this.nationalSignificantNumber`.

      var nationalSignificantNumberIndex = nationalDigits.lastIndexOf(nationalSignificantNumber); // If the extracted national (significant) number is the
      // last substring of the `digits`, then it means that it hasn't been altered:
      // no digits have been removed from the national (significant) number
      // while applying `national_prefix_transform_rule`.
      // https://gitlab.com/catamphetamine/libphonenumber-js/-/blob/master/METADATA.md#national_prefix_for_parsing--national_prefix_transform_rule

      if (nationalSignificantNumberIndex >= 0 && nationalSignificantNumberIndex === nationalDigits.length - nationalSignificantNumber.length) {
        nationalSignificantNumberMatchesInput = true; // If a prefix of a national (significant) number is not as simple
        // as just a basic national prefix, then such prefix is stored in
        // `this.complexPrefixBeforeNationalSignificantNumber` property and will be
        // prepended "as is" to the national (significant) number to produce
        // a formatted result.

        var prefixBeforeNationalNumber = nationalDigits.slice(0, nationalSignificantNumberIndex); // `prefixBeforeNationalNumber` is always non-empty,
        // because `onExtractedNationalNumber()` isn't called
        // when a national (significant) number hasn't been actually "extracted":
        // when a national (significant) number is equal to the national part of `digits`,
        // then `onExtractedNationalNumber()` doesn't get called.

        if (prefixBeforeNationalNumber !== nationalPrefix) {
          complexPrefixBeforeNationalSignificantNumber = prefixBeforeNationalNumber;
        }
      }

      setState({
        nationalPrefix: nationalPrefix,
        carrierCode: carrierCode,
        nationalSignificantNumber: nationalSignificantNumber,
        nationalSignificantNumberMatchesInput: nationalSignificantNumberMatchesInput,
        complexPrefixBeforeNationalSignificantNumber: complexPrefixBeforeNationalSignificantNumber
      }); // `onExtractedNationalNumber()` is only called when
      // the national (significant) number actually did change.

      this.hasExtractedNationalSignificantNumber = true;
      this.onNationalSignificantNumberChange();
    }
  }, {
    key: "reExtractNationalSignificantNumber",
    value: function reExtractNationalSignificantNumber(state) {
      // Attempt to extract a national prefix.
      //
      // Some people incorrectly input national prefix
      // in an international phone number.
      // For example, some people write British phone numbers as `+44(0)...`.
      //
      // Also, in some rare cases, it is valid for a national prefix
      // to be a part of an international phone number.
      // For example, mobile phone numbers in Mexico are supposed to be
      // dialled internationally using a `1` national prefix,
      // so the national prefix will be part of an international number.
      //
      // Quote from:
      // https://www.mexperience.com/dialing-cell-phones-in-mexico/
      //
      // "Dialing a Mexican cell phone from abroad
      // When you are calling a cell phone number in Mexico from outside Mexico,
      // it’s necessary to dial an additional “1” after Mexico’s country code
      // (which is “52”) and before the area code.
      // You also ignore the 045, and simply dial the area code and the
      // cell phone’s number.
      //
      // If you don’t add the “1”, you’ll receive a recorded announcement
      // asking you to redial using it.
      //
      // For example, if you are calling from the USA to a cell phone
      // in Mexico City, you would dial +52 – 1 – 55 – 1234 5678.
      // (Note that this is different to calling a land line in Mexico City
      // from abroad, where the number dialed would be +52 – 55 – 1234 5678)".
      //
      // Google's demo output:
      // https://libphonenumber.appspot.com/phonenumberparser?number=%2b5215512345678&country=MX
      //
      if (this.extractAnotherNationalSignificantNumber(state.getNationalDigits(), state.nationalSignificantNumber, function (stateUpdate) {
        return state.update(stateUpdate);
      })) {
        return true;
      } // If no format matches the phone number, then it could be
      // "a really long IDD" (quote from a comment in Google's library).
      // An IDD prefix is first extracted when the user has entered at least 3 digits,
      // and then here — every time when there's a new digit and the number
      // couldn't be formatted.
      // For example, in Australia the default IDD prefix is `0011`,
      // and it could even be as long as `14880011`.
      //
      // Could also check `!hasReceivedThreeLeadingDigits` here
      // to filter out the case when this check duplicates the one
      // already performed when there're 3 leading digits,
      // but it's not a big deal, and in most cases there
      // will be a suitable `format` when there're 3 leading digits.
      //


      if (this.extractIddPrefix(state)) {
        this.extractCallingCodeAndNationalSignificantNumber(state);
        return true;
      } // Google's AsYouType formatter supports sort of an "autocorrection" feature
      // when it "autocorrects" numbers that have been input for a country
      // with that country's calling code.
      // Such "autocorrection" feature looks weird, but different people have been requesting it:
      // https://github.com/catamphetamine/libphonenumber-js/issues/376
      // https://github.com/catamphetamine/libphonenumber-js/issues/375
      // https://github.com/catamphetamine/libphonenumber-js/issues/316


      if (this.fixMissingPlus(state)) {
        this.extractCallingCodeAndNationalSignificantNumber(state);
        return true;
      }
    }
  }, {
    key: "extractIddPrefix",
    value: function extractIddPrefix(state) {
      // An IDD prefix can't be present in a number written with a `+`.
      // Also, don't re-extract an IDD prefix if has already been extracted.
      var international = state.international,
          IDDPrefix = state.IDDPrefix,
          digits = state.digits,
          nationalSignificantNumber = state.nationalSignificantNumber;

      if (international || IDDPrefix) {
        return;
      } // Some users input their phone number in "out-of-country"
      // dialing format instead of using the leading `+`.
      // https://github.com/catamphetamine/libphonenumber-js/issues/185
      // Detect such numbers.


      var numberWithoutIDD = stripIddPrefix(digits, this.defaultCountry, this.defaultCallingCode, this.metadata.metadata);

      if (numberWithoutIDD !== undefined && numberWithoutIDD !== digits) {
        // If an IDD prefix was stripped then convert the IDD-prefixed number
        // to international number for subsequent parsing.
        state.update({
          IDDPrefix: digits.slice(0, digits.length - numberWithoutIDD.length)
        });
        this.startInternationalNumber(state, {
          country: undefined,
          callingCode: undefined
        });
        return true;
      }
    }
  }, {
    key: "fixMissingPlus",
    value: function fixMissingPlus(state) {
      if (!state.international) {
        var _extractCountryCallin2 = extractCountryCallingCodeFromInternationalNumberWithoutPlusSign(state.digits, this.defaultCountry, this.defaultCallingCode, this.metadata.metadata),
            newCallingCode = _extractCountryCallin2.countryCallingCode,
            number = _extractCountryCallin2.number;

        if (newCallingCode) {
          state.update({
            missingPlus: true
          });
          this.startInternationalNumber(state, {
            country: state.country,
            callingCode: newCallingCode
          });
          return true;
        }
      }
    }
  }, {
    key: "startInternationalNumber",
    value: function startInternationalNumber(state, _ref3) {
      var country = _ref3.country,
          callingCode = _ref3.callingCode;
      state.startInternationalNumber(country, callingCode); // If a national (significant) number has been extracted before, reset it.

      if (state.nationalSignificantNumber) {
        state.resetNationalSignificantNumber();
        this.onNationalSignificantNumberChange();
        this.hasExtractedNationalSignificantNumber = undefined;
      }
    }
  }, {
    key: "extractCallingCodeAndNationalSignificantNumber",
    value: function extractCallingCodeAndNationalSignificantNumber(state) {
      if (this.extractCountryCallingCode(state)) {
        // `this.extractCallingCode()` is currently called when the number
        // couldn't be formatted during the standard procedure.
        // Normally, the national prefix would be re-extracted
        // for an international number if such number couldn't be formatted,
        // but since it's already not able to be formatted,
        // there won't be yet another retry, so also extract national prefix here.
        this.extractNationalSignificantNumber(state.getNationalDigits(), function (stateUpdate) {
          return state.update(stateUpdate);
        });
      }
    }
  }]);

  return AsYouTypeParser;
}();
/**
 * Extracts formatted phone number from text (if there's any).
 * @param  {string} text
 * @return {string} [formattedPhoneNumber]
 */


export { AsYouTypeParser as default };

function extractFormattedPhoneNumber(text) {
  // Attempt to extract a possible number from the string passed in.
  var startsAt = text.search(VALID_FORMATTED_PHONE_NUMBER_PART);

  if (startsAt < 0) {
    return;
  } // Trim everything to the left of the phone number.


  text = text.slice(startsAt); // Trim the `+`.

  var hasPlus;

  if (text[0] === '+') {
    hasPlus = true;
    text = text.slice('+'.length);
  } // Trim everything to the right of the phone number.


  text = text.replace(AFTER_PHONE_NUMBER_DIGITS_END_PATTERN, ''); // Re-add the previously trimmed `+`.

  if (hasPlus) {
    text = '+' + text;
  }

  return text;
}
/**
 * Extracts formatted phone number digits (and a `+`) from text (if there're any).
 * @param  {string} text
 * @return {any[]}
 */


function _extractFormattedDigitsAndPlus(text) {
  // Extract a formatted phone number part from text.
  var extractedNumber = extractFormattedPhoneNumber(text) || ''; // Trim a `+`.

  if (extractedNumber[0] === '+') {
    return [extractedNumber.slice('+'.length), true];
  }

  return [extractedNumber];
}
/**
 * Extracts formatted phone number digits (and a `+`) from text (if there're any).
 * @param  {string} text
 * @return {any[]}
 */


export function extractFormattedDigitsAndPlus(text) {
  var _extractFormattedDigi3 = _extractFormattedDigitsAndPlus(text),
      _extractFormattedDigi4 = _slicedToArray(_extractFormattedDigi3, 2),
      formattedDigits = _extractFormattedDigi4[0],
      hasPlus = _extractFormattedDigi4[1]; // If the extracted phone number part
  // can possibly be a part of some valid phone number
  // then parse phone number characters from a formatted phone number.


  if (!VALID_FORMATTED_PHONE_NUMBER_DIGITS_PART_PATTERN.test(formattedDigits)) {
    formattedDigits = '';
  }

  return [formattedDigits, hasPlus];
}
//# sourceMappingURL=AsYouTypeParser.js.map