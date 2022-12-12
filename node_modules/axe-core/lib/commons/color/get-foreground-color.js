import Color from './color';
import getBackgroundColor from './get-background-color';
import incompleteData from './incomplete-data';
import flattenColors from './flatten-colors';
import { getNodeFromTree } from '../../core/utils';

function getOpacity(node) {
  if (!node) {
    return 1;
  }

  const vNode = getNodeFromTree(node);

  if (vNode && vNode._opacity !== undefined && vNode._opacity !== null) {
    return vNode._opacity;
  }

  const nodeStyle = window.getComputedStyle(node);
  const opacity = nodeStyle.getPropertyValue('opacity');
  const finalOpacity = opacity * getOpacity(node.parentElement);

  // cache the results of the getOpacity check on the parent tree
  // so we don't have to look at the parent tree again for all its
  // descendants
  if (vNode) {
    vNode._opacity = finalOpacity;
  }

  return finalOpacity;
}

/**
 * Returns the flattened foreground color of an element, or null if it can't be determined because
 * of transparency
 * @method getForegroundColor
 * @memberof axe.commons.color
 * @instance
 * @param {Element} node
 * @param {Boolean} noScroll (default false)
 * @param {Color} bgColor
 * @return {Color|null}
 *
 * @deprecated noScroll parameter
 */
function getForegroundColor(node, _, bgColor) {
  const nodeStyle = window.getComputedStyle(node);

  const fgColor = new Color();
  fgColor.parseString(nodeStyle.getPropertyValue('color'));
  const opacity = getOpacity(node);
  fgColor.alpha = fgColor.alpha * opacity;
  if (fgColor.alpha === 1) {
    return fgColor;
  }

  if (!bgColor) {
    bgColor = getBackgroundColor(node, []);
  }

  if (bgColor === null) {
    const reason = incompleteData.get('bgColor');
    incompleteData.set('fgColor', reason);
    return null;
  }

  return flattenColors(fgColor, bgColor);
}

export default getForegroundColor;
