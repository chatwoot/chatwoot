import { getRootNode } from '../../commons/dom';
import { escapeSelector } from '../../core/utils';

function duplicateIdEvaluate(node) {
  const id = node.getAttribute('id').trim();
  // Since empty ID's are not meaningful and are ignored by Edge, we'll
  // let those pass.
  if (!id) {
    return true;
  }
  const root = getRootNode(node);
  const matchingNodes = Array.from(
    root.querySelectorAll(`[id="${escapeSelector(id)}"]`)
  ).filter(foundNode => foundNode !== node);

  if (matchingNodes.length) {
    this.relatedNodes(matchingNodes);
  }
  this.data(id);

  return matchingNodes.length === 0;
}

export default duplicateIdEvaluate;
