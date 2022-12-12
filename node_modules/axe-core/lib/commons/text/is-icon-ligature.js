import sanitize from './sanitize';
import hasUnicode from './has-unicode';
import cache from '../../core/base/cache';

/**
 * Determines if a given text node is an icon ligature
 *
 * @method isIconLigature
 * @memberof axe.commons.text
 * @instance
 * @param {VirtualNode} textVNode The virtual text node
 * @param {Number} occuranceThreshold Number of times the font is encountered before auto-assigning the font as a ligature or not
 * @param {Number} differenceThreshold Percent of differences in pixel data or pixel width needed to determine if a font is a ligature font
 * @return {Boolean}
 */
function isIconLigature(
  textVNode,
  differenceThreshold = 0.15,
  occuranceThreshold = 3
) {
  /**
   * Determine if the visible text is a ligature by comparing the
   * first letters image data to the entire strings image data.
   * If the two images are significantly different (typical set to 5%
   * statistical significance, but we'll be using a slightly higher value
   * of 15% to help keep the size of the canvas down) then we know the text
   * has been replaced by a ligature.
   *
   * Example:
   * If a text node was the string "File", looking at just the first
   * letter "F" would produce the following image:
   *
   * ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
   * │ │ │█│█│█│█│█│█│█│█│█│█│█│ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│█│█│█│█│█│█│█│█│█│ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│ │ │ │ │ │ │ │ │ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│ │ │ │ │ │ │ │ │ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│█│█│█│█│█│ │ │ │ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│█│█│█│█│█│ │ │ │ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│ │ │ │ │ │ │ │ │ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│ │ │ │ │ │ │ │ │ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │ │█│█│ │ │ │ │ │ │ │ │ │ │ │
   * └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
   *
   * But if the entire string "File" produced an image which had at least
   * a 15% difference in pixels, we would know that the string was replaced
   * by a ligature:
   *
   * ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
   * │ │█│█│█│█│█│█│█│█│█│█│ │ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│ │ │ │ │ │ │ │ │█│█│ │ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│ │█│█│█│█│█│█│ │█│ │█│ │ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│ │ │ │ │ │ │ │ │█│█│█│█│ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│ │█│█│█│█│█│█│ │ │ │ │█│ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│ │ │ │ │ │ │ │ │ │ │ │█│ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│ │█│█│█│█│█│█│█│█│█│ │█│ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│ │ │ │ │ │ │ │ │ │ │ │█│ │
   * ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
   * │ │█│█│█│█│█│█│█│█│█│█│█│█│█│ │
   * └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
   */
  const nodeValue = textVNode.actualNode.nodeValue.trim();

  // text with unicode or non-bmp letters cannot be ligature icons
  if (
    !sanitize(nodeValue) ||
    hasUnicode(nodeValue, { emoji: true, nonBmp: true })
  ) {
    return false;
  }

  if (!cache.get('canvasContext')) {
    cache.set(
      'canvasContext',
      document.createElement('canvas').getContext('2d')
    );
  }
  const canvasContext = cache.get('canvasContext');
  const canvas = canvasContext.canvas;

  // keep track of each font encountered and the number of times it shows up
  // as a ligature.
  if (!cache.get('fonts')) {
    cache.set('fonts', {});
  }
  const fonts = cache.get('fonts');

  const style = window.getComputedStyle(textVNode.parent.actualNode);
  const fontFamily = style.getPropertyValue('font-family');

  if (!fonts[fontFamily]) {
    fonts[fontFamily] = {
      occurances: 0,
      numLigatures: 0
    };
  }
  const font = fonts[fontFamily];

  // improve the performance by only comparing the image data of a font
  // a certain number of times
  if (font.occurances >= occuranceThreshold) {
    // if the font has always been a ligature assume it's a ligature font
    if (font.numLigatures / font.occurances === 1) {
      return true;
    }
    // inversely, if it's never been a ligature assume it's not a ligature font
    else if (font.numLigatures === 0) {
      return false;
    }

    // we could theoretically get into an odd middle ground scenario in which
    // the font family is being used as normal text sometimes and as icons
    // other times. in these cases we would need to always check the text
    // to know if it's an icon or not
  }
  font.occurances++;

  // 30px was chosen to account for common ligatures in normal fonts
  // such as fi, ff, ffi. If a ligature would add a single column of
  // pixels to a 30x30 grid, it would not meet the statistical significance
  // threshold of 15% (30x30 = 900; 30/900 = 3.333%). this also allows for
  // more than 1 column differences (60/900 = 6.666%) and things like
  // extending the top of the f in the fi ligature.
  let fontSize = 30;
  let fontStyle = `${fontSize}px ${fontFamily}`;

  // set the size of the canvas to the width of the first letter
  canvasContext.font = fontStyle;
  const firstChar = nodeValue.charAt(0);
  let width = canvasContext.measureText(firstChar).width;

  // ensure font meets the 30px width requirement (30px font-size doesn't
  // necessarily mean its 30px wide when drawn)
  if (width < 30) {
    const diff = 30 / width;
    width *= diff;
    fontSize *= diff;
    fontStyle = `${fontSize}px ${fontFamily}`;
  }
  canvas.width = width;
  canvas.height = fontSize;

  // changing the dimensions of a canvas resets all properties (include font)
  // and clears it
  canvasContext.font = fontStyle;
  canvasContext.textAlign = 'left';
  canvasContext.textBaseline = 'top';
  canvasContext.fillText(firstChar, 0, 0);
  const compareData = new Uint32Array(
    canvasContext.getImageData(0, 0, width, fontSize).data.buffer
  );

  // if the font doesn't even have character data for a single char then
  // it has to be an icon ligature (e.g. Material Icon)
  if (!compareData.some(pixel => pixel)) {
    font.numLigatures++;
    return true;
  }

  canvasContext.clearRect(0, 0, width, fontSize);
  canvasContext.fillText(nodeValue, 0, 0);
  const compareWith = new Uint32Array(
    canvasContext.getImageData(0, 0, width, fontSize).data.buffer
  );

  // calculate the number of differences between the first letter and the
  // entire string, ignoring color differences
  const differences = compareData.reduce((diff, pixel, i) => {
    if (pixel === 0 && compareWith[i] === 0) {
      return diff;
    }
    if (pixel !== 0 && compareWith[i] !== 0) {
      return diff;
    }
    return ++diff;
  }, 0);

  // calculate the difference between the width of each character and the
  // combined with of all characters
  const expectedWidth = nodeValue.split('').reduce((width, char) => {
    return width + canvasContext.measureText(char).width;
  }, 0);
  const actualWidth = canvasContext.measureText(nodeValue).width;

  const pixelDifference = differences / compareData.length;
  const sizeDifference = 1 - actualWidth / expectedWidth;

  if (
    pixelDifference >= differenceThreshold &&
    sizeDifference >= differenceThreshold
  ) {
    font.numLigatures++;
    return true;
  }

  return false;
}

export default isIconLigature;
