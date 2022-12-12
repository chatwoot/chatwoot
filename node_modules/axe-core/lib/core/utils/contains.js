/**
 * Wrapper for Node#contains
 * @method contains
 * @memberof axe.utils
 * @param  {VirtualNode} vNode     The candidate container VirtualNode
 * @param  {VirtualNode} otherVNode The vNode to test is contained by `vNode`
 * @return {Boolean}           Whether `vNode` contains `otherVNode`
 */
function contains(vNode, otherVNode) {
  /*eslint no-bitwise: 0*/

  function containsShadowChild(vNode, otherVNode) {
    if (vNode.shadowId === otherVNode.shadowId) {
      return true;
    }
    return !!vNode.children.find(child => {
      return containsShadowChild(child, otherVNode);
    });
  }

  if (vNode.shadowId || otherVNode.shadowId) {
    return containsShadowChild(vNode, otherVNode);
  }

  if (vNode.actualNode) {
    if (typeof vNode.actualNode.contains === 'function') {
      return vNode.actualNode.contains(otherVNode.actualNode);
    }

    return !!(
      vNode.actualNode.compareDocumentPosition(otherVNode.actualNode) & 16
    );
  } else {
    // fallback for virtualNode only contexts (e.g. linting)
    // @see https://github.com/Financial-Times/polyfill-service/pull/183/files
    do {
      if (otherVNode === vNode) {
        return true;
      }
    } while ((otherVNode = otherVNode && otherVNode.parent));
  }

  return false;
}

export default contains;
