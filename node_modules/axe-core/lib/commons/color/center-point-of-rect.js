/**
 * Get coordinates for an element's client rects or bounding client rect
 *
 * @method centerPointOfRect
 * @memberof axe.commons.color
 * @param {DOMRect} rect
 * @deprecated
 * @returns {Object | undefined}
 */
function centerPointOfRect(rect) {
  if (rect.left > window.innerWidth) {
    return undefined;
  }

  if (rect.top > window.innerHeight) {
    return undefined;
  }

  const x = Math.min(
    Math.ceil(rect.left + rect.width / 2),
    window.innerWidth - 1
  );
  const y = Math.min(
    Math.ceil(rect.top + rect.height / 2),
    window.innerHeight - 1
  );

  return { x, y };
}

export default centerPointOfRect;
