/**
 * A port of Google's `PhoneNumberMatcher.java`.
 * https://github.com/googlei18n/libphonenumber/blob/master/java/libphonenumber/src/com/google/i18n/phonenumbers/PhoneNumberMatcher.java
 * Date: 08.03.2018.
 */

import PhoneNumber from './PhoneNumber.js'

import {
  MAX_LENGTH_FOR_NSN,
  MAX_LENGTH_COUNTRY_CODE,
  VALID_PUNCTUATION
} from './constants.js'

import createExtensionPattern from './helpers/extension/createExtensionPattern.js'

import RegExpCache from './findNumbers/RegExpCache.js'

import {
	limit,
	trimAfterFirstMatch
} from './findNumbers/util.js'

import {
	_pL,
	_pN,
	pZ,
	PZ,
	pNd
} from './findNumbers/utf-8.js'

import Leniency from './findNumbers/Leniency.js'
import parsePreCandidate from './findNumbers/parsePreCandidate.js'
import isValidPreCandidate from './findNumbers/isValidPreCandidate.js'
import isValidCandidate, { LEAD_CLASS } from './findNumbers/isValidCandidate.js'

import { isSupportedCountry } from './metadata.js'

import parsePhoneNumber from './parsePhoneNumber.js'

const USE_NON_GEOGRAPHIC_COUNTRY_CODE = false

const EXTN_PATTERNS_FOR_MATCHING = createExtensionPattern('matching')

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
const INNER_MATCHES =
[
	// Breaks on the slash - e.g. "651-234-2345/332-445-1234"
	'\\/+(.*)/',

	// Note that the bracket here is inside the capturing group, since we consider it part of the
	// phone number. Will match a pattern like "(650) 223 3345 (754) 223 3321".
	'(\\([^(]*)',

	// Breaks on a hyphen - e.g. "12345 - 332-445-1234 is my number."
	// We require a space on either side of the hyphen for it to be considered a separator.
	`(?:${pZ}-|-${pZ})${pZ}*(.+)`,

	// Various types of wide hyphens. Note we have decided not to enforce a space here, since it's
	// possible that it's supposed to be used to break two numbers without spaces, and we haven't
	// seen many instances of it used within a number.
	`[\u2012-\u2015\uFF0D]${pZ}*(.+)`,

	// Breaks on a full stop - e.g. "12345. 332-445-1234 is my number."
	`\\.+${pZ}*([^.]+)`,

	// Breaks on space - e.g. "3324451234 8002341234"
	`${pZ}+(${PZ}+)`
]

// Limit on the number of leading (plus) characters.
const leadLimit = limit(0, 2)

// Limit on the number of consecutive punctuation characters.
const punctuationLimit = limit(0, 4)

/* The maximum number of digits allowed in a digit-separated block. As we allow all digits in a
 * single block, set high enough to accommodate the entire national number and the international
 * country code. */
const digitBlockLimit = MAX_LENGTH_FOR_NSN + MAX_LENGTH_COUNTRY_CODE

// Limit on the number of blocks separated by punctuation.
// Uses digitBlockLimit since some formats use spaces to separate each digit.
const blockLimit = limit(0, digitBlockLimit)

/* A punctuation sequence allowing white space. */
const punctuation = `[${VALID_PUNCTUATION}]` + punctuationLimit

// A digits block without punctuation.
const digitSequence = pNd + limit(1, digitBlockLimit)

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
const PATTERN = '(?:' + LEAD_CLASS + punctuation + ')' + leadLimit
	+ digitSequence + '(?:' + punctuation + digitSequence + ')' + blockLimit
	+ '(?:' + EXTN_PATTERNS_FOR_MATCHING + ')?'

