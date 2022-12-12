import { isVisible } from '../../commons/dom';

function accesskeysEvaluate(node) {
  if (isVisible(node, false)) {
    this.data(node.getAttribute('accesskey'));
    this.relatedNodes([node]);
  }
  return true;
}

export default accesskeysEvaluate;
