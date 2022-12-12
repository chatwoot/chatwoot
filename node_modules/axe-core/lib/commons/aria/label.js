import labelVirtual from './label-virtual';
import { getNodeFromTree } from '../../core/utils';

/**
 * Gets the aria label for a given node
 * @method label
 * @memberof axe.commons.aria
 * @instance
 * @param  {HTMLElement} node The element to check
 * @return {Mixed} String of visible text, or `null` if no label is found
 */
function label(node) {
  node = getNodeFromTree(node);
  return labelVirtual(node);
}

export default label;
