import { isVisible, isOffscreen } from '../../commons/dom';

function isOnScreenEvaluate(node) {
  // From a visual perspective
  return isVisible(node, false) && !isOffscreen(node);
}

export default isOnScreenEvaluate;
