// The minimum length of the national significant number.
export const MIN_LENGTH_FOR_NSN = 2

// The ITU says the maximum length should be 15,
// but one can find longer numbers in Germany.
export const MAX_LENGTH_FOR_NSN = 17

// The maximum length of the country calling code.
export const MAX_LENGTH_COUNTRY_CODE = 3

// Digits accepted in phone numbers
// (ascii, fullwidth, arabic-indic, and eastern arabic digits).
export const VALID_DIGITS = '0-9\uFF10-\uFF19\u0660-\u0669\u06F0-\u06F9'

// `DASHES` will be right after the opening square bracket of the "character class"
const DASHES = '-\u2010-\u2015\u2212\u30FC\uFF0D'
const SLASHES = '\uFF0F/'
const DOTS = '\uFF0E.'
export const WHITESPACE = ' \u00A0\u00AD\u200B\u2060\u3000'
const BRACKETS = '()\uFF08\uFF09\uFF3B\uFF3D\\[\\]'
// export const OPENING_BRACKETS = '(\uFF08\uFF3B\\\['
const TILDES = '~\u2053\u223C\uFF5E'

// Regular expression of acceptable punctuation found in phone numbers. This
// excludes punctuation found as a leading character only. This consists of dash
// characters, white space characters, full stops, slashes, square brackets,
// parentheses and tildes. Full-width variants are also present.
export const VALID_PUNCTUATION = `${DASHES}${SLASHES}${DOTS}${WHITESPACE}${BRACKETS}${TILDES}`

export const PLUS_CHARS = '+\uFF0B'
// const LEADING_PLUS_CHARS_PATTERN = new RegExp('^[' + PLUS_CHARS + ']+')