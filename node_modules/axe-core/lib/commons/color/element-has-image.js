import incompleteData from './incomplete-data';

/**
 * Reports if an element has a background image or gradient
 *
 * @method elementHasImage
 * @memberof axe.commons.color
 * @private
 * @param {Element} elm
 * @param {Object|null} style
 * @return {Boolean}
 */
function elementHasImage(elm, style) {
  const graphicNodes = ['IMG', 'CANVAS', 'OBJECT', 'IFRAME', 'VIDEO', 'SVG'];
  const nodeName = elm.nodeName.toUpperCase();

  if (graphicNodes.includes(nodeName)) {
    incompleteData.set('bgColor', 'imgNode');
    return true;
  }

  style = style || window.getComputedStyle(elm);

  const bgImageStyle = style.getPropertyValue('background-image');
  const hasBgImage = bgImageStyle !== 'none';

  if (hasBgImage) {
    const hasGradient = /gradient/.test(bgImageStyle);
    incompleteData.set('bgColor', hasGradient ? 'bgGradient' : 'bgImage');
  }

  return hasBgImage;
}

export default elementHasImage;
