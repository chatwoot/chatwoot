import contains from './contains';

/**
 * Get the deepest node in a given collection
 * @private
 * @param  {Array} collection Array of nodes to test
 * @return {Node}             The deepest node
 */
function getDeepest(collection) {
  return collection.sort((a, b) => {
    if (contains(a, b)) {
      return 1;
    }
    return -1;
  })[0];
}

/**
 * Determines if a node is included or excluded in a given context
 * @private
 * @param  {Node}  node     The node to test
 * @param  {Object}  context "Resolved" context object, @see resolveContext
 * @return {Boolean}         [description]
 */
function isNodeInContext(node, context) {
  const include =
    context.include &&
    getDeepest(
      context.include.filter(candidate => {
        return contains(candidate, node);
      })
    );
  const exclude =
    context.exclude &&
    getDeepest(
      context.exclude.filter(candidate => {
        return contains(candidate, node);
      })
    );
  if ((!exclude && include) || (exclude && contains(exclude, include))) {
    return true;
  }
  return false;
}

export default isNodeInContext;
