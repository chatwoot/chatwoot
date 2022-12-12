import Color from './color';

/**
 * Creates a string array of fonts for given CSSStyleDeclaration object
 * @private
 * @param {Object} style CSSStyleDeclaration object
 * @return {Array}
 */
function _getFonts(style) {
  return style
    .getPropertyValue('font-family')
    .split(/[,;]/g)
    .map(font => {
      return font.trim().toLowerCase();
    });
}

/**
 * Determine if the text content of two nodes is styled in a way that they can be distinguished without relying on color
 * @method elementIsDistinct
 * @memberof axe.commons.color
 * @instance
 * @param  {HTMLElement} node The element to check
 * @param  {HTMLElement} ancestorNode The ancestor node element to check
 * @return {Boolean}
 */
function elementIsDistinct(node, ancestorNode) {
  var nodeStyle = window.getComputedStyle(node);

  // Check if the link has a background
  if (nodeStyle.getPropertyValue('background-image') !== 'none') {
    return true;
  }

  // Check if the link has a border or outline
  var hasBorder = ['border-bottom', 'border-top', 'outline'].reduce(
    (result, edge) => {
      var borderClr = new Color();
      borderClr.parseString(nodeStyle.getPropertyValue(edge + '-color'));

      // Check if a border/outline was specified
      return (
        result ||
        // or if the current border edge / outline
        (nodeStyle.getPropertyValue(edge + '-style') !== 'none' &&
          parseFloat(nodeStyle.getPropertyValue(edge + '-width')) > 0 &&
          borderClr.alpha !== 0)
      );
    },
    false
  );

  if (hasBorder) {
    return true;
  }

  var parentStyle = window.getComputedStyle(ancestorNode);
  // Compare fonts
  if (_getFonts(nodeStyle)[0] !== _getFonts(parentStyle)[0]) {
    return true;
  }

  var hasStyle = [
    'text-decoration-line',
    'text-decoration-style',
    'font-weight',
    'font-style',
    'font-size'
  ].reduce((result, cssProp) => {
    return (
      result ||
      nodeStyle.getPropertyValue(cssProp) !==
        parentStyle.getPropertyValue(cssProp)
    );
  }, false);

  var tDec = nodeStyle.getPropertyValue('text-decoration');
  if (tDec.split(' ').length < 3) {
    // old style CSS text decoration
    hasStyle =
      hasStyle || tDec !== parentStyle.getPropertyValue('text-decoration');
  }

  return hasStyle;
}

export default elementIsDistinct;
