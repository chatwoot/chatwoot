import flattenColors from './flatten-colors';

/**
 * Get the contrast of two colors
 * @method getContrast
 * @memberof axe.commons.color.Color
 * @instance
 * @param  {Color}  bgcolor  Background color
 * @param  {Color}  fgcolor  Foreground color
 * @return {number} The contrast ratio
 */
function getContrast(bgColor, fgColor) {
  if (!fgColor || !bgColor) {
    return null;
  }

  if (fgColor.alpha < 1) {
    fgColor = flattenColors(fgColor, bgColor);
  }

  var bL = bgColor.getRelativeLuminance();
  var fL = fgColor.getRelativeLuminance();

  return (Math.max(fL, bL) + 0.05) / (Math.min(fL, bL) + 0.05);
}

export default getContrast;
