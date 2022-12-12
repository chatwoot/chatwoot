import parseSameOriginStylesheet from './parse-sameorigin-stylesheet';
import parseCrossOriginStylesheet from './parse-crossorigin-stylesheet';

/**
 * Parse a given stylesheet
 *
 * @method parseStylesheet
 * @memberof axe.utils
 * @param {Object} sheet stylesheet to parse
 * @param {Object} options configuration options object from `parseStylesheets`
 * @param {Array<Number>} priority priority of stylesheet
 * @param {Array<String>} importedUrls list of resolved `@import` urls
 * @param {Boolean} isCrossOrigin boolean denoting if a stylesheet is `cross-origin`, passed for re-parsing `cross-origin` sheets
 * @returns {Promise}
 */
function parseStylesheet(
  sheet,
  options,
  priority,
  importedUrls,
  isCrossOrigin = false
) {
  const isSameOrigin = isSameOriginStylesheet(sheet);
  if (isSameOrigin) {
    /**
     * resolve `same-origin` stylesheet
     */
    return parseSameOriginStylesheet(
      sheet,
      options,
      priority,
      importedUrls,
      isCrossOrigin
    );
  }

  /**
   * resolve `cross-origin` stylesheet
   */
  return parseCrossOriginStylesheet(
    sheet.href,
    options,
    priority,
    importedUrls,
    true // -> isCrossOrigin
  );
}

/**
 * Check if a given stylesheet is from the `same-origin`
 * Note:
 * `sheet.cssRules` throws an error on `cross-origin` stylesheets
 *
 * @param {Object} sheet CSS stylesheet
 * @returns {Boolean}
 */
function isSameOriginStylesheet(sheet) {
  try {
    /*eslint no-unused-vars: 0*/
    const rules = sheet.cssRules;

    /**
     * Safari, does not throw an error when accessing cssRules property,
     */
    if (!rules && sheet.href) {
      return false;
    }

    return true;
  } catch (e) {
    return false;
  }
}

export default parseStylesheet;
