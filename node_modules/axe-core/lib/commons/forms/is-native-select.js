import { getNodeFromTree } from '../../core/utils';
import AbstractVirtuaNode from '../../core/base/virtual-node/abstract-virtual-node';

/**
 * Determines if an element is a native select element
 * @method isNativeSelect
 * @memberof axe.commons.forms
 * @param {VirtualNode|Element} node Node to determine if select
 * @returns {Bool}
 */
function isNativeSelect(node) {
  node = node instanceof AbstractVirtuaNode ? node : getNodeFromTree(node);
  const nodeName = node.props.nodeName;
  return nodeName === 'select';
}

export default isNativeSelect;
