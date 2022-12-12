import getNodeFromTree from './get-node-from-tree';

/**
 * Determine whether an element is visible
 * @method isHidden
 * @memberof axe.utils
 * @param {HTMLElement} el The HTMLElement
 * @param {Boolean} recursed
 * @return {Boolean} The element's visibilty status
 */
function isHidden(el, recursed) {
  const node = getNodeFromTree(el);

  // 9 === Node.DOCUMENT
  if (el.nodeType === 9) {
    return false;
  }

  // 11 === Node.DOCUMENT_FRAGMENT_NODE
  if (el.nodeType === 11) {
    el = el.host; // grab the host Node
  }

  if (node && node._isHidden !== null) {
    return node._isHidden;
  }

  const style = window.getComputedStyle(el, null);

  if (
    !style ||
    !el.parentNode ||
    style.getPropertyValue('display') === 'none' ||
    (!recursed &&
      // visibility is only accurate on the first element
      style.getPropertyValue('visibility') === 'hidden') ||
    el.getAttribute('aria-hidden') === 'true'
  ) {
    return true;
  }

  const parent = el.assignedSlot ? el.assignedSlot : el.parentNode;
  const hidden = isHidden(parent, true);

  // cache the results of the isHidden check on the parent tree
  // so we don't have to look at the parent tree again for all its
  // descendants
  if (node) {
    node._isHidden = hidden;
  }

  return hidden;
}

export default isHidden;
