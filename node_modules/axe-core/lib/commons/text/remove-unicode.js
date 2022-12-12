import {
  getUnicodeNonBmpRegExp,
  getSupplementaryPrivateUseRegExp,
  getPunctuationRegExp
} from './unicode.js';
import emojiRegexText from 'emoji-regex';

/**
 * Remove specified type(s) unicode characters
 *
 * @method removeUnicode
 * @memberof axe.commons.text
 * @instance
 * @param {String} str string to operate on
 * @param {Object} options config containing which unicode character sets to remove
 * @property {Boolean} options.emoji remove emoji unicode
 * @property {Boolean} options.nonBmp remove nonBmp unicode
 * @property {Boolean} options.punctuations remove punctuations unicode
 * @returns {String}
 */
function removeUnicode(str, options) {
  const { emoji, nonBmp, punctuations } = options;

  if (emoji) {
    str = str.replace(emojiRegexText(), '');
  }
  if (nonBmp) {
    str = str.replace(getUnicodeNonBmpRegExp(), '');
    str = str.replace(getSupplementaryPrivateUseRegExp(), '');
  }
  if (punctuations) {
    str = str.replace(getPunctuationRegExp(), '');
  }

  return str;
}

export default removeUnicode;
