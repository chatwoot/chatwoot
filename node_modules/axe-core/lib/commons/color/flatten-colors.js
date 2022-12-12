import Color from './color';

/**
 * Combine the two given color according to alpha blending.
 * @method flattenColors
 * @memberof axe.commons.color.Color
 * @instance
 * @param {Color} fgColor Foreground color
 * @param {Color} bgColor Background color
 * @return {Color} Blended color
 */
function flattenColors(fgColor, bgColor) {
  var alpha = fgColor.alpha;
  var r = (1 - alpha) * bgColor.red + alpha * fgColor.red;
  var g = (1 - alpha) * bgColor.green + alpha * fgColor.green;
  var b = (1 - alpha) * bgColor.blue + alpha * fgColor.blue;
  var a = fgColor.alpha + bgColor.alpha * (1 - fgColor.alpha);

  return new Color(r, g, b, a);
}

export default flattenColors;
