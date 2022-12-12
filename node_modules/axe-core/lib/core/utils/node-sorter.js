/**
 * Array#sort callback to sort nodes by DOM order
 * @private
 * @param  {Node} nodeA
 * @param  {Node} nodeB
 * @return {Integer}   @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/Sort
 */
function nodeSorter(nodeA, nodeB) {
  /*eslint no-bitwise: 0 */
  nodeA = nodeA.actualNode || nodeA;
  nodeB = nodeB.actualNode || nodeB;
  if (nodeA === nodeB) {
    return 0;
  }

  if (nodeA.compareDocumentPosition(nodeB) & 4) {
    return -1; // a before b
  } else {
    return 1; // b before a
  }
}

export default nodeSorter;
