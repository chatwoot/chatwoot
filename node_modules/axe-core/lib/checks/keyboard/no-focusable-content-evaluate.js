import isFocusable from '../../commons/dom/is-focusable';

function focusableDescendants(vNode) {
  if (isFocusable(vNode)) {
    return true;
  }

  if (!vNode.children) {
    if (vNode.props.nodeType === 1) {
      throw new Error('Cannot determine children');
    }

    return false;
  }

  return vNode.children.some(child => {
    return focusableDescendants(child);
  });
}

function noFocusbleContentEvaluate(node, options, virtualNode) {
  if (!virtualNode.children) {
    return undefined;
  }

  try {
    return !virtualNode.children.some(child => {
      return focusableDescendants(child);
    });
  } catch (e) {
    return undefined;
  }
}

export default noFocusbleContentEvaluate;
