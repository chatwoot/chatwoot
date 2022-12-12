function hasAltEvaluate(node, options, virtualNode) {
  const { nodeName } = virtualNode.props;
  if (!['img', 'input', 'area'].includes(nodeName)) {
    return false;
  }

  return virtualNode.hasAttr('alt');
}

export default hasAltEvaluate;
