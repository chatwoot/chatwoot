import { getElementByReference, isVisible } from '../../commons/dom';

function skipLinkEvaluate(node) {
  const target = getElementByReference(node, 'href');
  if (target) {
    return isVisible(target, true) || undefined;
  }
  return false;
}

export default skipLinkEvaluate;
