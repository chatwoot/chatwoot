import getExplicitRole from '../aria/get-explicit-role';

/**
 * Determines if an element is an aria listbox element
 * @method isAriaListbox
 * @memberof axe.commons.forms
 * @param {VirtualNode|Element} node Node to determine if aria listbox
 * @returns {Bool}
 */
function isAriaListbox(node) {
  const role = getExplicitRole(node);
  return role === 'listbox';
}

export default isAriaListbox;
