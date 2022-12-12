import isVisible from '../dom/is-visible';

/**
 * Returns an array of visible text virtual nodes
 *
 * @method visibleTextNodes
 * @memberof axe.commons.text
 * @instance
 * @param {VirtualNode} vNode
 * @return {VitrualNode[]}
 */
function visibleTextNodes(vNode) {
  const parentVisible = isVisible(vNode.actualNode);
  let nodes = [];
  vNode.children.forEach(child => {
    if (child.actualNode.nodeType === 3) {
      if (parentVisible) {
        nodes.push(child);
      }
    } else {
      nodes = nodes.concat(visibleTextNodes(child));
    }
  });
  return nodes;
}

export default visibleTextNodes;
