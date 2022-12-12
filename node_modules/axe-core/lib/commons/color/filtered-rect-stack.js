import getRectStack from './get-rect-stack';
import incompleteData from './incomplete-data';

/**
 * Get filtered stack of block and inline elements, excluding line breaks
 * @method filteredRectStack
 * @memberof axe.commons.color
 * @param {Element} elm
 * @return {Array}
 */
function filteredRectStack(elm) {
  const rectStack = getRectStack(elm);

  if (rectStack && rectStack.length === 1) {
    return rectStack[0];
  }

  if (rectStack && rectStack.length > 1) {
    const boundingStack = rectStack.shift();
    let isSame;

    // iterating over arrays of DOMRects
    rectStack.forEach((rectList, index) => {
      if (index === 0) {
        return;
      }
      // if the stacks are the same, use the first one. otherwise, return null.
      const rectA = rectStack[index - 1],
        rectB = rectStack[index];

      // if elements in clientRects are the same
      // or the boundingClientRect contains the differing element, pass it
      isSame =
        rectA.every(
          (element, elementIndex) => element === rectB[elementIndex]
        ) || boundingStack.includes(elm);
    });
    if (!isSame) {
      incompleteData.set('bgColor', 'elmPartiallyObscuring');
      return null;
    }
    // pass the first stack if it wasn't partially covered
    return rectStack[0];
  }

  // rect outside of viewport
  incompleteData.set('bgColor', 'outsideViewport');
  return null;
}

export default filteredRectStack;
