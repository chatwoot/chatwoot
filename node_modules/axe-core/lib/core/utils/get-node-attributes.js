/**
 * Return the list of attributes of a node.
 * @method getNodeAttributes
 * @memberof axe.utils
 * @param {Element} node
 * @deprecated
 * @returns {NamedNodeMap}
 */
function getNodeAttributes(node) {
  // eslint-disable-next-line no-restricted-syntax
  if (node.attributes instanceof window.NamedNodeMap) {
    // eslint-disable-next-line no-restricted-syntax
    return node.attributes;
  }

  // if the attributes property is not of type NamedNodeMap then the DOM
  // has been clobbered. E.g. <form><input name="attributes"></form>.
  // We can clone the node to isolate it and then return the attributes
  return node.cloneNode(false).attributes;
}

export default getNodeAttributes;
