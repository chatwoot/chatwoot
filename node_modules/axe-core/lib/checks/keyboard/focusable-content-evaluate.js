function focusableContentEvaluate(node, options, virtualNode) {
  /**
   * Note:
   * Check if given node contains focusable elements (excluding thyself)
   */
  const tabbableElements = virtualNode.tabbableElements;

  if (!tabbableElements) {
    return false;
  }

  // remove thyself from tabbable elements (if exists)
  const tabbableContentElements = tabbableElements.filter(
    el => el !== virtualNode
  );

  return tabbableContentElements.length > 0;
}

export default focusableContentEvaluate;
