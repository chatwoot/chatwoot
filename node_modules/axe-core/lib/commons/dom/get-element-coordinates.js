import getScrollOffset from './get-scroll-offset';

/**
 * Get the coordinates of the element passed into the function relative to the document
 * @method getElementCoordinates
 * @memberof axe.commons.dom
 * @instance
 * @param {HTMLElement} element The HTMLElement
 * @return {elementObj} elementObj Returns a `Object` with the following properties, which
 * each hold a value representing the pixels for each of the
 */
/**
 * @typedef elementObj
 * @type {Object}
 * @property {Number} top The top coordinate of the element
 * @property {Number} right The right coordinate of the element
 * @property {Number} bottom The bottom coordinate of the element
 * @property {Number} left The left coordinate of the element
 * @property {Number} width The width of the element
 * @property {Number} height The height of the element
 */
function getElementCoordinates(element) {
  var scrollOffset = getScrollOffset(document),
    xOffset = scrollOffset.left,
    yOffset = scrollOffset.top,
    coords = element.getBoundingClientRect();

  return {
    top: coords.top + yOffset,
    right: coords.right + xOffset,
    bottom: coords.bottom + yOffset,
    left: coords.left + xOffset,
    width: coords.right - coords.left,
    height: coords.bottom - coords.top
  };
}

export default getElementCoordinates;
