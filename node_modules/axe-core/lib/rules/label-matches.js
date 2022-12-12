function labelMatches(node, virtualNode) {
  if (
    virtualNode.props.nodeName !== 'input' ||
    virtualNode.hasAttr('type') === false
  ) {
    return true;
  }

  var type = virtualNode.attr('type').toLowerCase();
  return (
    ['hidden', 'image', 'button', 'submit', 'reset'].includes(type) === false
  );
}

export default labelMatches;
