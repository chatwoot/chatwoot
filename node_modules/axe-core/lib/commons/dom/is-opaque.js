import elementHasImage from '../color/element-has-image';
import getOwnBackgroundColor from '../color/get-own-background-color';

/**
 * Determines whether an element has a fully opaque background, whether solid color or an image
 * @param {Element} node
 * @return {Boolean} false if the background is transparent, true otherwise
 */
function isOpaque(node) {
  const style = window.getComputedStyle(node);
  return (
    elementHasImage(node, style) || getOwnBackgroundColor(style).alpha === 1
  );
}

export default isOpaque;
