import { isFocusable } from '../../commons/dom';
import { accessibleTextVirtual } from '../../commons/text';

function focusableNoNameEvaluate(node, options, virtualNode) {
  const tabIndex = virtualNode.attr('tabindex');
  const inFocusOrder = isFocusable(virtualNode) && tabIndex > -1;
  if (!inFocusOrder) {
    return false;
  }

  try {
    return !accessibleTextVirtual(virtualNode);
  } catch (e) {
    return undefined;
  }
}

export default focusableNoNameEvaluate;
