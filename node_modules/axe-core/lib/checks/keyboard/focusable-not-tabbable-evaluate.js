import { isModalOpen } from '../../commons/dom';

function focusableNotTabbableEvaluate(node, options, virtualNode) {
  const elementsThatCanBeDisabled = [
    'BUTTON',
    'FIELDSET',
    'INPUT',
    'SELECT',
    'TEXTAREA'
  ];

  const tabbableElements = virtualNode.tabbableElements;

  if (!tabbableElements || !tabbableElements.length) {
    return true;
  }

  const relatedNodes = tabbableElements.reduce((out, { actualNode: el }) => {
    const nodeName = el.nodeName.toUpperCase();
    // populate nodes that cannot be disabled
    if (!elementsThatCanBeDisabled.includes(nodeName)) {
      out.push(el);
    }
    return out;
  }, []);

  this.relatedNodes(relatedNodes);

  if (relatedNodes.length > 0 && isModalOpen()) {
    return true;
  }

  return relatedNodes.length === 0;
}

export default focusableNotTabbableEvaluate;
