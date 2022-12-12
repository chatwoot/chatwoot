import {
  accessibleText,
  isHumanInterpretable,
  visibleTextNodes,
  isIconLigature,
  sanitize,
  removeUnicode
} from '../../commons/text';

/**
 * Check if a given text exists in another
 *
 * @param {String} compare given text to check
 * @param {String} compareWith text against which to be compared
 * @returns {Boolean}
 */
function isStringContained(compare, compareWith) {
  const curatedCompareWith = curateString(compareWith);
  const curatedCompare = curateString(compare);
  if (!curatedCompareWith || !curatedCompare) {
    return false;
  }
  return curatedCompareWith.includes(curatedCompare);
}

/**
 * Curate given text, by removing emoji's, punctuations, unicode and trim whitespace.
 *
 * @param {String} str given text to curate
 * @returns {String}
 */
function curateString(str) {
  const noUnicodeStr = removeUnicode(str, {
    emoji: true,
    nonBmp: true,
    punctuations: true
  });
  return sanitize(noUnicodeStr);
}

function labelContentNameMismatchEvaluate(node, options, virtualNode) {
  const { pixelThreshold, occuranceThreshold } = options || {};

  const accText = accessibleText(node).toLowerCase();
  if (isHumanInterpretable(accText) < 1) {
    return undefined;
  }

  const textVNodes = visibleTextNodes(virtualNode);
  const nonLigatureText = textVNodes
    .filter(
      textVNode =>
        !isIconLigature(textVNode, pixelThreshold, occuranceThreshold)
    )
    .map(textVNode => textVNode.actualNode.nodeValue)
    .join('');
  const visibleText = sanitize(nonLigatureText).toLowerCase();
  if (!visibleText) {
    return true;
  }
  if (isHumanInterpretable(visibleText) < 1) {
    if (isStringContained(visibleText, accText)) {
      return true;
    }
    return undefined;
  }

  return isStringContained(visibleText, accText);
}

export default labelContentNameMismatchEvaluate;
