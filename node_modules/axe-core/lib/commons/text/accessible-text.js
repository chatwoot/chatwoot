import accessibleTextVirtual from './accessible-text-virtual';
import { getNodeFromTree } from '../../core/utils';

/**
 * Finds virtual node and calls accessibleTextVirtual()
 * IMPORTANT: This method requires the composed tree at axe._tree
 *
 * @param {HTMLElement} element The HTMLElement
 * @param {Object} context
 * @property {Bool} inControlContext
 * @property {Bool} inLabelledByContext
 * @return {string}
 */
function accessibleText(element, context) {
  const virtualNode = getNodeFromTree(element); // throws an exception on purpose if axe._tree not correct
  return accessibleTextVirtual(virtualNode, context);
}

export default accessibleText;
