import { matchesExpression, convertSelector } from './matches';

function createLocalVariables(vNodes, anyLevel, thisLevel, parentShadowId) {
  const retVal = {
    vNodes: vNodes.slice(),
    anyLevel: anyLevel,
    thisLevel: thisLevel,
    parentShadowId: parentShadowId
  };
  retVal.vNodes.reverse();
  return retVal;
}

function matchExpressions(domTree, expressions, filter) {
  const stack = [];
  const vNodes = Array.isArray(domTree) ? domTree : [domTree];
  let currentLevel = createLocalVariables(
    vNodes,
    expressions,
    [],
    domTree[0].shadowId
  );
  const result = [];

  while (currentLevel.vNodes.length) {
    const vNode = currentLevel.vNodes.pop();
    const childOnly = []; // we will add hierarchical '>' selectors here
    const childAny = [];
    const combined = currentLevel.anyLevel
      .slice()
      .concat(currentLevel.thisLevel);
    let added = false;
    // see if node matches
    for (let i = 0; i < combined.length; i++) {
      const exp = combined[i];
      if (
        (!exp[0].id || vNode.shadowId === currentLevel.parentShadowId) &&
        matchesExpression(vNode, exp[0])
      ) {
        if (exp.length === 1) {
          if (!added && (!filter || filter(vNode))) {
            result.push(vNode);
            added = true;
          }
        } else {
          const rest = exp.slice(1);
          if ([' ', '>'].includes(rest[0].combinator) === false) {
            throw new Error(
              'axe.utils.querySelectorAll does not support the combinator: ' +
                exp[1].combinator
            );
          }
          if (rest[0].combinator === '>') {
            // add the rest to the childOnly array
            childOnly.push(rest);
          } else {
            // add the rest to the childAny array
            childAny.push(rest);
          }
        }
      }
      if (
        (!exp[0].id || vNode.shadowId === currentLevel.parentShadowId) &&
        currentLevel.anyLevel.includes(exp)
      ) {
        childAny.push(exp);
      }
    }

    if (vNode.children && vNode.children.length) {
      stack.push(currentLevel);
      currentLevel = createLocalVariables(
        vNode.children,
        childAny,
        childOnly,
        vNode.shadowId
      );
    }
    // check for "return"
    while (!currentLevel.vNodes.length && stack.length) {
      currentLevel = stack.pop();
    }
  }
  return result;
}

/**
 * querySelectorAllFilter implements querySelectorAll on the virtual DOM with
 * ability to filter the returned nodes using an optional supplied filter function
 *
 * @method querySelectorAllFilter
 * @memberof axe.utils
 * @param {NodeList} domTree flattened tree collection to search
 * @param {String} selector String containing one or more CSS selectors separated by commas
 * @param {Function} filter function (optional)
 * @return {Array} Elements matched by any of the selectors and filtered by the filter function
 */
function querySelectorAllFilter(domTree, selector, filter) {
  domTree = Array.isArray(domTree) ? domTree : [domTree];
  const expressions = convertSelector(selector);
  return matchExpressions(domTree, expressions, filter);
}

export default querySelectorAllFilter;
