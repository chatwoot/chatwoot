function structuredDlitemsEvaluate(node, options, virtualNode) {
  const children = virtualNode.children;
  if (!children || !children.length) {
    return false;
  }

  let hasDt = false,
    hasDd = false,
    nodeName;
  for (var i = 0; i < children.length; i++) {
    nodeName = children[i].props.nodeName.toUpperCase();
    if (nodeName === 'DT') {
      hasDt = true;
    }
    if (hasDt && nodeName === 'DD') {
      return false;
    }
    if (nodeName === 'DD') {
      hasDd = true;
    }
  }

  return hasDt || hasDd;
}

export default structuredDlitemsEvaluate;
