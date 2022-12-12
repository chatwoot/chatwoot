/**
 * Get an element's parent in the flattened tree
 * @method getComposedParent
 * @memberof axe.commons.dom
 * @instance
 * @param {Node} element
 * @return {Node|null} Parent element or Null for root node
 */
function getComposedParent(element) {
  if (element.assignedSlot) {
    // NOTE: If the display of a slot element isn't 'contents',
    // the slot shouldn't be ignored. Chrome does not support this (yet) so,
    // we'll skip this part for now.
    return getComposedParent(element.assignedSlot); // parent of a shadow DOM slot
  } else if (element.parentNode) {
    var parentNode = element.parentNode;
    if (parentNode.nodeType === 1) {
      return parentNode; // Regular node
    } else if (parentNode.host) {
      return parentNode.host; // Shadow root
    }
  }
  return null; // Root node
}

export default getComposedParent;
