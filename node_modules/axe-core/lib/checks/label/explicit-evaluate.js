import { getRootNode, isVisible } from '../../commons/dom';
import { accessibleText } from '../../commons/text';
import { escapeSelector } from '../../core/utils';

function explicitEvaluate(node, options, virtualNode) {
  if (virtualNode.attr('id')) {
    if (!virtualNode.actualNode) {
      return undefined;
    }

    const root = getRootNode(virtualNode.actualNode);
    const id = escapeSelector(virtualNode.attr('id'));
    const labels = Array.from(root.querySelectorAll(`label[for="${id}"]`));

    if (labels.length) {
      try {
        return labels.some(label => {
          // defer to hidden-explicit-label check for better messaging
          if (!isVisible(label)) {
            return true;
          } else {
            return !!accessibleText(label);
          }
        });
      } catch (e) {
        return undefined;
      }
    }
  }

  return false;
}

export default explicitEvaluate;
