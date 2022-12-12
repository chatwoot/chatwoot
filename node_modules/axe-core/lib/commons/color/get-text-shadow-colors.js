import Color from './color';
import assert from '../../core/utils/assert';

/**
 * Get text-shadow colors that can impact the color contrast of the text
 * @param {Element} node  DOM Element
 * @param {Object} options (optional)
 * @property {Bool} minRatio Ignore shadows smaller than this, ratio shadow size divided by font size
 * @property {Bool} maxRatio Ignore shadows equal or larter than this, ratio shadow size divided by font size
 */
function getTextShadowColors(node, { minRatio, maxRatio } = {}) {
  const style = window.getComputedStyle(node);
  const textShadow = style.getPropertyValue('text-shadow');
  if (textShadow === 'none') {
    return [];
  }

  const fontSizeStr = style.getPropertyValue('font-size');
  const fontSize = parseInt(fontSizeStr);
  assert(
    isNaN(fontSize) === false,
    `Unable to determine font-size value ${fontSizeStr}`
  );

  const shadowColors = [];
  const shadows = parseTextShadows(textShadow);
  shadows.forEach(({ colorStr, pixels }) => {
    // Defautls only necessary for IE
    colorStr = colorStr || style.getPropertyValue('color');
    const [offsetY, offsetX, blurRadius = 0] = pixels;
    if (
      (!minRatio || blurRadius >= fontSize * minRatio) &&
      (!maxRatio || blurRadius < fontSize * maxRatio)
    ) {
      const color = textShadowColor({
        colorStr,
        offsetY,
        offsetX,
        blurRadius,
        fontSize
      });
      shadowColors.push(color);
    }
  });
  return shadowColors;
}

/**
 * Parse text-shadow property value. Required for IE, which can return the color
 * either at the start or the end, and either in rgb(a) or as a named color
 */
function parseTextShadows(textShadow) {
  let current = { pixels: [] };
  let str = textShadow.trim();
  const shadows = [current];
  if (!str) {
    return [];
  }

  while (str) {
    const colorMatch =
      str.match(/^rgba?\([0-9,.\s]+\)/i) ||
      str.match(/^[a-z]+/i) ||
      str.match(/^#[0-9a-f]+/i);
    const pixelMatch = str.match(/^([0-9.-]+)px/i) || str.match(/^(0)/);

    if (colorMatch) {
      assert(
        !current.colorStr,
        `Multiple colors identified in text-shadow: ${textShadow}`
      );
      str = str.replace(colorMatch[0], '').trim();
      current.colorStr = colorMatch[0];
    } else if (pixelMatch) {
      assert(
        current.pixels.length < 3,
        `Too many pixel units in text-shadow: ${textShadow}`
      );
      str = str.replace(pixelMatch[0], '').trim();
      const pixelUnit = parseFloat(
        (pixelMatch[1][0] === '.' ? '0' : '') + pixelMatch[1]
      );
      current.pixels.push(pixelUnit);
    } else if (str[0] === ',') {
      // multiple text-shadows in a single string (e.g. `text-shadow: 1px 1px 1px #000, 3px 3px 5px blue;`
      assert(
        current.pixels.length >= 2,
        `Missing pixel value in text-shadow: ${textShadow}`
      );
      current = { pixels: [] };
      shadows.push(current);
      str = str.substr(1).trim();
    } else {
      throw new Error(`Unable to process text-shadows: ${textShadow}`);
    }
  }

  return shadows;
}

function textShadowColor({ colorStr, offsetX, offsetY, blurRadius, fontSize }) {
  if (offsetX > blurRadius || offsetY > blurRadius) {
    // Shadow is too far removed from the text to impact contrast
    return new Color(0, 0, 0, 0);
  }

  const shadowColor = new Color();
  shadowColor.parseString(colorStr);
  shadowColor.alpha *= blurRadiusToAlpha(blurRadius, fontSize);

  return shadowColor;
}

function blurRadiusToAlpha(blurRadius, fontSize) {
  // This formula is an estimate based on various tests.
  // Different people test this differently, so opinions may vary.
  const relativeBlur = blurRadius / fontSize;
  return 0.185 / (relativeBlur + 0.4);
}

export default getTextShadowColors;
