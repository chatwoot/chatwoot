function pAsHeadingMatches(node) {
  const children = Array.from(node.parentNode.childNodes);
  const nodeText = node.textContent.trim();
  const isSentence = /[.!?:;](?![.!?:;])/g;

  // Check that there is text, and it is not more than a single sentence
  if (nodeText.length === 0 || (nodeText.match(isSentence) || []).length >= 2) {
    return false;
  }

  // Grab sibling p element following the current node
  const siblingsAfter = children
    .slice(children.indexOf(node) + 1)
    .filter(
      elm => elm.nodeName.toUpperCase() === 'P' && elm.textContent.trim() !== ''
    );

  return siblingsAfter.length !== 0;
}

export default pAsHeadingMatches;
