import { isVisible } from '../../commons/dom';
import {
  visibleVirtual,
  hasUnicode,
  sanitize,
  removeUnicode
} from '../../commons/text';
import {
  getBackgroundColor,
  getForegroundColor,
  incompleteData,
  getContrast,
  getOwnBackgroundColor,
  getTextShadowColors,
  flattenColors
} from '../../commons/color';
import { memoize } from '../../core/utils';

const hasPsuedoElement = memoize(function hasPsuedoElement(node, pseudo) {
  const style = window.getComputedStyle(node, pseudo);
  const backgroundColor = getOwnBackgroundColor(style);

  // element has a non-transparent color or image and has
  // non-zero width
  return (
    style.getPropertyValue('content') !== 'none' &&
    style.getPropertyValue('position') === 'absolute' &&
    parseInt(style.getPropertyValue('width')) !== 0 &&
    parseInt(style.getPropertyValue('height')) !== 0 &&
    (backgroundColor.alpha !== 0 ||
      style.getPropertyValue('background-image') !== 'none')
  );
});

function colorContrastEvaluate(node, options, virtualNode) {
  if (!isVisible(node, false)) {
    return true;
  }

  const {
    ignoreUnicode,
    ignoreLength,
    boldValue,
    boldTextPt,
    largeTextPt,
    contrastRatio,
    shadowOutlineEmMax
  } = options;

  const visibleText = visibleVirtual(virtualNode, false, true);
  const textContainsOnlyUnicode =
    hasUnicode(visibleText, {
      nonBmp: true
    }) &&
    sanitize(
      removeUnicode(visibleText, {
        nonBmp: true
      })
    ) === '';

  if (textContainsOnlyUnicode && ignoreUnicode) {
    this.data({ messageKey: 'nonBmp' });
    return undefined;
  }

  const bgNodes = [];
  const bgColor = getBackgroundColor(node, bgNodes, shadowOutlineEmMax);
  const fgColor = getForegroundColor(node, false, bgColor);
  // Thin shadows only. Thicker shadows are included in the background instead
  const shadowColors = getTextShadowColors(node, {
    maxRatio: shadowOutlineEmMax
  });

  const nodeStyle = window.getComputedStyle(node);
  const fontSize = parseFloat(nodeStyle.getPropertyValue('font-size'));
  const fontWeight = nodeStyle.getPropertyValue('font-weight');
  const bold = parseFloat(fontWeight) >= boldValue || fontWeight === 'bold';

  let contrast = null;
  if (shadowColors.length === 0) {
    contrast = getContrast(bgColor, fgColor);
  } else if (fgColor && bgColor) {
    // Thin shadows can pass either by contrasting with the text color
    // or when contrasting with the background.
    const shadowColor = [...shadowColors, bgColor].reduce(flattenColors);
    const bgContrast = getContrast(bgColor, shadowColor);
    const fgContrast = getContrast(shadowColor, fgColor);
    contrast = Math.max(bgContrast, fgContrast);
  }

  const ptSize = Math.ceil(fontSize * 72) / 96;
  const isSmallFont =
    (bold && ptSize < boldTextPt) || (!bold && ptSize < largeTextPt);

  const { expected, minThreshold, maxThreshold } = isSmallFont
    ? contrastRatio.normal
    : contrastRatio.large;
  const isValid = contrast > expected;

  // if element or a parent has pseudo content then we need to mark
  // as needs review
  let parentNode = node.parentElement;
  while (parentNode) {
    if (
      hasPsuedoElement(parentNode, ':before') ||
      hasPsuedoElement(parentNode, ':after')
    ) {
      this.data({
        messageKey: 'pseudoContent'
      });
      this.relatedNodes(parentNode);
      return undefined;
    }

    parentNode = parentNode.parentElement;
  }

  // ratio is outside range
  if (
    (typeof minThreshold === 'number' && contrast < minThreshold) ||
    (typeof maxThreshold === 'number' && contrast > maxThreshold)
  ) {
    return true;
  }

  // truncate ratio to three digits while rounding down
  // 4.499 = 4.49, 4.019 = 4.01
  const truncatedResult = Math.floor(contrast * 100) / 100;

  // if fgColor or bgColor are missing, get more information.
  let missing;
  if (bgColor === null) {
    missing = incompleteData.get('bgColor');
  }

  const equalRatio = truncatedResult === 1;
  const shortTextContent = visibleText.length === 1;
  if (equalRatio) {
    missing = incompleteData.set('bgColor', 'equalRatio');
  } else if (shortTextContent && !ignoreLength) {
    // Check that the text content is a single character long
    missing = 'shortTextContent';
  }

  // need both independently in case both are missing
  const data = {
    fgColor: fgColor ? fgColor.toHexString() : undefined,
    bgColor: bgColor ? bgColor.toHexString() : undefined,
    contrastRatio: truncatedResult,
    fontSize: `${((fontSize * 72) / 96).toFixed(1)}pt (${fontSize}px)`,
    fontWeight: bold ? 'bold' : 'normal',
    messageKey: missing,
    expectedContrastRatio: expected + ':1'
  };

  this.data(data);

  // We don't know, so we'll put it into Can't Tell
  if (
    fgColor === null ||
    bgColor === null ||
    equalRatio ||
    (shortTextContent && !ignoreLength && !isValid)
  ) {
    missing = null;
    incompleteData.clear();
    this.relatedNodes(bgNodes);
    return undefined;
  }

  if (!isValid) {
    this.relatedNodes(bgNodes);
  }

  return isValid;
}

export default colorContrastEvaluate;
