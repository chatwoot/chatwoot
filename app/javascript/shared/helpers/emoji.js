/**
 * Detects support for emoji character sets.
 *
 * Based on the Modernizr emoji detection.
 * https://github.com/Modernizr/Modernizr/blob/347ddb078116cee91b25b6e897e211b023f9dcb4/feature-detects/emoji.js
 *
 * @return {Boolean} true or false
 * @example
 *
 * hasEmojiSupport()
 * // => true|false
 */
export const hasEmojiSupport = () => {
  const pixelRatio = window.devicePixelRatio || 1;
  const offset = 12 * pixelRatio;
  const node = document.createElement('canvas');

  // canvastext support
  if (
    !node.getContext ||
    !node.getContext('2d') ||
    typeof node.getContext('2d').fillText !== 'function'
  ) {
    return false;
  }

  const ctx = node.getContext('2d');

  ctx.fillStyle = '#f00';
  ctx.textBaseline = 'top';
  ctx.font = '32px Arial';
  ctx.fillText('\ud83d\udc28', 0, 0); // U+1F428 KOALA
  return ctx.getImageData(offset, offset, 1, 1).data[0] !== 0;
};

export const removeEmoji = text => {
  if (text) {
    return text
      .replace(
        /([\u2700-\u27BF]|[\uE000-\uF8FF]|\uD83C[\uDC00-\uDFFF]|\uD83D[\uDC00-\uDFFF]|[\u2011-\u26FF]|\uD83E[\uDD10-\uDDFF])/g,
        ''
      )
      .replace(/\s+/g, ' ')
      .trim();
  }
  return '';
};
