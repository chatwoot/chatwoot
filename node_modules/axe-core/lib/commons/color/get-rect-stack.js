import getElementStack from '../dom/get-element-stack';
import getTextElementStack from '../dom/get-text-element-stack';

/**
 * Get relevant stacks of block and inline elements, excluding line breaks
 * @method getRectStack
 * @memberof axe.commons.color
 * @param {Element} elm
 * @return {Array}
 */
function getRectStack(elm) {
  const boundingStack = getElementStack(elm);

  // Handle inline elements spanning multiple lines to be evaluated
  const filteredArr = getTextElementStack(elm);

  // If the element does not have multiple rects, like for display:block, return a single stack
  if (!filteredArr || filteredArr.length <= 1) {
    return [boundingStack];
  }

  if (filteredArr.some(stack => stack === undefined)) {
    // Can be happen when one or more of the rects sits outside the viewport
    return null;
  }

  // add bounding client rect stack for comparison later
  filteredArr.splice(0, 0, boundingStack);
  return filteredArr;
}

export default getRectStack;
