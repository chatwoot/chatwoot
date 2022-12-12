import { isFocusable } from '../../commons/dom';

function isElementFocusableEvaluate(node, options, virtualNode) {
  return isFocusable(virtualNode);
}

export default isElementFocusableEvaluate;
