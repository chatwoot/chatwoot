import { getNodeFromTree, getScroll } from '../../core/utils';

/**
 * Return the ancestor node that is a scroll region.
 * @param {VirtualNode}
 * @return {VirtualNode|null}
 */
function getScrollAncestor(node) {
  const vNode = getNodeFromTree(node);
  let ancestor = vNode.parent;

  while (ancestor) {
    if (getScroll(ancestor.actualNode)) {
      return ancestor.actualNode;
    }

    ancestor = ancestor.parent;
  }
}

/**
 * Checks whether a parent element visually contains its child, either directly or via scrolling.
 * Assumes that |parent| is an ancestor of |node|.
 * @param {Element} node
 * @param {Element} parent
 * @return {boolean} True if node is visually contained within parent
 */
function contains(node, parent) {
  const rectBound = node.getBoundingClientRect();
  const margin = 0.01;
  const rect = {
    top: rectBound.top + margin,
    bottom: rectBound.bottom - margin,
    left: rectBound.left + margin,
    right: rectBound.right - margin
  };

  const parentRect = parent.getBoundingClientRect();
  const parentTop = parentRect.top;
  const parentLeft = parentRect.left;
  const parentScrollArea = {
    top: parentTop - parent.scrollTop,
    bottom: parentTop - parent.scrollTop + parent.scrollHeight,
    left: parentLeft - parent.scrollLeft,
    right: parentLeft - parent.scrollLeft + parent.scrollWidth
  };

  const style = window.getComputedStyle(parent);

  // if parent element is inline, scrollArea will be too unpredictable
  if (style.getPropertyValue('display') === 'inline') {
    return true;
  }

  //In theory, we should just be able to look at the scroll area as a superset of the parentRect,
  //but that's not true in Firefox
  if (
    (rect.left < parentScrollArea.left && rect.left < parentRect.left) ||
    (rect.top < parentScrollArea.top && rect.top < parentRect.top) ||
    (rect.right > parentScrollArea.right && rect.right > parentRect.right) ||
    (rect.bottom > parentScrollArea.bottom && rect.bottom > parentRect.bottom)
  ) {
    return false;
  }

  if (rect.right > parentRect.right || rect.bottom > parentRect.bottom) {
    return (
      style.overflow === 'scroll' ||
      style.overflow === 'auto' ||
      style.overflow === 'hidden' ||
      parent instanceof window.HTMLBodyElement ||
      parent instanceof window.HTMLHtmlElement
    );
  }

  return true;
}

/**
 * Checks whether a parent element visually contains its child, either directly or via scrolling.
 * Assumes that |parent| is an ancestor of |node|.
 * @method visuallyContains
 * @memberof axe.commons.dom
 * @instance
 * @param {Element} node
 * @param {Element} parent
 * @return {boolean} True if node is visually contained within parent
 */
function visuallyContains(node, parent) {
  const parentScrollAncestor = getScrollAncestor(parent);

  // if the elements share a common scroll parent, we can check if the
  // parent visually contains the node. otherwise we need to check each
  // scroll parent in between the node and the parent since if the
  // element is off screen due to the scroll, it won't be visually contained
  // by the parent
  do {
    const nextScrollAncestor = getScrollAncestor(node);

    if (
      nextScrollAncestor === parentScrollAncestor ||
      nextScrollAncestor === parent
    ) {
      return contains(node, parent);
    }

    node = nextScrollAncestor;
  } while (node);

  return false;
}

export default visuallyContains;
