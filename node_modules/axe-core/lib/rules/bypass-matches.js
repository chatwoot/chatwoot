import isInitiatorMatches from './is-initiator-matches';

function bypassMatches(node, virtualNode, context) {
  // the top level window should have an anchor
  if (isInitiatorMatches(node, virtualNode, context)) {
    return !!node.querySelector('a[href]');
  }

  // all iframes do not need an anchor but should be checked for bypass
  // elements (headings, landmarks, etc.)
  return true;
}

export default bypassMatches;
