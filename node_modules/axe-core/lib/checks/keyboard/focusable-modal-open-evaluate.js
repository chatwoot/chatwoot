import { isModalOpen } from '../../commons/dom';

function focusableModalOpenEvaluate(node, options, virtualNode) {
  const tabbableElements = virtualNode.tabbableElements.map(
    ({ actualNode }) => actualNode
  );

  if (!tabbableElements || !tabbableElements.length) {
    return true;
  }

  if (isModalOpen()) {
    this.relatedNodes(tabbableElements);
    return undefined;
  }

  return true;
}

export default focusableModalOpenEvaluate;
