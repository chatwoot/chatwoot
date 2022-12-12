import getElementStack from './get-element-stack';
import { createGrid, getRectStack } from './get-rect-stack';
import sanitize from '../text/sanitize';
import cache from '../../core/base/cache';
import { getNodeFromTree } from '../../core/utils';

/**
 * Return all elements that are at the center of each text client rect of the passed in node.
 * @method getTextElementStack
 * @memberof axe.commons.dom
 * @param {Node} node
 * @return {Array<Node[]>}
 */
function getTextElementStack(node) {
  if (!cache.get('gridCreated')) {
    createGrid();
    cache.set('gridCreated', true);
  }

  const vNode = getNodeFromTree(node);
  const grid = vNode._grid;

  if (!grid) {
    return [];
  }

  // for code blocks that use syntax highlighting, you can get a ton of client
  // rects (See https://github.com/dequelabs/axe-core/issues/1985). they use
  // a mixture of text nodes and other nodes (which will contain their own text
  // nodes), but all we care about is checking the direct text nodes as the
  // other nodes will have their own client rects checked. doing this speeds up
  // color contrast significantly for large syntax highlighted code blocks
  const nodeRect = vNode.boundingClientRect;
  const clientRects = [];
  Array.from(node.childNodes).forEach(elm => {
    if (elm.nodeType === 3 && sanitize(elm.textContent) !== '') {
      const range = document.createRange();
      range.selectNodeContents(elm);
      const rects = range.getClientRects();

      // if any text rect is larger than the bounds of the parent,
      // or goes outside of the bounds of the parent, we need to use
      // the parent rect so we stay within the bounds of the element.
      //
      // since we use the midpoint of the element when determining
      // the rect stack we will also use the midpoint of the text rect
      // to determine out of bounds.
      //
      // @see https://github.com/dequelabs/axe-core/issues/2178
      // @see https://github.com/dequelabs/axe-core/issues/2483
      // @see https://github.com/dequelabs/axe-core/issues/2681
      const outsideRectBounds = Array.from(rects).some(rect => {
        const horizontalMidpoint = rect.left + rect.width / 2;
        const verticalMidpoint = rect.top + rect.height / 2;

        return (
          horizontalMidpoint < nodeRect.left ||
          horizontalMidpoint > nodeRect.right ||
          verticalMidpoint < nodeRect.top ||
          verticalMidpoint > nodeRect.bottom
        );
      });
      if (outsideRectBounds) {
        return;
      }

      for (let i = 0; i < rects.length; i++) {
        const rect = rects[i];

        // filter out 0 width and height rects (newline characters)
        // ie11 has newline characters return 0.00998, so we'll say if the
        // line is < 1 it shouldn't be counted
        if (rect.width >= 1 && rect.height >= 1) {
          clientRects.push(rect);
        }
      }
    }
  });

  if (!clientRects.length) {
    return [getElementStack(node)];
  }

  return clientRects.map(rect => {
    return getRectStack(grid, rect);
  });
}

export default getTextElementStack;
