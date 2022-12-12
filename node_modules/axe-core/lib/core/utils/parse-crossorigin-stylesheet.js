import parseStylesheet from './parse-stylesheet';
import constants from '../constants';

/**
 * Parse cross-origin stylesheets
 *
 * @method parseCrossOriginStylesheet
 * @memberof axe.utils
 * @param {String} url url from which to fetch stylesheet
 * @param {Object} options options object from `axe.utils.parseStylesheet`
 * @param {Array<Number>} priority sheet priority
 * @param {Array<String>} importedUrls urls of already imported stylesheets
 * @param {Boolean} isCrossOrigin boolean denoting if a stylesheet is `cross-origin`
 * @returns {Promise}
 */
function parseCrossOriginStylesheet(
  url,
  options,
  priority,
  importedUrls,
  isCrossOrigin
) {
  /**
   * Add `url` to `importedUrls`
   */
  importedUrls.push(url);

  return new Promise((resolve, reject) => {
    const request = new XMLHttpRequest();
    request.open('GET', url);

    request.timeout = constants.preload.timeout;
    request.addEventListener('error', reject);
    request.addEventListener('timeout', reject);
    request.addEventListener('loadend', event => {
      if (event.loaded && request.responseText) {
        return resolve(request.responseText);
      }

      reject(request.responseText);
    });

    request.send();
  }).then(data => {
    const result = options.convertDataToStylesheet({
      data,
      isCrossOrigin,
      priority,
      root: options.rootNode,
      shadowId: options.shadowId
    });

    /**
     * Parse resolved stylesheet further for any `@import` styles
     */
    return parseStylesheet(
      result.sheet,
      options,
      priority,
      importedUrls,
      result.isCrossOrigin
    );
  });
}

export default parseCrossOriginStylesheet;
