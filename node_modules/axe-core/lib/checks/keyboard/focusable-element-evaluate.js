import { closest } from '../../core/utils';

function focusableElementEvaluate(node, options, virtualNode) {
  /**
   * Note:
   * Check
   * - if element is focusable
   * - if element is in focus order via `tabindex`
   */
  if (
    virtualNode.hasAttr('contenteditable') &&
    isContenteditable(virtualNode)
  ) {
    return true;
  }

  const isFocusable = virtualNode.isFocusable;
  let tabIndex = parseInt(virtualNode.attr('tabindex'), 10);
  tabIndex = !isNaN(tabIndex) ? tabIndex : null;

  return tabIndex ? isFocusable && tabIndex >= 0 : isFocusable;

  // contenteditable is focusable when it is an empty string (whitespace
  // is not considered empty) or "true". if the value is "false"
  // you can't edit it, but if it's anything else it inherits the value
  // from the first valid ancestor
  // @see https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/contenteditable
  function isContenteditable(vNode) {
    const contenteditable = vNode.attr('contenteditable');
    if (contenteditable === 'true' || contenteditable === '') {
      return true;
    }

    if (contenteditable === 'false') {
      return false;
    }

    const ancestor = closest(virtualNode.parent, '[contenteditable]');
    if (!ancestor) {
      return false;
    }

    return isContenteditable(ancestor);
  }
}

export default focusableElementEvaluate;
