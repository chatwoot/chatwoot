import AbstractVirtualNode from '../../core/base/virtual-node/abstract-virtual-node';
import { getNodeFromTree } from '../../core/utils';

/**
 * Get the text value of aria-label, if any
 *
 * @deprecated Do not use Element directly. Pass VirtualNode instead
 * @param {VirtualNode|Element} element
 * @return {string} ARIA label
 */
function arialabelText(vNode) {
  if (!(vNode instanceof AbstractVirtualNode)) {
    if (vNode.nodeType !== 1) {
      return '';
    }
    vNode = getNodeFromTree(vNode);
  }
  return vNode.attr('aria-label') || '';
}

export default arialabelText;