// Regular expression of trailing characters that we want to remove.
// We remove all characters that are not alpha or numerical characters.
// The hash character is retained here, as it may signify
// the previous block was an extension.
//
// // Don't know what does '&&' mean here.
// const UNWANTED_END_CHAR_PATTERN = new RegExp(`[[\\P{N}&&\\P{L}]&&[^#]]+$`)
//
const UNWANTED_END_CHAR_PATTERN = new RegExp(`[^${_pN}${_pL}#]+$`)

const NON_DIGITS_PATTERN = /(\D+)/

const MAX_SAFE_INTEGER = Number.MAX_SAFE_INTEGER || Math.pow(2, 53) - 1

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
export default class PhoneNumberMatcher
{
  /**
   * @param {string} text — the character sequence that we will search, null for no text.
   * @param {'POSSIBLE'|'VALID'|'STRICT_GROUPING'|'EXACT_GROUPING'} [options.leniency] — The leniency to use when evaluating candidate phone numbers. See `source/findNumbers/Leniency.js` for more details.
   * @param {number} [options.maxTries] — The maximum number of invalid numbers to try before giving up on the text. This is to cover degenerate cases where the text has a lot of false positives in it. Must be >= 0.
   */
  constructor(text = '', options = {}, metadata)
  {
    options = {
      v2: options.v2,
      defaultCallingCode: options.defaultCallingCode,
      defaultCountry: options.defaultCountry && isSupportedCountry(options.defaultCountry, metadata) ? options.defaultCountry : undefined,
      leniency: options.leniency || (options.extended ? 'POSSIBLE' : 'VALID'),
      maxTries: options.maxTries || MAX_SAFE_INTEGER
    }

    // Validate `leniency`.
		if (!options.leniency) {
			throw new TypeError('`leniency` is required')
		}
    if (options.leniency !== 'POSSIBLE' && options.leniency !== 'VALID') {
      throw new TypeError(`Invalid \`leniency\`: "${options.leniency}". Supported values: "POSSIBLE", "VALID".`)
    }

    // Validate `maxTries`.
		if (options.maxTries < 0) {
			throw new TypeError('`maxTries` must be `>= 0`')
		}

		this.text = text
		this.options = options
    this.metadata = metadata

		// The degree of phone number validation.
		this.leniency = Leniency[options.leniency]

		if (!this.leniency) {
			throw new TypeError(`Unknown leniency: "${options.leniency}"`)
		}

		/** The maximum number of retries after matching an invalid number. */
		this.maxTries = options.maxTries

		this.PATTERN = new RegExp(PATTERN, 'ig')

    /** The iteration tristate. */
    this.state = 'NOT_READY'

    /** The next index to start searching at. Undefined in {@link State#DONE}. */
    this.searchIndex = 0

    // A cache for frequently used country-specific regular expressions. Set to 32 to cover ~2-3
    // countries being used for the same doc with ~10 patterns for each country. Some pages will have
    // a lot more countries in use, but typically fewer numbers for each so expanding the cache for
    // that use-case won't have a lot of benefit.
    this.regExpCache = new RegExpCache(32)
  }

  /**
   * Attempts to find the next subsequence in the searched sequence on or after {@code searchIndex}
   * that represents a phone number. Returns the next match, null if none was found.
   *
   * @param index  the search index to start searching at
   * @return  the phone number match found, null if none can be found
   */
	find() {
		// // Reset the regular expression.
		// this.PATTERN.lastIndex = index

		let matches
		while ((this.maxTries > 0) && (matches = this.PATTERN.exec(this.text)) !== null) {
			let candidate = matches[0]
			const offset = matches.index

			candidate = parsePreCandidate(candidate)

			if (isValidPreCandidate(candidate, offset, this.text)) {
				const match =
					// Try to come up with a valid match given the entire candidate.
					this.parseAndVerify(candidate, offset, this.text)
					// If that failed, try to find an "inner match" -
					// there might be a phone number within this candidate.
					|| this.extractInnerMatch(candidate, offset, this.text)

				if (match) {
					if (this.options.v2) {
						return {
							startsAt: match.startsAt,
							endsAt: match.endsAt,
							number: match.phoneNumber
						}
					} else {
            const { phoneNumber } = match

            const result = {
              startsAt: match.startsAt,
              endsAt: match.endsAt,
              phone: phoneNumber.nationalNumber
            }

            if (phoneNumber.country) {
              /* istanbul ignore if */
              if (USE_NON_GEOGRAPHIC_COUNTRY_CODE && country === '001') {
                result.countryCallingCode = phoneNumber.countryCallingCode
              } else {
                result.country = phoneNumber.country
              }
            } else {
              result.countryCallingCode = phoneNumber.countryCallingCode
            }

            if (phoneNumber.ext) {
              result.ext = phoneNumber.ext
            }

            return result
          }
				}
			}

			this.maxTries--
		}
	}

