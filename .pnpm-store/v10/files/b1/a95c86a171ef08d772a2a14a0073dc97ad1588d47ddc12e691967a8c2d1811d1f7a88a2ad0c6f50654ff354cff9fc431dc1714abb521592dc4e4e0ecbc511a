"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _PhoneNumber = _interopRequireDefault(require("./PhoneNumber.js"));

var _constants = require("./constants.js");

var _createExtensionPattern = _interopRequireDefault(require("./helpers/extension/createExtensionPattern.js"));

var _RegExpCache = _interopRequireDefault(require("./findNumbers/RegExpCache.js"));

var _util = require("./findNumbers/util.js");

var _utf = require("./findNumbers/utf-8.js");

var _Leniency = _interopRequireDefault(require("./findNumbers/Leniency.js"));

var _parsePreCandidate = _interopRequireDefault(require("./findNumbers/parsePreCandidate.js"));

var _isValidPreCandidate = _interopRequireDefault(require("./findNumbers/isValidPreCandidate.js"));

var _isValidCandidate = _interopRequireWildcard(require("./findNumbers/isValidCandidate.js"));

var _metadata = require("./metadata.js");

var _parsePhoneNumber = _interopRequireDefault(require("./parsePhoneNumber.js"));

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { "default": obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj["default"] = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _createForOfIteratorHelperLoose(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (it) return (it = it.call(o)).next.bind(it); if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; return function () { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

var USE_NON_GEOGRAPHIC_COUNTRY_CODE = false;
var EXTN_PATTERNS_FOR_MATCHING = (0, _createExtensionPattern["default"])('matching');
/**
 * Patterns used to extract phone numbers from a larger phone-number-like pattern. These are
 * ordered according to specificity. For example, white-space is last since that is frequently
 * used in numbers, not just to separate two numbers. We have separate patterns since we don't
 * want to break up the phone-number-like text on more than one different kind of symbol at one
 * time, although symbols of the same type (e.g. space) can be safely grouped together.
 *
 * Note that if there is a match, we will always check any text found up to the first match as
 * well.
 */

var INNER_MATCHES = [// Breaks on the slash - e.g. "651-234-2345/332-445-1234"
'\\/+(.*)/', // Note that the bracket here is inside the capturing group, since we consider it part of the
// phone number. Will match a pattern like "(650) 223 3345 (754) 223 3321".
'(\\([^(]*)', // Breaks on a hyphen - e.g. "12345 - 332-445-1234 is my number."
// We require a space on either side of the hyphen for it to be considered a separator.
"(?:".concat(_utf.pZ, "-|-").concat(_utf.pZ, ")").concat(_utf.pZ, "*(.+)"), // Various types of wide hyphens. Note we have decided not to enforce a space here, since it's
// possible that it's supposed to be used to break two numbers without spaces, and we haven't
// seen many instances of it used within a number.
"[\u2012-\u2015\uFF0D]".concat(_utf.pZ, "*(.+)"), // Breaks on a full stop - e.g. "12345. 332-445-1234 is my number."
"\\.+".concat(_utf.pZ, "*([^.]+)"), // Breaks on space - e.g. "3324451234 8002341234"
"".concat(_utf.pZ, "+(").concat(_utf.PZ, "+)")]; // Limit on the number of leading (plus) characters.

var leadLimit = (0, _util.limit)(0, 2); // Limit on the number of consecutive punctuation characters.

var punctuationLimit = (0, _util.limit)(0, 4);
/* The maximum number of digits allowed in a digit-separated block. As we allow all digits in a
 * single block, set high enough to accommodate the entire national number and the international
 * country code. */

var digitBlockLimit = _constants.MAX_LENGTH_FOR_NSN + _constants.MAX_LENGTH_COUNTRY_CODE; // Limit on the number of blocks separated by punctuation.
// Uses digitBlockLimit since some formats use spaces to separate each digit.

var blockLimit = (0, _util.limit)(0, digitBlockLimit);
/* A punctuation sequence allowing white space. */

var punctuation = "[".concat(_constants.VALID_PUNCTUATION, "]") + punctuationLimit; // A digits block without punctuation.

var digitSequence = _utf.pNd + (0, _util.limit)(1, digitBlockLimit);
/**
 * Phone number pattern allowing optional punctuation.
 * The phone number pattern used by `find()`, similar to
 * VALID_PHONE_NUMBER, but with the following differences:
 * <ul>
 *   <li>All captures are limited in order to place an upper bound to the text matched by the
 *       pattern.
 * <ul>
 *   <li>Leading punctuation / plus signs are limited.
 *   <li>Consecutive occurrences of punctuation are limited.
 *   <li>Number of digits is limited.
 * </ul>
 *   <li>No whitespace is allowed at the start or end.
 *   <li>No alpha digits (vanity numbers such as 1-800-SIX-FLAGS) are currently supported.
 * </ul>
 */

var PATTERN = '(?:' + _isValidCandidate.LEAD_CLASS + punctuation + ')' + leadLimit + digitSequence + '(?:' + punctuation + digitSequence + ')' + blockLimit + '(?:' + EXTN_PATTERNS_FOR_MATCHING + ')?'; // Regular expression of trailing characters that we want to remove.
// We remove all characters that are not alpha or numerical characters.
// The hash character is retained here, as it may signify
// the previous block was an extension.
//
// // Don't know what does '&&' mean here.
// const UNWANTED_END_CHAR_PATTERN = new RegExp(`[[\\P{N}&&\\P{L}]&&[^#]]+$`)
//

var UNWANTED_END_CHAR_PATTERN = new RegExp("[^".concat(_utf._pN).concat(_utf._pL, "#]+$"));
var NON_DIGITS_PATTERN = /(\D+)/;
var MAX_SAFE_INTEGER = Number.MAX_SAFE_INTEGER || Math.pow(2, 53) - 1;
/**
 * A stateful class that finds and extracts telephone numbers from {@linkplain CharSequence text}.
 * Instances can be created using the {@linkplain PhoneNumberUtil#findNumbers factory methods} in
 * {@link PhoneNumberUtil}.
 *
 * <p>Vanity numbers (phone numbers using alphabetic digits such as <tt>1-800-SIX-FLAGS</tt> are
 * not found.
 *
 * <p>This class is not thread-safe.
 */

var PhoneNumberMatcher = /*#__PURE__*/function () {
  /**
   * @param {string} text — the character sequence that we will search, null for no text.
   * @param {'POSSIBLE'|'VALID'|'STRICT_GROUPING'|'EXACT_GROUPING'} [options.leniency] — The leniency to use when evaluating candidate phone numbers. See `source/findNumbers/Leniency.js` for more details.
   * @param {number} [options.maxTries] — The maximum number of invalid numbers to try before giving up on the text. This is to cover degenerate cases where the text has a lot of false positives in it. Must be >= 0.
   */
  function PhoneNumberMatcher() {
    var text = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';
    var options = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
    var metadata = arguments.length > 2 ? arguments[2] : undefined;

    _classCallCheck(this, PhoneNumberMatcher);

    options = {
      v2: options.v2,
      defaultCallingCode: options.defaultCallingCode,
      defaultCountry: options.defaultCountry && (0, _metadata.isSupportedCountry)(options.defaultCountry, metadata) ? options.defaultCountry : undefined,
      leniency: options.leniency || (options.extended ? 'POSSIBLE' : 'VALID'),
      maxTries: options.maxTries || MAX_SAFE_INTEGER
    }; // Validate `leniency`.

    if (!options.leniency) {
      throw new TypeError('`leniency` is required');
    }

    if (options.leniency !== 'POSSIBLE' && options.leniency !== 'VALID') {
      throw new TypeError("Invalid `leniency`: \"".concat(options.leniency, "\". Supported values: \"POSSIBLE\", \"VALID\"."));
    } // Validate `maxTries`.


    if (options.maxTries < 0) {
      throw new TypeError('`maxTries` must be `>= 0`');
    }

    this.text = text;
    this.options = options;
    this.metadata = metadata; // The degree of phone number validation.

    this.leniency = _Leniency["default"][options.leniency];

    if (!this.leniency) {
      throw new TypeError("Unknown leniency: \"".concat(options.leniency, "\""));
    }
    /** The maximum number of retries after matching an invalid number. */


    this.maxTries = options.maxTries;
    this.PATTERN = new RegExp(PATTERN, 'ig');
    /** The iteration tristate. */

    this.state = 'NOT_READY';
    /** The next index to start searching at. Undefined in {@link State#DONE}. */

    this.searchIndex = 0; // A cache for frequently used country-specific regular expressions. Set to 32 to cover ~2-3
    // countries being used for the same doc with ~10 patterns for each country. Some pages will have
    // a lot more countries in use, but typically fewer numbers for each so expanding the cache for
    // that use-case won't have a lot of benefit.

    this.regExpCache = new _RegExpCache["default"](32);
  }
  /**
   * Attempts to find the next subsequence in the searched sequence on or after {@code searchIndex}
   * that represents a phone number. Returns the next match, null if none was found.
   *
   * @param index  the search index to start searching at
   * @return  the phone number match found, null if none can be found
   */


  _createClass(PhoneNumberMatcher, [{
    key: "find",
    value: function find() {
      // // Reset the regular expression.
      // this.PATTERN.lastIndex = index
      var matches;

      while (this.maxTries > 0 && (matches = this.PATTERN.exec(this.text)) !== null) {
        var candidate = matches[0];
        var offset = matches.index;
        candidate = (0, _parsePreCandidate["default"])(candidate);

        if ((0, _isValidPreCandidate["default"])(candidate, offset, this.text)) {
          var match = // Try to come up with a valid match given the entire candidate.
          this.parseAndVerify(candidate, offset, this.text) // If that failed, try to find an "inner match" -
          // there might be a phone number within this candidate.
          || this.extractInnerMatch(candidate, offset, this.text);

          if (match) {
            if (this.options.v2) {
              return {
                startsAt: match.startsAt,
                endsAt: match.endsAt,
                number: match.phoneNumber
              };
            } else {
              var phoneNumber = match.phoneNumber;
              var result = {
                startsAt: match.startsAt,
                endsAt: match.endsAt,
                phone: phoneNumber.nationalNumber
              };

              if (phoneNumber.country) {
                /* istanbul ignore if */
                if (USE_NON_GEOGRAPHIC_COUNTRY_CODE && country === '001') {
                  result.countryCallingCode = phoneNumber.countryCallingCode;
                } else {
                  result.country = phoneNumber.country;
                }
              } else {
                result.countryCallingCode = phoneNumber.countryCallingCode;
              }

              if (phoneNumber.ext) {
                result.ext = phoneNumber.ext;
              }

              return result;
            }
          }
        }

        this.maxTries--;
      }
    }
    /**
     * Attempts to extract a match from `substring`
     * if the substring itself does not qualify as a match.
     */

  }, {
    key: "extractInnerMatch",
    value: function extractInnerMatch(substring, offset, text) {
      for (var _iterator = _createForOfIteratorHelperLoose(INNER_MATCHES), _step; !(_step = _iterator()).done;) {
        var innerMatchPattern = _step.value;
        var isFirstMatch = true;
        var candidateMatch = void 0;
        var innerMatchRegExp = new RegExp(innerMatchPattern, 'g');

        while (this.maxTries > 0 && (candidateMatch = innerMatchRegExp.exec(substring)) !== null) {
          if (isFirstMatch) {
            // We should handle any group before this one too.
            var _candidate = (0, _util.trimAfterFirstMatch)(UNWANTED_END_CHAR_PATTERN, substring.slice(0, candidateMatch.index));

            var _match = this.parseAndVerify(_candidate, offset, text);

            if (_match) {
              return _match;
            }

            this.maxTries--;
            isFirstMatch = false;
          }

          var candidate = (0, _util.trimAfterFirstMatch)(UNWANTED_END_CHAR_PATTERN, candidateMatch[1]); // Java code does `groupMatcher.start(1)` here,
          // but there's no way in javascript to get a `candidate` start index,
          // therefore resort to using this kind of an approximation.
          // (`groupMatcher` is called `candidateInSubstringMatch` in this javascript port)
          // https://stackoverflow.com/questions/15934353/get-index-of-each-capture-in-a-javascript-regex

          var candidateIndexGuess = substring.indexOf(candidate, candidateMatch.index);
          var match = this.parseAndVerify(candidate, offset + candidateIndexGuess, text);

          if (match) {
            return match;
          }

          this.maxTries--;
        }
      }
    }
    /**
     * Parses a phone number from the `candidate` using `parse` and
     * verifies it matches the requested `leniency`. If parsing and verification succeed,
     * a corresponding `PhoneNumberMatch` is returned, otherwise this method returns `null`.
     *
     * @param candidate  the candidate match
     * @param offset  the offset of {@code candidate} within {@link #text}
     * @return  the parsed and validated phone number match, or null
     */

  }, {
    key: "parseAndVerify",
    value: function parseAndVerify(candidate, offset, text) {
      if (!(0, _isValidCandidate["default"])(candidate, offset, text, this.options.leniency)) {
        return;
      }

      var phoneNumber = (0, _parsePhoneNumber["default"])(candidate, {
        extended: true,
        defaultCountry: this.options.defaultCountry,
        defaultCallingCode: this.options.defaultCallingCode
      }, this.metadata);

      if (!phoneNumber) {
        return;
      }

      if (!phoneNumber.isPossible()) {
        return;
      }

      if (this.leniency(phoneNumber, {
        candidate: candidate,
        defaultCountry: this.options.defaultCountry,
        metadata: this.metadata,
        regExpCache: this.regExpCache
      })) {
        return {
          startsAt: offset,
          endsAt: offset + candidate.length,
          phoneNumber: phoneNumber
        };
      }
    }
  }, {
    key: "hasNext",
    value: function hasNext() {
      if (this.state === 'NOT_READY') {
        this.lastMatch = this.find(); // (this.searchIndex)

        if (this.lastMatch) {
          // this.searchIndex = this.lastMatch.endsAt
          this.state = 'READY';
        } else {
          this.state = 'DONE';
        }
      }

      return this.state === 'READY';
    }
  }, {
    key: "next",
    value: function next() {
      // Check the state and find the next match as a side-effect if necessary.
      if (!this.hasNext()) {
        throw new Error('No next element');
      } // Don't retain that memory any longer than necessary.


      var result = this.lastMatch;
      this.lastMatch = null;
      this.state = 'NOT_READY';
      return result;
    }
  }]);

  return PhoneNumberMatcher;
}();

exports["default"] = PhoneNumberMatcher;
//# sourceMappingURL=PhoneNumberMatcher.js.map