import AbstractVirtualNode from '../../core/base/virtual-node/abstract-virtual-node';
import { getNodeFromTree, querySelectorAll } from '../../core/utils';
import focusDisabled from './focus-disabled';

/**
 * Determines if an element is focusable without considering its tabindex
 * @method isNativelyFocusable
 * @memberof axe.commons.dom
 * @instance
 * @param {HTMLElement|VirtualNode} el The HTMLElement
 * @return {Boolean} True if the element is in the focus order but wouldn't be
 * if its tabindex were removed. Else, false.
 */
function isNativelyFocusable(el) {
  const vNode = el instanceof AbstractVirtualNode ? el : getNodeFromTree(el);

  if (!vNode || focusDisabled(vNode)) {
    return false;
  }

  switch (vNode.props.nodeName) {
    case 'a':
    case 'area':
      if (vNode.hasAttr('href')) {
        return true;
      }
      break;
    case 'input':
      return vNode.props.type !== 'hidden';
    case 'textarea':
    case 'select':
    case 'summary':
    case 'button':
      return true;
    case 'details':
      return !querySelectorAll(vNode, 'summary').length;
  }
  return false;
}

export default isNativelyFocusable;
