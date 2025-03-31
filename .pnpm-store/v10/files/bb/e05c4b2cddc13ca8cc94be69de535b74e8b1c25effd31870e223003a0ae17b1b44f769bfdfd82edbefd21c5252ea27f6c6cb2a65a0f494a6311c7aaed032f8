"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.WHITESPACE = exports.VALID_PUNCTUATION = exports.VALID_DIGITS = exports.PLUS_CHARS = exports.MIN_LENGTH_FOR_NSN = exports.MAX_LENGTH_FOR_NSN = exports.MAX_LENGTH_COUNTRY_CODE = void 0;
// The minimum length of the national significant number.
var MIN_LENGTH_FOR_NSN = 2; // The ITU says the maximum length should be 15,
// but one can find longer numbers in Germany.

exports.MIN_LENGTH_FOR_NSN = MIN_LENGTH_FOR_NSN;
var MAX_LENGTH_FOR_NSN = 17; // The maximum length of the country calling code.

exports.MAX_LENGTH_FOR_NSN = MAX_LENGTH_FOR_NSN;
var MAX_LENGTH_COUNTRY_CODE = 3; // Digits accepted in phone numbers
// (ascii, fullwidth, arabic-indic, and eastern arabic digits).

exports.MAX_LENGTH_COUNTRY_CODE = MAX_LENGTH_COUNTRY_CODE;
var VALID_DIGITS = "0-9\uFF10-\uFF19\u0660-\u0669\u06F0-\u06F9"; // `DASHES` will be right after the opening square bracket of the "character class"

exports.VALID_DIGITS = VALID_DIGITS;
var DASHES = "-\u2010-\u2015\u2212\u30FC\uFF0D";
var SLASHES = "\uFF0F/";
var DOTS = "\uFF0E.";
var WHITESPACE = " \xA0\xAD\u200B\u2060\u3000";
exports.WHITESPACE = WHITESPACE;
var BRACKETS = "()\uFF08\uFF09\uFF3B\uFF3D\\[\\]"; // export const OPENING_BRACKETS = '(\uFF08\uFF3B\\\['

var TILDES = "~\u2053\u223C\uFF5E"; // Regular expression of acceptable punctuation found in phone numbers. This
// excludes punctuation found as a leading character only. This consists of dash
// characters, white space characters, full stops, slashes, square brackets,
// parentheses and tildes. Full-width variants are also present.

var VALID_PUNCTUATION = "".concat(DASHES).concat(SLASHES).concat(DOTS).concat(WHITESPACE).concat(BRACKETS).concat(TILDES);
exports.VALID_PUNCTUATION = VALID_PUNCTUATION;
var PLUS_CHARS = "+\uFF0B"; // const LEADING_PLUS_CHARS_PATTERN = new RegExp('^[' + PLUS_CHARS + ']+')

exports.PLUS_CHARS = PLUS_CHARS;
//# sourceMappingURL=constants.js.map