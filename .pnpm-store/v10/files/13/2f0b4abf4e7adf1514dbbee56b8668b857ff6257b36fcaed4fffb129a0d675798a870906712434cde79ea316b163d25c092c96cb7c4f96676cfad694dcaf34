function _createForOfIteratorHelperLoose(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (it) return (it = it.call(o)).next.bind(it); if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; return function () { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import isValidNumber from '../isValid.js';
import parseDigits from '../helpers/parseDigits.js';
import matchPhoneNumberStringAgainstPhoneNumber from './matchPhoneNumberStringAgainstPhoneNumber.js';
import Metadata from '../metadata.js';
import getCountryByCallingCode from '../helpers/getCountryByCallingCode.js';
import { chooseFormatForNumber } from '../format.js';
import { startsWith, endsWith } from './util.js';
/**
 * Leniency when finding potential phone numbers in text segments
 * The levels here are ordered in increasing strictness.
 */

export default {
  /**
   * Phone numbers accepted are "possible", but not necessarily "valid".
   */
  POSSIBLE: function POSSIBLE(phoneNumber, _ref) {
    var candidate = _ref.candidate,
        metadata = _ref.metadata;
    return true;
  },

  /**
   * Phone numbers accepted are "possible" and "valid".
   * Numbers written in national format must have their national-prefix
   * present if it is usually written for a number of this type.
   */
  VALID: function VALID(phoneNumber, _ref2) {
    var candidate = _ref2.candidate,
        defaultCountry = _ref2.defaultCountry,
        metadata = _ref2.metadata;

    if (!phoneNumber.isValid() || !containsOnlyValidXChars(phoneNumber, candidate, metadata)) {
      return false;
    } // Skipped for simplicity.
    // return isNationalPrefixPresentIfRequired(phoneNumber, { defaultCountry, metadata })


    return true;
  },

  /**
   * Phone numbers accepted are "valid" and
   * are grouped in a possible way for this locale. For example, a US number written as
   * "65 02 53 00 00" and "650253 0000" are not accepted at this leniency level, whereas
   * "650 253 0000", "650 2530000" or "6502530000" are.
   * Numbers with more than one '/' symbol in the national significant number
   * are also dropped at this level.
   *
   * Warning: This level might result in lower coverage especially for regions outside of
   * country code "+1". If you are not sure about which level to use,
   * email the discussion group libphonenumber-discuss@googlegroups.com.
   */
  STRICT_GROUPING: function STRICT_GROUPING(phoneNumber, _ref3) {
    var candidate = _ref3.candidate,
        defaultCountry = _ref3.defaultCountry,
        metadata = _ref3.metadata,
        regExpCache = _ref3.regExpCache;

    if (!phoneNumber.isValid() || !containsOnlyValidXChars(phoneNumber, candidate, metadata) || containsMoreThanOneSlashInNationalNumber(phoneNumber, candidate) || !isNationalPrefixPresentIfRequired(phoneNumber, {
      defaultCountry: defaultCountry,
      metadata: metadata
    })) {
      return false;
    }

    return checkNumberGroupingIsValid(phoneNumber, candidate, metadata, allNumberGroupsRemainGrouped, regExpCache);
  },

  /**
   * Phone numbers accepted are "valid" and are grouped in the same way
   * that we would have formatted it, or as a single block.
   * For example, a US number written as "650 2530000" is not accepted
   * at this leniency level, whereas "650 253 0000" or "6502530000" are.
   * Numbers with more than one '/' symbol are also dropped at this level.
   *
   * Warning: This level might result in lower coverage especially for regions outside of
   * country code "+1". If you are not sure about which level to use, email the discussion group
   * libphonenumber-discuss@googlegroups.com.
   */
  EXACT_GROUPING: function EXACT_GROUPING(phoneNumber, _ref4) {
    var candidate = _ref4.candidate,
        defaultCountry = _ref4.defaultCountry,
        metadata = _ref4.metadata,
        regExpCache = _ref4.regExpCache;

    if (!phoneNumber.isValid() || !containsOnlyValidXChars(phoneNumber, candidate, metadata) || containsMoreThanOneSlashInNationalNumber(phoneNumber, candidate) || !isNationalPrefixPresentIfRequired(phoneNumber, {
      defaultCountry: defaultCountry,
      metadata: metadata
    })) {
      return false;
    }

    return checkNumberGroupingIsValid(phoneNumber, candidate, metadata, allNumberGroupsAreExactlyPresent, regExpCache);
  }
};

function containsOnlyValidXChars(phoneNumber, candidate, metadata) {
  // The characters 'x' and 'X' can be (1) a carrier code, in which case they always precede the
  // national significant number or (2) an extension sign, in which case they always precede the
  // extension number. We assume a carrier code is more than 1 digit, so the first case has to
  // have more than 1 consecutive 'x' or 'X', whereas the second case can only have exactly 1 'x'
  // or 'X'. We ignore the character if it appears as the last character of the string.
  for (var index = 0; index < candidate.length - 1; index++) {
    var charAtIndex = candidate.charAt(index);

    if (charAtIndex === 'x' || charAtIndex === 'X') {
      var charAtNextIndex = candidate.charAt(index + 1);

      if (charAtNextIndex === 'x' || charAtNextIndex === 'X') {
        // This is the carrier code case, in which the 'X's always precede the national
        // significant number.
        index++;

        if (matchPhoneNumberStringAgainstPhoneNumber(candidate.substring(index), phoneNumber, metadata) !== 'NSN_MATCH') {
          return false;
        } // This is the extension sign case, in which the 'x' or 'X' should always precede the
        // extension number.

      } else {
        var ext = parseDigits(candidate.substring(index));

        if (ext) {
          if (phoneNumber.ext !== ext) {
            return false;
          }
        } else {
          if (phoneNumber.ext) {
            return false;
          }
        }
      }
    }
  }

  return true;
}

function isNationalPrefixPresentIfRequired(phoneNumber, _ref5) {
  var defaultCountry = _ref5.defaultCountry,
      _metadata = _ref5.metadata;

  // First, check how we deduced the country code. If it was written in international format, then
  // the national prefix is not required.
  if (phoneNumber.__countryCallingCodeSource !== 'FROM_DEFAULT_COUNTRY') {
    return true;
  }

  var metadata = new Metadata(_metadata);
  metadata.selectNumberingPlan(phoneNumber.countryCallingCode);
  var phoneNumberRegion = phoneNumber.country || getCountryByCallingCode(phoneNumber.countryCallingCode, {
    nationalNumber: phoneNumber.nationalNumber,
    defaultCountry: defaultCountry,
    metadata: metadata
  }); // Check if a national prefix should be present when formatting this number.

  var nationalNumber = phoneNumber.nationalNumber;
  var format = chooseFormatForNumber(metadata.numberingPlan.formats(), nationalNumber); // To do this, we check that a national prefix formatting rule was present
  // and that it wasn't just the first-group symbol ($1) with punctuation.

  if (format.nationalPrefixFormattingRule()) {
    if (metadata.numberingPlan.nationalPrefixIsOptionalWhenFormattingInNationalFormat()) {
      // The national-prefix is optional in these cases, so we don't need to check if it was present.
      return true;
    }

    if (!format.usesNationalPrefix()) {
      // National Prefix not needed for this number.
      return true;
    }

    return Boolean(phoneNumber.nationalPrefix);
  }

  return true;
}

export function containsMoreThanOneSlashInNationalNumber(phoneNumber, candidate) {
  var firstSlashInBodyIndex = candidate.indexOf('/');

  if (firstSlashInBodyIndex < 0) {
    // No slashes, this is okay.
    return false;
  } // Now look for a second one.


  var secondSlashInBodyIndex = candidate.indexOf('/', firstSlashInBodyIndex + 1);

  if (secondSlashInBodyIndex < 0) {
    // Only one slash, this is okay.
    return false;
  } // If the first slash is after the country calling code, this is permitted.


  var candidateHasCountryCode = phoneNumber.__countryCallingCodeSource === 'FROM_NUMBER_WITH_PLUS_SIGN' || phoneNumber.__countryCallingCodeSource === 'FROM_NUMBER_WITHOUT_PLUS_SIGN';

  if (candidateHasCountryCode && parseDigits(candidate.substring(0, firstSlashInBodyIndex)) === phoneNumber.countryCallingCode) {
    // Any more slashes and this is illegal.
    return candidate.slice(secondSlashInBodyIndex + 1).indexOf('/') >= 0;
  }

  return true;
}

function checkNumberGroupingIsValid(number, candidate, metadata, checkGroups, regExpCache) {
  throw new Error('This part of code hasn\'t been ported');
  var normalizedCandidate = normalizeDigits(candidate, true
  /* keep non-digits */
  );
  var formattedNumberGroups = getNationalNumberGroups(metadata, number, null);

  if (checkGroups(metadata, number, normalizedCandidate, formattedNumberGroups)) {
    return true;
  } // If this didn't pass, see if there are any alternate formats that match, and try them instead.


  var alternateFormats = MetadataManager.getAlternateFormatsForCountry(number.getCountryCode());
  var nationalSignificantNumber = util.getNationalSignificantNumber(number);

  if (alternateFormats) {
    for (var _iterator = _createForOfIteratorHelperLoose(alternateFormats.numberFormats()), _step; !(_step = _iterator()).done;) {
      var alternateFormat = _step.value;

      if (alternateFormat.leadingDigitsPatterns().length > 0) {
        // There is only one leading digits pattern for alternate formats.
        var leadingDigitsRegExp = regExpCache.getPatternForRegExp('^' + alternateFormat.leadingDigitsPatterns()[0]);

        if (!leadingDigitsRegExp.test(nationalSignificantNumber)) {
          // Leading digits don't match; try another one.
          continue;
        }
      }

      formattedNumberGroups = getNationalNumberGroups(metadata, number, alternateFormat);

      if (checkGroups(metadata, number, normalizedCandidate, formattedNumberGroups)) {
        return true;
      }
    }
  }

  return false;
}
/**
 * Helper method to get the national-number part of a number, formatted without any national
 * prefix, and return it as a set of digit blocks that would be formatted together following
 * standard formatting rules.
 */


function getNationalNumberGroups(metadata, number, formattingPattern) {
  throw new Error('This part of code hasn\'t been ported');

  if (formattingPattern) {
    // We format the NSN only, and split that according to the separator.
    var nationalSignificantNumber = util.getNationalSignificantNumber(number);
    return util.formatNsnUsingPattern(nationalSignificantNumber, formattingPattern, 'RFC3966', metadata).split('-');
  } // This will be in the format +CC-DG1-DG2-DGX;ext=EXT where DG1..DGX represents groups of digits.


  var rfc3966Format = formatNumber(number, 'RFC3966', metadata); // We remove the extension part from the formatted string before splitting it into different
  // groups.

  var endIndex = rfc3966Format.indexOf(';');

  if (endIndex < 0) {
    endIndex = rfc3966Format.length;
  } // The country-code will have a '-' following it.


  var startIndex = rfc3966Format.indexOf('-') + 1;
  return rfc3966Format.slice(startIndex, endIndex).split('-');
}

function allNumberGroupsAreExactlyPresent(metadata, number, normalizedCandidate, formattedNumberGroups) {
  throw new Error('This part of code hasn\'t been ported');
  var candidateGroups = normalizedCandidate.split(NON_DIGITS_PATTERN); // Set this to the last group, skipping it if the number has an extension.

  var candidateNumberGroupIndex = number.hasExtension() ? candidateGroups.length - 2 : candidateGroups.length - 1; // First we check if the national significant number is formatted as a block.
  // We use contains and not equals, since the national significant number may be present with
  // a prefix such as a national number prefix, or the country code itself.

  if (candidateGroups.length == 1 || candidateGroups[candidateNumberGroupIndex].contains(util.getNationalSignificantNumber(number))) {
    return true;
  } // Starting from the end, go through in reverse, excluding the first group, and check the
  // candidate and number groups are the same.


  var formattedNumberGroupIndex = formattedNumberGroups.length - 1;

  while (formattedNumberGroupIndex > 0 && candidateNumberGroupIndex >= 0) {
    if (candidateGroups[candidateNumberGroupIndex] !== formattedNumberGroups[formattedNumberGroupIndex]) {
      return false;
    }

    formattedNumberGroupIndex--;
    candidateNumberGroupIndex--;
  } // Now check the first group. There may be a national prefix at the start, so we only check
  // that the candidate group ends with the formatted number group.


  return candidateNumberGroupIndex >= 0 && endsWith(candidateGroups[candidateNumberGroupIndex], formattedNumberGroups[0]);
}

function allNumberGroupsRemainGrouped(metadata, number, normalizedCandidate, formattedNumberGroups) {
  throw new Error('This part of code hasn\'t been ported');
  var fromIndex = 0;

  if (number.getCountryCodeSource() !== CountryCodeSource.FROM_DEFAULT_COUNTRY) {
    // First skip the country code if the normalized candidate contained it.
    var countryCode = String(number.getCountryCode());
    fromIndex = normalizedCandidate.indexOf(countryCode) + countryCode.length();
  } // Check each group of consecutive digits are not broken into separate groupings in the
  // {@code normalizedCandidate} string.


  for (var i = 0; i < formattedNumberGroups.length; i++) {
    // Fails if the substring of {@code normalizedCandidate} starting from {@code fromIndex}
    // doesn't contain the consecutive digits in formattedNumberGroups[i].
    fromIndex = normalizedCandidate.indexOf(formattedNumberGroups[i], fromIndex);

    if (fromIndex < 0) {
      return false;
    } // Moves {@code fromIndex} forward.


    fromIndex += formattedNumberGroups[i].length();

    if (i == 0 && fromIndex < normalizedCandidate.length()) {
      // We are at the position right after the NDC. We get the region used for formatting
      // information based on the country code in the phone number, rather than the number itself,
      // as we do not need to distinguish between different countries with the same country
      // calling code and this is faster.
      var region = util.getRegionCodeForCountryCode(number.getCountryCode());

      if (util.getNddPrefixForRegion(region, true) != null && Character.isDigit(normalizedCandidate.charAt(fromIndex))) {
        // This means there is no formatting symbol after the NDC. In this case, we only
        // accept the number if there is no formatting symbol at all in the number, except
        // for extensions. This is only important for countries with national prefixes.
        var nationalSignificantNumber = util.getNationalSignificantNumber(number);
        return startsWith(normalizedCandidate.slice(fromIndex - formattedNumberGroups[i].length), nationalSignificantNumber);
      }
    }
  } // The check here makes sure that we haven't mistakenly already used the extension to
  // match the last group of the subscriber number. Note the extension cannot have
  // formatting in-between digits.


  return normalizedCandidate.slice(fromIndex).contains(number.getExtension());
}
//# sourceMappingURL=Leniency.js.map