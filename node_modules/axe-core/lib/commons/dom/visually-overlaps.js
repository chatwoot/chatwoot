/**
 * Checks whether a parent element visually overlaps a rectangle, either directly or via scrolling.
 * @method visuallyOverlaps
 * @memberof axe.commons.dom
 * @instance
 * @param {DOMRect} rect
 * @param {Element} parent
 * @return {boolean} True if rect is visually contained within parent
 */
function visuallyOverlaps(rect, parent) {
  var parentRect = parent.getBoundingClientRect();
  var parentTop = parentRect.top;
  var parentLeft = parentRect.left;
  var parentScrollArea = {
    top: parentTop - parent.scrollTop,
    bottom: parentTop - parent.scrollTop + parent.scrollHeight,
    left: parentLeft - parent.scrollLeft,
    right: parentLeft - parent.scrollLeft + parent.scrollWidth
  };

  //In theory, we should just be able to look at the scroll area as a superset of the parentRect,
  //but that's not true in Firefox
  if (
    (rect.left > parentScrollArea.right && rect.left > parentRect.right) ||
    (rect.top > parentScrollArea.bottom && rect.top > parentRect.bottom) ||
    (rect.right < parentScrollArea.left && rect.right < parentRect.left) ||
    (rect.bottom < parentScrollArea.top && rect.bottom < parentRect.top)
  ) {
    return false;
  }

  var style = window.getComputedStyle(parent);

  if (rect.left > parentRect.right || rect.top > parentRect.bottom) {
    return (
      style.overflow === 'scroll' ||
      style.overflow === 'auto' ||
      parent instanceof window.HTMLBodyElement ||
      parent instanceof window.HTMLHtmlElement
    );
  }

  return true;
}

export default visuallyOverlaps;
