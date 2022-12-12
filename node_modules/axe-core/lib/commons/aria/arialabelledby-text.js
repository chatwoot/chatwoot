import idrefs from '../dom/idrefs';
import accessibleText from '../text/accessible-text';
import AbstractVirtualNode from '../../core/base/virtual-node/abstract-virtual-node';
import { getNodeFromTree } from '../../core/utils';

/**
 * Get the accessible name based on aria-labelledby
 *
 * @deprecated Do not use Element directly. Pass VirtualNode instead
 * @param {VirtualNode} element
 * @param {Object} context
 * @property {Bool} inLabelledByContext Whether or not the lookup is part of aria-labelledby reference
 * @property {Bool} inControlContext Whether or not the lookup is part of a native label reference
 * @property {Element} startNode First node in accessible name computation
 * @property {Bool} debug Enable logging for formControlValue
 * @return {string} Cancatinated text value for referenced elements
 */
function arialabelledbyText(vNode, context = {}) {
  if (!(vNode instanceof AbstractVirtualNode)) {
    if (vNode.nodeType !== 1) {
      return '';
    }
    vNode = getNodeFromTree(vNode);
  }

  /**
   * Note: The there are significant difference in how many "leads" browsers follow.
   * - Firefox stops after the first IDREF, so it
   * 		doesn't follow aria-labelledby after a for:>ID ref.
   * - Chrome seems to just keep iterating no matter how many levels deep.
   * - AccName-AAM 1.1 suggests going one level deep, but to treat
   * 		each ref type separately.
   *
   * Axe-core's implementation behaves most closely like Firefox as it seems
   *  to be the common denominator. Main difference is that Firefox
   *  includes the value of form controls in addition to aria-label(s),
   *  something no other browser seems to do. Axe doesn't do that.
   */
  if (
    vNode.props.nodeType !== 1 ||
    context.inLabelledByContext ||
    context.inControlContext ||
    !vNode.attr('aria-labelledby')
  ) {
    return '';
  }

  const refs = idrefs(vNode, 'aria-labelledby').filter(elm => elm);
  return refs.reduce((accessibleName, elm) => {
    const accessibleNameAdd = accessibleText(elm, {
      // Prevent the infinite reference loop:
      inLabelledByContext: true,
      startNode: context.startNode || vNode,
      ...context
    });

    if (!accessibleName) {
      return accessibleNameAdd;
    } else {
      return `${accessibleName} ${accessibleNameAdd}`;
    }
  }, '');
}

export default arialabelledbyText;
