/**
 * Return the document or document fragment (shadow DOM)
 * @method getRootNode
 * @memberof axe.utils
 * @param {Element} node
 * @returns {DocumentFragment|Document}
 */
function getRootNode(node) {
  var doc = (node.getRootNode && node.getRootNode()) || document; // this is for backwards compatibility
  if (doc === node) {
    // disconnected node
    doc = document;
  }
  return doc;
}

export default getRootNode;
