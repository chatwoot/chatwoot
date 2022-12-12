import getAccessibleRefs from './get-accessible-refs';

/**
 * Check that a DOM node is a reference in the accessibility tree
 * @param {Element} node
 * @returns {Boolean}
 */
function isAccessibleRef(node) {
  return !!getAccessibleRefs(node).length;
}

export default isAccessibleRef;