  /**
   * Attempts to extract a match from `substring`
   * if the substring itself does not qualify as a match.
   */
  extractInnerMatch(substring, offset, text) {
    for (const innerMatchPattern of INNER_MATCHES) {
      let isFirstMatch = true
      let candidateMatch
      const innerMatchRegExp = new RegExp(innerMatchPattern, 'g')
      while (this.maxTries > 0 && (candidateMatch = innerMatchRegExp.exec(substring)) !== null) {
        if (isFirstMatch) {
          // We should handle any group before this one too.
          const candidate = trimAfterFirstMatch(
            UNWANTED_END_CHAR_PATTERN,
            substring.slice(0, candidateMatch.index)
          )

          const match = this.parseAndVerify(candidate, offset, text)

          if (match) {
            return match
          }

          this.maxTries--
          isFirstMatch = false
        }

        const candidate = trimAfterFirstMatch(UNWANTED_END_CHAR_PATTERN, candidateMatch[1])

        // Java code does `groupMatcher.start(1)` here,
        // but there's no way in javascript to get a `candidate` start index,
        // therefore resort to using this kind of an approximation.
        // (`groupMatcher` is called `candidateInSubstringMatch` in this javascript port)
        // https://stackoverflow.com/questions/15934353/get-index-of-each-capture-in-a-javascript-regex
        const candidateIndexGuess = substring.indexOf(candidate, candidateMatch.index)

        const match = this.parseAndVerify(candidate, offset + candidateIndexGuess, text)
        if (match) {
          return match
        }

        this.maxTries--
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
  parseAndVerify(candidate, offset, text) {
    if (!isValidCandidate(candidate, offset, text, this.options.leniency)) {
      return
  	}

    const phoneNumber = parsePhoneNumber(
      candidate,
      {
        extended: true,
        defaultCountry: this.options.defaultCountry,
        defaultCallingCode: this.options.defaultCallingCode
      },
      this.metadata
    )

    if (!phoneNumber) {
      return
    }

    if (!phoneNumber.isPossible()) {
      return
    }

    if (this.leniency(phoneNumber, {
      candidate,
      defaultCountry: this.options.defaultCountry,
      metadata: this.metadata,
      regExpCache: this.regExpCache
    })) {
      return {
        startsAt: offset,
        endsAt: offset + candidate.length,
        phoneNumber
      }
    }
  }

  hasNext()
  {
    if (this.state === 'NOT_READY')
    {
      this.lastMatch = this.find() // (this.searchIndex)

      if (this.lastMatch)
      {
        // this.searchIndex = this.lastMatch.endsAt
        this.state = 'READY'
      }
      else
      {
        this.state = 'DONE'
      }
    }

    return this.state === 'READY'
  }

  next()
  {
    // Check the state and find the next match as a side-effect if necessary.
    if (!this.hasNext())
    {
      throw new Error('No next element')
    }

    // Don't retain that memory any longer than necessary.
    const result = this.lastMatch
    this.lastMatch = null
    this.state = 'NOT_READY'
    return result
  }
}