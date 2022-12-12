/**
 * Get the scroll offset of the document passed in
 * @method getScrollOffset
 * @memberof axe.commons.dom
 * @instance
 * @param {Document} element The element to evaluate, defaults to document
 * @return {Object} Contains the attributes `x` and `y` which contain the scroll offsets
 */
function getScrollOffset(element) {
  if (!element.nodeType && element.document) {
    element = element.document;
  }

  // 9 === Node.DOCUMENT_NODE
  if (element.nodeType === 9) {
    var docElement = element.documentElement,
      body = element.body;

    return {
      left:
        (docElement && docElement.scrollLeft) || (body && body.scrollLeft) || 0,
      top: (docElement && docElement.scrollTop) || (body && body.scrollTop) || 0
    };
  }

  return {
    left: element.scrollLeft,
    top: element.scrollTop
  };
}

export default getScrollOffset;
