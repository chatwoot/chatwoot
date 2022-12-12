import { getComposedParent } from '../../commons/dom';
import {
  elementIsDistinct,
  getForegroundColor,
  getBackgroundColor,
  incompleteData
} from '../../commons/color';

function getContrast(color1, color2) {
  var c1lum = color1.getRelativeLuminance();
  var c2lum = color2.getRelativeLuminance();
  return (Math.max(c1lum, c2lum) + 0.05) / (Math.min(c1lum, c2lum) + 0.05);
}

const blockLike = [
  'block',
  'list-item',
  'table',
  'flex',
  'grid',
  'inline-block'
];
function isBlock(elm) {
  var display = window.getComputedStyle(elm).getPropertyValue('display');
  return blockLike.indexOf(display) !== -1 || display.substr(0, 6) === 'table-';
}

function linkInTextBlockEvaluate(node) {
  if (isBlock(node)) {
    return false;
  }

  var parentBlock = getComposedParent(node);
  while (parentBlock.nodeType === 1 && !isBlock(parentBlock)) {
    parentBlock = getComposedParent(parentBlock);
  }

  this.relatedNodes([parentBlock]);

  // TODO: Check the :visited state of the link
  if (elementIsDistinct(node, parentBlock)) {
    return true;
  } else {
    // Check if contrast of foreground is sufficient
    var nodeColor, parentColor;
    nodeColor = getForegroundColor(node);
    parentColor = getForegroundColor(parentBlock);

    if (!nodeColor || !parentColor) {
      return undefined;
    }

    var contrast = getContrast(nodeColor, parentColor);
    if (contrast === 1) {
      return true;
    } else if (contrast >= 3.0) {
      incompleteData.set('fgColor', 'bgContrast');
      this.data({
        messageKey: incompleteData.get('fgColor')
      });
      incompleteData.clear();
      // User needs to check whether there is a hover and a focus style
      return undefined;
    }

    // Check if contrast of background is sufficient
    nodeColor = getBackgroundColor(node);
    parentColor = getBackgroundColor(parentBlock);

    if (
      !nodeColor ||
      !parentColor ||
      getContrast(nodeColor, parentColor) >= 3.0
    ) {
      let reason;
      if (!nodeColor || !parentColor) {
        reason = incompleteData.get('bgColor');
      } else {
        reason = 'bgContrast';
      }
      incompleteData.set('fgColor', reason);
      this.data({
        messageKey: incompleteData.get('fgColor')
      });
      incompleteData.clear();
      return undefined;
    }
  }

  // TODO: We should check the focus / hover style too
  return false;
}

export default linkInTextBlockEvaluate;
