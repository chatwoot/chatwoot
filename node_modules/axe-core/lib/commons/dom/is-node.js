/**
 * Determines if element is an instance of Node
 * @method isNode
 * @memberof axe.commons.dom
 * @instance
 * @deprecated
 * @param  {Element} element
 * @return {Boolean}
 */
function isNode(element) {
  return element instanceof window.Node;
}

export default isNode;
