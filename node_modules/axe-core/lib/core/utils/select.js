import contains from './contains';
import querySelectorAllFilter from './query-selector-all-filter';
import isNodeInContext from './is-node-in-context';

/**
 * Pushes unique nodes that are in context to an array
 * @private
 * @param  {Array} result  The array to push to
 * @param  {Array} nodes   The list of nodes to push
 * @param  {Object} context The "resolved" context object, @see resolveContext
 */
function pushNode(result, nodes) {
  let temp;

  if (result.length === 0) {
    return nodes;
  }
  if (result.length < nodes.length) {
    // switch so the comparison is shortest
    temp = result;
    result = nodes;
    nodes = temp;
  }
  for (let i = 0, l = nodes.length; i < l; i++) {
    if (!result.includes(nodes[i])) {
      result.push(nodes[i]);
    }
  }
  return result;
}

/**
 * reduces the includes list to only the outermost includes
 * @param {Array} the array of include nodes
 * @return {Array} the modified array of nodes
 */
function reduceIncludes(includes) {
  return includes.reduce((res, el) => {
    if (!res.length || !contains(res[res.length - 1], el)) {
      res.push(el);
    }
    return res;
  }, []);
}

/**
 * Selects elements which match `selector` that are included and excluded via the `Context` object
 * @param  {String} selector  CSS selector of the HTMLElements to select
 * @param  {Context} context  The "resolved" context object, @see Context
 * @return {Array}            Matching virtual DOM nodes sorted by DOM order
 */
function select(selector, context) {
  let result = [];
  let candidate;
  if (axe._selectCache) {
    // if used outside of run, it will still work
    for (let j = 0, l = axe._selectCache.length; j < l; j++) {
      // First see whether the item exists in the cache
      const item = axe._selectCache[j];
      if (item.selector === selector) {
        return item.result;
      }
    }
  }
  const curried = (context => {
    return node => {
      return isNodeInContext(node, context);
    };
  })(context);
  const reducedIncludes = reduceIncludes(context.include);
  for (let i = 0; i < reducedIncludes.length; i++) {
    candidate = reducedIncludes[i];
    result = pushNode(
      result,
      querySelectorAllFilter(candidate, selector, curried)
    );
  }
  if (axe._selectCache) {
    axe._selectCache.push({
      selector: selector,
      result: result
    });
  }
  return result;
}

export default select;
