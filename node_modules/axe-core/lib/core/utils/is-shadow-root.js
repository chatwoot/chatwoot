const possibleShadowRoots = [
  'article',
  'aside',
  'blockquote',
  'body',
  'div',
  'footer',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'main',
  'nav',
  'p',
  'section',
  'span'
];
/**
 * Test a node to see if it has a spec-conforming shadow root
 *
 * @param {Node}   node  The HTML DOM node
 * @return {Boolean}
 */
function isShadowRoot(node) {
  if (node.shadowRoot) {
    const nodeName = node.nodeName.toLowerCase();
    if (
      possibleShadowRoots.includes(nodeName) ||
      /^[a-z][a-z0-9_.-]*-[a-z0-9_.-]*$/.test(nodeName)
    ) {
      return true;
    }
  }
  return false;
}

export default isShadowRoot;
