function nonEmptyIfPresentEvaluate(node, options, virtualNode) {
  // Check for 'default' names, which are given to reset and submit buttons
  const nodeName = virtualNode.props.nodeName;
  const type = (virtualNode.attr('type') || '').toLowerCase();
  const label = virtualNode.attr('value');

  if (label) {
    this.data({
      messageKey: 'has-label'
    });
  }

  if (nodeName === 'input' && ['submit', 'reset'].includes(type)) {
    return label === null;
  }
  return false;
}

export default nonEmptyIfPresentEvaluate;
