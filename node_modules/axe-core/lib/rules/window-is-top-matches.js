// @deprecated
function windowIsTopMatches(node) {
  return (
    node.ownerDocument.defaultView.self === node.ownerDocument.defaultView.top
  );
}

export default windowIsTopMatches;
