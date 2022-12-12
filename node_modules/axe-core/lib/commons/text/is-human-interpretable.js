import removeUnicode from './remove-unicode';
import sanitize from './sanitize';

/**
 * Determines if a given text is human friendly and interpretable
 *
 * @method isHumanInterpretable
 * @memberof axe.commons.text
 * @instance
 * @param  {String} str text to be validated
 * @returns {Number} Between 0 and 1, (0 -> not interpretable, 1 -> interpretable)
 */
function isHumanInterpretable(str) {
  /**
   * Steps:
   * 1) Check for single character edge cases
   * 		a) handle if character is alphanumeric & within the given icon mapping
   * 					eg: x (close), i (info)
   *
   * 3) handle unicode from astral  (non bilingual multi plane) unicode, emoji & punctuations
   * 					eg: Windings font
   * 					eg: '💪'
   * 					eg: I saw a shooting 💫
   * 					eg: ? (help), > (next arrow), < (back arrow), need help ?
   */

  if (!str.length) {
    return 0;
  }

  // Step 1
  const alphaNumericIconMap = [
    'x', // close
    'i' // info
  ];
  // Step 1a
  if (alphaNumericIconMap.includes(str)) {
    return 0;
  }

  // Step 2
  const noUnicodeStr = removeUnicode(str, {
    emoji: true,
    nonBmp: true,
    punctuations: true
  });
  if (!sanitize(noUnicodeStr)) {
    return 0;
  }

  return 1;
}

export default isHumanInterpretable;
