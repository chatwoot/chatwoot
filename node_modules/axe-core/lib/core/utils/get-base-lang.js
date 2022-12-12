/**
 * Convenience function to extract primary language subtag from a given value
 * @method getBaseLang
 * @memberof axe.utils
 * @param {String} value value specified as lang or xml:lang attribute
 * @return {String}
 */
function getBaseLang(lang) {
  if (!lang) {
    return '';
  }
  return lang
    .trim()
    .split('-')[0]
    .toLowerCase();
}

export default getBaseLang;
