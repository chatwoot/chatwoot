import getContrast from './get-contrast';

/**
 * Check whether certain text properties meet WCAG contrast rules
 * @method hasValidContrastRatio
 * @memberof axe.commons.color.Color
 * @instance
 * @param  {Color}  bgcolor  Background color
 * @param  {Color}  fgcolor  Foreground color
 * @param  {number}  fontSize  Font size of text, in pixels
 * @param  {boolean}  isBold  Whether the text is bold
 * @return {{isValid: boolean, contrastRatio: number, expectedContrastRatio: number}}
 *
 * @deprecated
 */
function hasValidContrastRatio(bg, fg, fontSize, isBold) {
  var contrast = getContrast(bg, fg);
  var isSmallFont =
    (isBold && Math.ceil(fontSize * 72) / 96 < 14) ||
    (!isBold && Math.ceil(fontSize * 72) / 96 < 18);
  var expectedContrastRatio = isSmallFont ? 4.5 : 3;

  return {
    isValid: contrast > expectedContrastRatio,
    contrastRatio: contrast,
    expectedContrastRatio: expectedContrastRatio
  };
}

export default hasValidContrastRatio;
