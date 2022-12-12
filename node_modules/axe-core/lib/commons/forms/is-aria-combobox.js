import getExplicitRole from '../aria/get-explicit-role';

/**
 * Determines if an element is an aria combobox element
 * @method isAriaCombobox
 * @memberof axe.commons.forms
 * @param {VirtualNode|Element} node Node to determine if aria combobox
 * @returns {Bool}
 */
function isAriaCombobox(node) {
  const role = getExplicitRole(node);
  return role === 'combobox';
}

export default isAriaCombobox;
