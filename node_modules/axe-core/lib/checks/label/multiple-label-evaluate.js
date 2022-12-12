import { getRootNode, isVisible, idrefs } from '../../commons/dom';
import { escapeSelector } from '../../core/utils';

function multipleLabelEvaluate(node) {
  const id = escapeSelector(node.getAttribute('id'));
  let parent = node.parentNode;
  let root = getRootNode(node);
  root = root.documentElement || root;
  let labels = Array.from(root.querySelectorAll(`label[for="${id}"]`));

  if (labels.length) {
    // filter out CSS hidden labels because they're fine
    labels = labels.filter(label => isVisible(label));
  }

  while (parent) {
    if (
      parent.nodeName.toUpperCase() === 'LABEL' &&
      labels.indexOf(parent) === -1
    ) {
      labels.push(parent);
    }
    parent = parent.parentNode;
  }

  this.relatedNodes(labels);

  // more than 1 CSS visible label
  if (labels.length > 1) {
    const ATVisibleLabels = labels.filter(label => isVisible(label, true));
    // more than 1 AT visible label will fail IOS/Safari/VO even with aria-labelledby
    if (ATVisibleLabels.length > 1) {
      return undefined;
    }
    // make sure the ONE AT visible label is in the list of idRefs of aria-labelledby
    const labelledby = idrefs(node, 'aria-labelledby');
    return !labelledby.includes(ATVisibleLabels[0]) ? undefined : false;
  }

  // only 1 CSS visible label
  return false;
}

export default multipleLabelEvaluate;
