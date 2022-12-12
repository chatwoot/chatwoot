import focusDisabled from './focus-disabled';
import isNativelyFocusable from './is-natively-focusable';
import AbstractVirtualNode from '../../core/base/virtual-node/abstract-virtual-node';
import { getNodeFromTree } from '../../core/utils';

/**
 * Determines if an element is focusable
 * @method isFocusable
 * @memberof axe.commons.dom
 * @instance
 * @param {HTMLElement} el The HTMLElement
 * @return {Boolean} The element's focusability status
 */

function isFocusable(el) {
  const vNode = el instanceof AbstractVirtualNode ? el : getNodeFromTree(el);

  if (vNode.props.nodeType !== 1) {
    return false;
  }

  if (focusDisabled(vNode)) {
    return false;
  } else if (isNativelyFocusable(vNode)) {
    return true;
  }
  // check if the tabindex is specified and a parseable number
  var tabindex = vNode.attr('tabindex');
  if (tabindex && !isNaN(parseInt(tabindex, 10))) {
    return true;
  }

  return false;
}

export default isFocusable;
