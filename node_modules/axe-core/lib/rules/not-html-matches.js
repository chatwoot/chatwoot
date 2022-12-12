function notHtmlMatches(node, virtualNode) {
  return virtualNode.props.nodeName !== 'html';
}

export default notHtmlMatches;
