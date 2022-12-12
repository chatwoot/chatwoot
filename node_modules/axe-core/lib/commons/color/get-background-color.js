import incompleteData from './incomplete-data';
import getBackgroundStack from './get-background-stack';
import getOwnBackgroundColor from './get-own-background-color';
import elementHasImage from './element-has-image';
import Color from './color';
import flattenColors from './flatten-colors';
import getTextShadowColors from './get-text-shadow-colors';
import visuallyContains from '../dom/visually-contains';

/**
 * Determine if element is partially overlapped, triggering a Can't Tell result
 * @private
 * @param {Element} elm
 * @param {Element} bgElm
 * @param {Object} bgColor
 * @return {Boolean}
 */
function elmPartiallyObscured(elm, bgElm, bgColor) {
  var obscured =
    elm !== bgElm && !visuallyContains(elm, bgElm) && bgColor.alpha !== 0;
  if (obscured) {
    incompleteData.set('bgColor', 'elmPartiallyObscured');
  }
  return obscured;
}

/**
 * Returns background color for element
 * Uses getBackgroundStack() to get all elements rendered underneath the current element,
 * to help determine the composite background color.
 *
 * @method getBackgroundColor
 * @memberof axe.commons.color
 * @param	{Element} elm Element to determine background color
 * @param	{Array}   [bgElms=[]] elements to inspect
 * @param	{Number}  shadowOutlineEmMax Thickness of `text-shadow` at which it becomes a background color
 * @returns {Color}
 */
function getBackgroundColor(elm, bgElms = [], shadowOutlineEmMax = 0.1) {
  let bgColors = getTextShadowColors(elm, { minRatio: shadowOutlineEmMax });
  const elmStack = getBackgroundStack(elm);

  // Search the stack until we have an alpha === 1 background
  (elmStack || []).some(bgElm => {
    const bgElmStyle = window.getComputedStyle(bgElm);

    // Get the background color
    const bgColor = getOwnBackgroundColor(bgElmStyle);

    if (
      // abort if a node is partially obscured and obscuring element has a background
      elmPartiallyObscured(elm, bgElm, bgColor) ||
      // OR if the background elm is a graphic
      elementHasImage(bgElm, bgElmStyle)
    ) {
      bgColors = null;
      bgElms.push(bgElm);

      return true;
    }

    if (bgColor.alpha !== 0) {
      // store elements contributing to the br color.
      bgElms.push(bgElm);
      bgColors.push(bgColor);

      // Exit if the background is opaque
      return bgColor.alpha === 1;
    } else {
      return false;
    }
  });

  if (bgColors === null || elmStack === null) {
    return null;
  }

  // Mix the colors together, on top of a default white
  bgColors.push(new Color(255, 255, 255, 1));
  var colors = bgColors.reduce(flattenColors);
  return colors;
}

export default getBackgroundColor;
