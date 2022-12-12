/**
 * Function which converts given text to `CSSStyleSheet`
 * - used in `CSSOM` computation.
 * - factory (closure) function, initialized with `document.implementation.createHTMLDocument()`, which uses DOM API for creating `style` elements.
 *
 * @method axe.utils.getStyleSheetFactory
 * @memberof axe.utils
 * @param {Object} dynamicDoc `document.implementation.createHTMLDocument()
 * @param {Object} options an object with properties to construct stylesheet
 * @property {String} options.data text content of the stylesheet
 * @property {Boolean} options.isCrossOrigin flag to notify if the resource was fetched from the network
 * @property {String} options.shadowId (Optional) shadowId if shadowDOM
 * @property {Object} options.root implementation document to create style elements
 * @property {String} options.priority a number indicating the loaded priority of CSS, to denote specificity of styles contained in the sheet.
 * @returns {Function}
 */
function getStyleSheetFactory(dynamicDoc) {
  if (!dynamicDoc) {
    throw new Error(
      'axe.utils.getStyleSheetFactory should be invoked with an argument'
    );
  }

  return options => {
    const {
      data,
      isCrossOrigin = false,
      shadowId,
      root,
      priority,
      isLink = false
    } = options;
    const style = dynamicDoc.createElement('style');
    if (isLink) {
      // as creating a stylesheet as link will need to be awaited
      // till `onload`, it is wise to convert link href to @import statement
      const text = dynamicDoc.createTextNode(`@import "${data.href}"`);
      style.appendChild(text);
    } else {
      style.appendChild(dynamicDoc.createTextNode(data));
    }
    dynamicDoc.head.appendChild(style);
    return {
      sheet: style.sheet,
      isCrossOrigin,
      shadowId,
      root,
      priority
    };
  };
}

export default getStyleSheetFactory;
