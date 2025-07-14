"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

Object.defineProperty(exports, "__esModule", {
  value: true
});
Object.defineProperty(exports, "DIGIT_PLACEHOLDER", {
  enumerable: true,
  get: function get() {
    return _AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER;
  }
});
exports["default"] = void 0;

var _AsYouTypeFormatterUtil = require("./AsYouTypeFormatter.util.js");

var _AsYouTypeFormatterComplete = _interopRequireWildcard(require("./AsYouTypeFormatter.complete.js"));

var _AsYouTypeFormatterPatternMatcher = _interopRequireDefault(require("./AsYouTypeFormatter.PatternMatcher.js"));

var _parseDigits = _interopRequireDefault(require("./helpers/parseDigits.js"));

var _formatNationalNumberUsingFormat = require("./helpers/formatNationalNumberUsingFormat.js");

var _constants = require("./constants.js");

var _applyInternationalSeparatorStyle = _interopRequireDefault(require("./helpers/applyInternationalSeparatorStyle.js"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _createForOfIteratorHelperLoose(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (it) return (it = it.call(o)).next.bind(it); if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; return function () { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

// Used in phone number format template creation.
// Could be any digit, I guess.
var DUMMY_DIGIT = '9'; // I don't know why is it exactly `15`

var LONGEST_NATIONAL_PHONE_NUMBER_LENGTH = 15; // Create a phone number consisting only of the digit 9 that matches the
// `number_pattern` by applying the pattern to the "longest phone number" string.

var LONGEST_DUMMY_PHONE_NUMBER = (0, _AsYouTypeFormatterUtil.repeat)(DUMMY_DIGIT, LONGEST_NATIONAL_PHONE_NUMBER_LENGTH); // A set of characters that, if found in a national prefix formatting rules, are an indicator to
// us that we should separate the national prefix from the number when formatting.

var NATIONAL_PREFIX_SEPARATORS_PATTERN = /[- ]/; // Deprecated: Google has removed some formatting pattern related code from their repo.
// https://github.com/googlei18n/libphonenumber/commit/a395b4fef3caf57c4bc5f082e1152a4d2bd0ba4c
// "We no longer have numbers in formatting matching patterns, only \d."
// Because this library supports generating custom metadata
// some users may still be using old metadata so the relevant
// code seems to stay until some next major version update.

var SUPPORT_LEGACY_FORMATTING_PATTERNS = true; // A pattern that is used to match character classes in regular expressions.
// An example of a character class is "[1-4]".

var CREATE_CHARACTER_CLASS_PATTERN = SUPPORT_LEGACY_FORMATTING_PATTERNS && function () {
  return /\[([^\[\]])*\]/g;
}; // Any digit in a regular expression that actually denotes a digit. For
// example, in the regular expression "80[0-2]\d{6,10}", the first 2 digits
// (8 and 0) are standalone digits, but the rest are not.
// Two look-aheads are needed because the number following \\d could be a
// two-digit number, since the phone number can be as long as 15 digits.


var CREATE_STANDALONE_DIGIT_PATTERN = SUPPORT_LEGACY_FORMATTING_PATTERNS && function () {
  return /\d(?=[^,}][^,}])/g;
}; // A regular expression that is used to determine if a `format` is
// suitable to be used in the "as you type formatter".
// A `format` is suitable when the resulting formatted number has
// the same digits as the user has entered.
//
// In the simplest case, that would mean that the format
// doesn't add any additional digits when formatting a number.
// Google says that it also shouldn't add "star" (`*`) characters,
// like it does in some Israeli formats.
// Such basic format would only contain "valid punctuation"
// and "captured group" identifiers ($1, $2, etc).
//
// An example of a format that adds additional digits:
//
// Country: `AR` (Argentina).
// Format:
// {
//    "pattern": "(\\d)(\\d{2})(\\d{4})(\\d{4})",
//    "leading_digits_patterns": ["91"],
//    "national_prefix_formatting_rule": "0$1",
//    "format": "$2 15-$3-$4",
//    "international_format": "$1 $2 $3-$4"
// }
//
// In the format above, the `format` adds `15` to the digits when formatting a number.
// A sidenote: this format actually is suitable because `national_prefix_for_parsing`
// has previously removed `15` from a national number, so re-adding `15` in `format`
// doesn't actually result in any extra digits added to user's input.
// But verifying that would be a complex procedure, so the code chooses a simpler path:
// it simply filters out all `format`s that contain anything but "captured group" ids.
//
// This regular expression is called `ELIGIBLE_FORMAT_PATTERN` in Google's
// `libphonenumber` code.
//


var NON_ALTERING_FORMAT_REG_EXP = new RegExp('[' + _constants.VALID_PUNCTUATION + ']*' + // Google developers say:
// "We require that the first matching group is present in the
//  output pattern to ensure no data is lost while formatting."
'\\$1' + '[' + _constants.VALID_PUNCTUATION + ']*' + '(\\$\\d[' + _constants.VALID_PUNCTUATION + ']*)*' + '$'); // This is the minimum length of the leading digits of a phone number
// to guarantee the first "leading digits pattern" for a phone number format
// to be preemptive.

var MIN_LEADING_DIGITS_LENGTH = 3;

var AsYouTypeFormatter = /*#__PURE__*/function () {
  function AsYouTypeFormatter(_ref) {
    var state = _ref.state,
        metadata = _ref.metadata;

    _classCallCheck(this, AsYouTypeFormatter);

    this.metadata = metadata;
    this.resetFormat();
  }

  _createClass(AsYouTypeFormatter, [{
    key: "resetFormat",
    value: function resetFormat() {
      this.chosenFormat = undefined;
      this.template = undefined;
      this.nationalNumberTemplate = undefined;
      this.populatedNationalNumberTemplate = undefined;
      this.populatedNationalNumberTemplatePosition = -1;
    }
  }, {
    key: "reset",
    value: function reset(numberingPlan, state) {
      this.resetFormat();

      if (numberingPlan) {
        this.isNANP = numberingPlan.callingCode() === '1';
        this.matchingFormats = numberingPlan.formats();

        if (state.nationalSignificantNumber) {
          this.narrowDownMatchingFormats(state);
        }
      } else {
        this.isNANP = undefined;
        this.matchingFormats = [];
      }
    }
    /**
     * Formats an updated phone number.
     * @param  {string} nextDigits — Additional phone number digits.
     * @param  {object} state — `AsYouType` state.
     * @return {[string]} Returns undefined if the updated phone number can't be formatted using any of the available formats.
     */

  }, {
    key: "format",
    value: function format(nextDigits, state) {
      var _this = this;

      // See if the phone number digits can be formatted as a complete phone number.
      // If not, use the results from `formatNationalNumberWithNextDigits()`,
      // which formats based on the chosen formatting pattern.
      //
      // Attempting to format complete phone number first is how it's done
      // in Google's `libphonenumber`, so this library just follows it.
      // Google's `libphonenumber` code doesn't explain in detail why does it
      // attempt to format digits as a complete phone number
      // instead of just going with a previoulsy (or newly) chosen `format`:
      //
      // "Checks to see if there is an exact pattern match for these digits.
      //  If so, we should use this instead of any other formatting template
      //  whose leadingDigitsPattern also matches the input."
      //
      if ((0, _AsYouTypeFormatterComplete.canFormatCompleteNumber)(state.nationalSignificantNumber, this.metadata)) {
        for (var _iterator = _createForOfIteratorHelperLoose(this.matchingFormats), _step; !(_step = _iterator()).done;) {
          var format = _step.value;
          var formattedCompleteNumber = (0, _AsYouTypeFormatterComplete["default"])(state, format, {
            metadata: this.metadata,
            shouldTryNationalPrefixFormattingRule: function shouldTryNationalPrefixFormattingRule(format) {
              return _this.shouldTryNationalPrefixFormattingRule(format, {
                international: state.international,
                nationalPrefix: state.nationalPrefix
              });
            },
            getSeparatorAfterNationalPrefix: function getSeparatorAfterNationalPrefix(format) {
              return _this.getSeparatorAfterNationalPrefix(format);
            }
          });

          if (formattedCompleteNumber) {
            this.resetFormat();
            this.chosenFormat = format;
            this.setNationalNumberTemplate(formattedCompleteNumber.replace(/\d/g, _AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER), state);
            this.populatedNationalNumberTemplate = formattedCompleteNumber; // With a new formatting template, the matched position
            // using the old template needs to be reset.

            this.populatedNationalNumberTemplatePosition = this.template.lastIndexOf(_AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER);
            return formattedCompleteNumber;
          }
        }
      } // Format the digits as a partial (incomplete) phone number
      // using the previously chosen formatting pattern (or a newly chosen one).


      return this.formatNationalNumberWithNextDigits(nextDigits, state);
    } // Formats the next phone number digits.

  }, {
    key: "formatNationalNumberWithNextDigits",
    value: function formatNationalNumberWithNextDigits(nextDigits, state) {
      var previouslyChosenFormat = this.chosenFormat; // Choose a format from the list of matching ones.

      var newlyChosenFormat = this.chooseFormat(state);

      if (newlyChosenFormat) {
        if (newlyChosenFormat === previouslyChosenFormat) {
          // If it can format the next (current) digits
          // using the previously chosen phone number format
          // then return the updated formatted number.
          return this.formatNextNationalNumberDigits(nextDigits);
        } else {
          // If a more appropriate phone number format
          // has been chosen for these "leading digits",
          // then re-format the national phone number part
          // using the newly selected format.
          return this.formatNextNationalNumberDigits(state.getNationalDigits());
        }
      }
    }
  }, {
    key: "narrowDownMatchingFormats",
    value: function narrowDownMatchingFormats(_ref2) {
      var _this2 = this;

      var nationalSignificantNumber = _ref2.nationalSignificantNumber,
          nationalPrefix = _ref2.nationalPrefix,
          international = _ref2.international;
      var leadingDigits = nationalSignificantNumber; // "leading digits" pattern list starts with a
      // "leading digits" pattern fitting a maximum of 3 leading digits.
      // So, after a user inputs 3 digits of a national (significant) phone number
      // this national (significant) number can already be formatted.
      // The next "leading digits" pattern is for 4 leading digits max,
      // and the "leading digits" pattern after it is for 5 leading digits max, etc.
      // This implementation is different from Google's
      // in that it searches for a fitting format
      // even if the user has entered less than
      // `MIN_LEADING_DIGITS_LENGTH` digits of a national number.
      // Because some leading digit patterns already match for a single first digit.

      var leadingDigitsPatternIndex = leadingDigits.length - MIN_LEADING_DIGITS_LENGTH;

      if (leadingDigitsPatternIndex < 0) {
        leadingDigitsPatternIndex = 0;
      }

      this.matchingFormats = this.matchingFormats.filter(function (format) {
        return _this2.formatSuits(format, international, nationalPrefix) && _this2.formatMatches(format, leadingDigits, leadingDigitsPatternIndex);
      }); // If there was a phone number format chosen
      // and it no longer holds given the new leading digits then reset it.
      // The test for this `if` condition is marked as:
      // "Reset a chosen format when it no longer holds given the new leading digits".
      // To construct a valid test case for this one can find a country
      // in `PhoneNumberMetadata.xml` yielding one format for 3 `<leadingDigits>`
      // and yielding another format for 4 `<leadingDigits>` (Australia in this case).

      if (this.chosenFormat && this.matchingFormats.indexOf(this.chosenFormat) === -1) {
        this.resetFormat();
      }
    }
  }, {
    key: "formatSuits",
    value: function formatSuits(format, international, nationalPrefix) {
      // When a prefix before a national (significant) number is
      // simply a national prefix, then it's parsed as `this.nationalPrefix`.
      // In more complex cases, a prefix before national (significant) number
      // could include a national prefix as well as some "capturing groups",
      // and in that case there's no info whether a national prefix has been parsed.
      // If national prefix is not used when formatting a phone number
      // using this format, but a national prefix has been entered by the user,
      // and was extracted, then discard such phone number format.
      // In Google's "AsYouType" formatter code, the equivalent would be this part:
      // https://github.com/google/libphonenumber/blob/0a45cfd96e71cad8edb0e162a70fcc8bd9728933/java/libphonenumber/src/com/google/i18n/phonenumbers/AsYouTypeFormatter.java#L175-L184
      if (nationalPrefix && !format.usesNationalPrefix() && // !format.domesticCarrierCodeFormattingRule() &&
      !format.nationalPrefixIsOptionalWhenFormattingInNationalFormat()) {
        return false;
      } // If national prefix is mandatory for this phone number format
      // and there're no guarantees that a national prefix is present in user input
      // then discard this phone number format as not suitable.
      // In Google's "AsYouType" formatter code, the equivalent would be this part:
      // https://github.com/google/libphonenumber/blob/0a45cfd96e71cad8edb0e162a70fcc8bd9728933/java/libphonenumber/src/com/google/i18n/phonenumbers/AsYouTypeFormatter.java#L185-L193


      if (!international && !nationalPrefix && format.nationalPrefixIsMandatoryWhenFormattingInNationalFormat()) {
        return false;
      }

      return true;
    }
  }, {
    key: "formatMatches",
    value: function formatMatches(format, leadingDigits, leadingDigitsPatternIndex) {
      var leadingDigitsPatternsCount = format.leadingDigitsPatterns().length; // If this format is not restricted to a certain
      // leading digits pattern then it fits.
      // The test case could be found by searching for "leadingDigitsPatternsCount === 0".

      if (leadingDigitsPatternsCount === 0) {
        return true;
      } // Start narrowing down the list of possible formats based on the leading digits.
      // (only previously matched formats take part in the narrowing down process)
      // `leading_digits_patterns` start with 3 digits min
      // and then go up from there one digit at a time.


      leadingDigitsPatternIndex = Math.min(leadingDigitsPatternIndex, leadingDigitsPatternsCount - 1);
      var leadingDigitsPattern = format.leadingDigitsPatterns()[leadingDigitsPatternIndex]; // Google imposes a requirement on the leading digits
      // to be minimum 3 digits long in order to be eligible
      // for checking those with a leading digits pattern.
      //
      // Since `leading_digits_patterns` start with 3 digits min,
      // Google's original `libphonenumber` library only starts
      // excluding any non-matching formats only when the
      // national number entered so far is at least 3 digits long,
      // otherwise format matching would give false negatives.
      //
      // For example, when the digits entered so far are `2`
      // and the leading digits pattern is `21` –
      // it's quite obvious in this case that the format could be the one
      // but due to the absence of further digits it would give false negative.
      //
      // Also, `leading_digits_patterns` doesn't always correspond to a single
      // digits count. For example, `60|8` pattern would already match `8`
      // but the `60` part would require having at least two leading digits,
      // so the whole pattern would require inputting two digits first in order to
      // decide on whether it matches the input, even when the input is "80".
      //
      // This library — `libphonenumber-js` — allows filtering by `leading_digits_patterns`
      // even when there's only 1 or 2 digits of the national (significant) number.
      // To do that, it uses a non-strict pattern matcher written specifically for that.
      //

      if (leadingDigits.length < MIN_LEADING_DIGITS_LENGTH) {
        // Before leading digits < 3 matching was implemented:
        // return true
        //
        // After leading digits < 3 matching was implemented:
        try {
          return new _AsYouTypeFormatterPatternMatcher["default"](leadingDigitsPattern).match(leadingDigits, {
            allowOverflow: true
          }) !== undefined;
        } catch (error)
        /* istanbul ignore next */
        {
          // There's a slight possibility that there could be some undiscovered bug
          // in the pattern matcher code. Since the "leading digits < 3 matching"
          // feature is not "essential" for operation, it can fall back to the old way
          // in case of any issues rather than halting the application's execution.
          console.error(error);
          return true;
        }
      } // If at least `MIN_LEADING_DIGITS_LENGTH` digits of a national number are
      // available then use the usual regular expression matching.
      //
      // The whole pattern is wrapped in round brackets (`()`) because
      // the pattern can use "or" operator (`|`) at the top level of the pattern.
      //


      return new RegExp("^(".concat(leadingDigitsPattern, ")")).test(leadingDigits);
    }
  }, {
    key: "getFormatFormat",
    value: function getFormatFormat(format, international) {
      return international ? format.internationalFormat() : format.format();
    }
  }, {
    key: "chooseFormat",
    value: function chooseFormat(state) {
      var _this3 = this;

      var _loop = function _loop() {
        var format = _step2.value;

        // If this format is currently being used
        // and is still suitable, then stick to it.
        if (_this3.chosenFormat === format) {
          return "break";
        } // Sometimes, a formatting rule inserts additional digits in a phone number,
        // and "as you type" formatter can't do that: it should only use the digits
        // that the user has input.
        //
        // For example, in Argentina, there's a format for mobile phone numbers:
        //
        // {
        //    "pattern": "(\\d)(\\d{2})(\\d{4})(\\d{4})",
        //    "leading_digits_patterns": ["91"],
        //    "national_prefix_formatting_rule": "0$1",
        //    "format": "$2 15-$3-$4",
        //    "international_format": "$1 $2 $3-$4"
        // }
        //
        // In that format, `international_format` is used instead of `format`
        // because `format` inserts `15` in the formatted number,
        // and `AsYouType` formatter should only use the digits
        // the user has actually input, without adding any extra digits.
        // In this case, it wouldn't make a difference, because the `15`
        // is first stripped when applying `national_prefix_for_parsing`
        // and then re-added when using `format`, so in reality it doesn't
        // add any new digits to the number, but to detect that, the code
        // would have to be more complex: it would have to try formatting
        // the digits using the format and then see if any digits have
        // actually been added or removed, and then, every time a new digit
        // is input, it should re-check whether the chosen format doesn't
        // alter the digits.
        //
        // Google's code doesn't go that far, and so does this library:
        // it simply requires that a `format` doesn't add any additonal
        // digits to user's input.
        //
        // Also, people in general should move from inputting phone numbers
        // in national format (possibly with national prefixes)
        // and use international phone number format instead:
        // it's a logical thing in the modern age of mobile phones,
        // globalization and the internet.
        //

        /* istanbul ignore if */


        if (!NON_ALTERING_FORMAT_REG_EXP.test(_this3.getFormatFormat(format, state.international))) {
          return "continue";
        }

        if (!_this3.createTemplateForFormat(format, state)) {
          // Remove the format if it can't generate a template.
          _this3.matchingFormats = _this3.matchingFormats.filter(function (_) {
            return _ !== format;
          });
          return "continue";
        }

        _this3.chosenFormat = format;
        return "break";
      };

      // When there are multiple available formats, the formatter uses the first
      // format where a formatting template could be created.
      //
      // For some weird reason, `istanbul` says "else path not taken"
      // for the `for of` line below. Supposedly that means that
      // the loop doesn't ever go over the last element in the list.
      // That's true because there always is `this.chosenFormat`
      // when `this.matchingFormats` is non-empty.
      // And, for some weird reason, it doesn't think that the case
      // with empty `this.matchingFormats` qualifies for a valid "else" path.
      // So simply muting this `istanbul` warning.
      // It doesn't skip the contents of the `for of` loop,
      // it just skips the `for of` line.
      //

      /* istanbul ignore next */
      for (var _iterator2 = _createForOfIteratorHelperLoose(this.matchingFormats.slice()), _step2; !(_step2 = _iterator2()).done;) {
        var _ret = _loop();

        if (_ret === "break") break;
        if (_ret === "continue") continue;
      }

      if (!this.chosenFormat) {
        // No format matches the national (significant) phone number.
        this.resetFormat();
      }

      return this.chosenFormat;
    }
  }, {
    key: "createTemplateForFormat",
    value: function createTemplateForFormat(format, state) {
      // The formatter doesn't format numbers when numberPattern contains '|', e.g.
      // (20|3)\d{4}. In those cases we quickly return.
      // (Though there's no such format in current metadata)

      /* istanbul ignore if */
      if (SUPPORT_LEGACY_FORMATTING_PATTERNS && format.pattern().indexOf('|') >= 0) {
        return;
      } // Get formatting template for this phone number format


      var template = this.getTemplateForFormat(format, state); // If the national number entered is too long
      // for any phone number format, then abort.

      if (template) {
        this.setNationalNumberTemplate(template, state);
        return true;
      }
    }
  }, {
    key: "getSeparatorAfterNationalPrefix",
    value: function getSeparatorAfterNationalPrefix(format) {
      // `US` metadata doesn't have a `national_prefix_formatting_rule`,
      // so the `if` condition below doesn't apply to `US`,
      // but in reality there shoudl be a separator
      // between a national prefix and a national (significant) number.
      // So `US` national prefix separator is a "special" "hardcoded" case.
      if (this.isNANP) {
        return ' ';
      } // If a `format` has a `national_prefix_formatting_rule`
      // and that rule has a separator after a national prefix,
      // then it means that there should be a separator
      // between a national prefix and a national (significant) number.


      if (format && format.nationalPrefixFormattingRule() && NATIONAL_PREFIX_SEPARATORS_PATTERN.test(format.nationalPrefixFormattingRule())) {
        return ' ';
      } // At this point, there seems to be no clear evidence that
      // there should be a separator between a national prefix
      // and a national (significant) number. So don't insert one.


      return '';
    }
  }, {
    key: "getInternationalPrefixBeforeCountryCallingCode",
    value: function getInternationalPrefixBeforeCountryCallingCode(_ref3, options) {
      var IDDPrefix = _ref3.IDDPrefix,
          missingPlus = _ref3.missingPlus;

      if (IDDPrefix) {
        return options && options.spacing === false ? IDDPrefix : IDDPrefix + ' ';
      }

      if (missingPlus) {
        return '';
      }

      return '+';
    }
  }, {
    key: "getTemplate",
    value: function getTemplate(state) {
      if (!this.template) {
        return;
      } // `this.template` holds the template for a "complete" phone number.
      // The currently entered phone number is most likely not "complete",
      // so trim all non-populated digits.


      var index = -1;
      var i = 0;
      var internationalPrefix = state.international ? this.getInternationalPrefixBeforeCountryCallingCode(state, {
        spacing: false
      }) : '';

      while (i < internationalPrefix.length + state.getDigitsWithoutInternationalPrefix().length) {
        index = this.template.indexOf(_AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER, index + 1);
        i++;
      }

      return (0, _AsYouTypeFormatterUtil.cutAndStripNonPairedParens)(this.template, index + 1);
    }
  }, {
    key: "setNationalNumberTemplate",
    value: function setNationalNumberTemplate(template, state) {
      this.nationalNumberTemplate = template;
      this.populatedNationalNumberTemplate = template; // With a new formatting template, the matched position
      // using the old template needs to be reset.

      this.populatedNationalNumberTemplatePosition = -1; // For convenience, the public `.template` property
      // contains the whole international number
      // if the phone number being input is international:
      // 'x' for the '+' sign, 'x'es for the country phone code,
      // a spacebar and then the template for the formatted national number.

      if (state.international) {
        this.template = this.getInternationalPrefixBeforeCountryCallingCode(state).replace(/[\d\+]/g, _AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER) + (0, _AsYouTypeFormatterUtil.repeat)(_AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER, state.callingCode.length) + ' ' + template;
      } else {
        this.template = template;
      }
    }
    /**
     * Generates formatting template for a national phone number,
     * optionally containing a national prefix, for a format.
     * @param  {Format} format
     * @param  {string} nationalPrefix
     * @return {string}
     */

  }, {
    key: "getTemplateForFormat",
    value: function getTemplateForFormat(format, _ref4) {
      var nationalSignificantNumber = _ref4.nationalSignificantNumber,
          international = _ref4.international,
          nationalPrefix = _ref4.nationalPrefix,
          complexPrefixBeforeNationalSignificantNumber = _ref4.complexPrefixBeforeNationalSignificantNumber;
      var pattern = format.pattern();
      /* istanbul ignore else */

      if (SUPPORT_LEGACY_FORMATTING_PATTERNS) {
        pattern = pattern // Replace anything in the form of [..] with \d
        .replace(CREATE_CHARACTER_CLASS_PATTERN(), '\\d') // Replace any standalone digit (not the one in `{}`) with \d
        .replace(CREATE_STANDALONE_DIGIT_PATTERN(), '\\d');
      } // Generate a dummy national number (consisting of `9`s)
      // that fits this format's `pattern`.
      //
      // This match will always succeed,
      // because the "longest dummy phone number"
      // has enough length to accomodate any possible
      // national phone number format pattern.
      //


      var digits = LONGEST_DUMMY_PHONE_NUMBER.match(pattern)[0]; // If the national number entered is too long
      // for any phone number format, then abort.

      if (nationalSignificantNumber.length > digits.length) {
        return;
      } // Get a formatting template which can be used to efficiently format
      // a partial number where digits are added one by one.
      // Below `strictPattern` is used for the
      // regular expression (with `^` and `$`).
      // This wasn't originally in Google's `libphonenumber`
      // and I guess they don't really need it
      // because they're not using "templates" to format phone numbers
      // but I added `strictPattern` after encountering
      // South Korean phone number formatting bug.
      //
      // Non-strict regular expression bug demonstration:
      //
      // this.nationalSignificantNumber : `111111111` (9 digits)
      //
      // pattern : (\d{2})(\d{3,4})(\d{4})
      // format : `$1 $2 $3`
      // digits : `9999999999` (10 digits)
      //
      // '9999999999'.replace(new RegExp(/(\d{2})(\d{3,4})(\d{4})/g), '$1 $2 $3') = "99 9999 9999"
      //
      // template : xx xxxx xxxx
      //
      // But the correct template in this case is `xx xxx xxxx`.
      // The template was generated incorrectly because of the
      // `{3,4}` variability in the `pattern`.
      //
      // The fix is, if `this.nationalSignificantNumber` has already sufficient length
      // to satisfy the `pattern` completely then `this.nationalSignificantNumber`
      // is used instead of `digits`.


      var strictPattern = new RegExp('^' + pattern + '$');
      var nationalNumberDummyDigits = nationalSignificantNumber.replace(/\d/g, DUMMY_DIGIT); // If `this.nationalSignificantNumber` has already sufficient length
      // to satisfy the `pattern` completely then use it
      // instead of `digits`.

      if (strictPattern.test(nationalNumberDummyDigits)) {
        digits = nationalNumberDummyDigits;
      }

      var numberFormat = this.getFormatFormat(format, international);
      var nationalPrefixIncludedInTemplate; // If a user did input a national prefix (and that's guaranteed),
      // and if a `format` does have a national prefix formatting rule,
      // then see if that national prefix formatting rule
      // prepends exactly the same national prefix the user has input.
      // If that's the case, then use the `format` with the national prefix formatting rule.
      // Otherwise, use  the `format` without the national prefix formatting rule,
      // and prepend a national prefix manually to it.

      if (this.shouldTryNationalPrefixFormattingRule(format, {
        international: international,
        nationalPrefix: nationalPrefix
      })) {
        var numberFormatWithNationalPrefix = numberFormat.replace(_formatNationalNumberUsingFormat.FIRST_GROUP_PATTERN, format.nationalPrefixFormattingRule()); // If `national_prefix_formatting_rule` of a `format` simply prepends
        // national prefix at the start of a national (significant) number,
        // then such formatting can be used with `AsYouType` formatter.
        // There seems to be no `else` case: everywhere in metadata,
        // national prefix formatting rule is national prefix + $1,
        // or `($1)`, in which case such format isn't even considered
        // when the user has input a national prefix.

        /* istanbul ignore else */

        if ((0, _parseDigits["default"])(format.nationalPrefixFormattingRule()) === (nationalPrefix || '') + (0, _parseDigits["default"])('$1')) {
          numberFormat = numberFormatWithNationalPrefix;
          nationalPrefixIncludedInTemplate = true; // Replace all digits of the national prefix in the formatting template
          // with `DIGIT_PLACEHOLDER`s.

          if (nationalPrefix) {
            var i = nationalPrefix.length;

            while (i > 0) {
              numberFormat = numberFormat.replace(/\d/, _AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER);
              i--;
            }
          }
        }
      } // Generate formatting template for this phone number format.


      var template = digits // Format the dummy phone number according to the format.
      .replace(new RegExp(pattern), numberFormat) // Replace each dummy digit with a DIGIT_PLACEHOLDER.
      .replace(new RegExp(DUMMY_DIGIT, 'g'), _AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER); // If a prefix of a national (significant) number is not as simple
      // as just a basic national prefix, then just prepend such prefix
      // before the national (significant) number, optionally spacing
      // the two with a whitespace.

      if (!nationalPrefixIncludedInTemplate) {
        if (complexPrefixBeforeNationalSignificantNumber) {
          // Prepend the prefix to the template manually.
          template = (0, _AsYouTypeFormatterUtil.repeat)(_AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER, complexPrefixBeforeNationalSignificantNumber.length) + ' ' + template;
        } else if (nationalPrefix) {
          // Prepend national prefix to the template manually.
          template = (0, _AsYouTypeFormatterUtil.repeat)(_AsYouTypeFormatterUtil.DIGIT_PLACEHOLDER, nationalPrefix.length) + this.getSeparatorAfterNationalPrefix(format) + template;
        }
      }

      if (international) {
        template = (0, _applyInternationalSeparatorStyle["default"])(template);
      }

      return template;
    }
  }, {
    key: "formatNextNationalNumberDigits",
    value: function formatNextNationalNumberDigits(digits) {
      var result = (0, _AsYouTypeFormatterUtil.populateTemplateWithDigits)(this.populatedNationalNumberTemplate, this.populatedNationalNumberTemplatePosition, digits);

      if (!result) {
        // Reset the format.
        this.resetFormat();
        return;
      }

      this.populatedNationalNumberTemplate = result[0];
      this.populatedNationalNumberTemplatePosition = result[1]; // Return the formatted phone number so far.

      return (0, _AsYouTypeFormatterUtil.cutAndStripNonPairedParens)(this.populatedNationalNumberTemplate, this.populatedNationalNumberTemplatePosition + 1); // The old way which was good for `input-format` but is not so good
      // for `react-phone-number-input`'s default input (`InputBasic`).
      // return closeNonPairedParens(this.populatedNationalNumberTemplate, this.populatedNationalNumberTemplatePosition + 1)
      // 	.replace(new RegExp(DIGIT_PLACEHOLDER, 'g'), ' ')
    }
  }, {
    key: "shouldTryNationalPrefixFormattingRule",
    value: function shouldTryNationalPrefixFormattingRule(format, _ref5) {
      var international = _ref5.international,
          nationalPrefix = _ref5.nationalPrefix;

      if (format.nationalPrefixFormattingRule()) {
        // In some countries, `national_prefix_formatting_rule` is `($1)`,
        // so it applies even if the user hasn't input a national prefix.
        // `format.usesNationalPrefix()` detects such cases.
        var usesNationalPrefix = format.usesNationalPrefix();

        if (usesNationalPrefix && nationalPrefix || !usesNationalPrefix && !international) {
          return true;
        }
      }
    }
  }]);

  return AsYouTypeFormatter;
}();

exports["default"] = AsYouTypeFormatter;
//# sourceMappingURL=AsYouTypeFormatter.js.map