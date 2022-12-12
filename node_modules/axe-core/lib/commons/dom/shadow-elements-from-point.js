import getRootNode from './get-root-node';
import visuallyContains from './visually-contains';
import { isShadowRoot } from '../../core/utils';

/**
 * Get elements from point across shadow dom boundaries
 * @method shadowElementsFromPoint
 * @memberof axe.commons.dom
 * @instance
 * @param {Number} nodeX X coordinates of point
 * @param {Number} nodeY Y coordinates of point
 * @param {Object} [root] Shadow root or document root
 * @return {Array}
 */
function shadowElementsFromPoint(nodeX, nodeY, root = document, i = 0) {
  if (i > 999) {
    throw new Error('Infinite loop detected');
  }
  return (
    // IE can return null when there are no elements
    Array.from(root.elementsFromPoint(nodeX, nodeY) || [])
      // As of Chrome 66, elementFromPoint will return elements from parent trees.
      // We only want to touch each tree once, so we're filtering out nodes on other trees.
      .filter(nodes => getRootNode(nodes) === root)
      .reduce((stack, elm) => {
        if (isShadowRoot(elm)) {
          const shadowStack = shadowElementsFromPoint(
            nodeX,
            nodeY,
            elm.shadowRoot,
            i + 1
          );
          stack = stack.concat(shadowStack);
          // filter host nodes which get included regardless of overlap
          // TODO: refactor multiline overlap checking inside shadow dom
          if (stack.length && visuallyContains(stack[0], elm)) {
            stack.push(elm);
          }
        } else {
          stack.push(elm);
        }
        return stack;
      }, [])
  );
}

export default shadowElementsFromPoint;
