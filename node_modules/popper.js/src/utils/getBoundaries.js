import getScrollParent from './getScrollParent';
import getParentNode from './getParentNode';
import getReferenceNode from './getReferenceNode';
import findCommonOffsetParent from './findCommonOffsetParent';
import getOffsetRectRelativeToArbitraryNode from './getOffsetRectRelativeToArbitraryNode';
import getViewportOffsetRectRelativeToArtbitraryNode from './getViewportOffsetRectRelativeToArtbitraryNode';
import getWindowSizes from './getWindowSizes';
import isFixed from './isFixed';
import getFixedPositionOffsetParent from './getFixedPositionOffsetParent';

/**
 * Computed the boundaries limits and return them
 * @method
 * @memberof Popper.Utils
 * @param {HTMLElement} popper
 * @param {HTMLElement} reference
 * @param {number} padding
 * @param {HTMLElement} boundariesElement - Element used to define the boundaries
 * @param {Boolean} fixedPosition - Is in fixed position mode
 * @returns {Object} Coordinates of the boundaries
 */
export default function getBoundaries(
  popper,
  reference,
  padding,
  boundariesElement,
  fixedPosition = false
) {
  // NOTE: 1 DOM access here

  let boundaries = { top: 0, left: 0 };
  const offsetParent = fixedPosition ? getFixedPositionOffsetParent(popper) : findCommonOffsetParent(popper, getReferenceNode(reference));

  // Handle viewport case
  if (boundariesElement === 'viewport' ) {
    boundaries = getViewportOffsetRectRelativeToArtbitraryNode(offsetParent, fixedPosition);
  }

  else {
    // Handle other cases based on DOM element used as boundaries
    let boundariesNode;
    if (boundariesElement === 'scrollParent') {
      boundariesNode = getScrollParent(getParentNode(reference));
      if (boundariesNode.nodeName === 'BODY') {
        boundariesNode = popper.ownerDocument.documentElement;
      }
    } else if (boundariesElement === 'window') {
      boundariesNode = popper.ownerDocument.documentElement;
    } else {
      boundariesNode = boundariesElement;
    }

    const offsets = getOffsetRectRelativeToArbitraryNode(
      boundariesNode,
      offsetParent,
      fixedPosition
    );

    // In case of HTML, we need a different computation
    if (boundariesNode.nodeName === 'HTML' && !isFixed(offsetParent)) {
      const { height, width } = getWindowSizes(popper.ownerDocument);
      boundaries.top += offsets.top - offsets.marginTop;
      boundaries.bottom = height + offsets.top;
      boundaries.left += offsets.left - offsets.marginLeft;
      boundaries.right = width + offsets.left;
    } else {
      // for all the other DOM elements, this one is good
      boundaries = offsets;
    }
  }

  // Add paddings
  padding = padding || 0;
  const isPaddingNumber = typeof padding === 'number';
  boundaries.left += isPaddingNumber ? padding : padding.left || 0; 
  boundaries.top += isPaddingNumber ? padding : padding.top || 0; 
  boundaries.right -= isPaddingNumber ? padding : padding.right || 0; 
  boundaries.bottom -= isPaddingNumber ? padding : padding.bottom || 0; 

  return boundaries;
}
