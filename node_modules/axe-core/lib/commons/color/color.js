import standards from '../../standards';

/**
 * Convert a CSS color value into a number
 */
function convertColorVal(colorFunc, value, index) {
  if (/%$/.test(value)) {
    //<percentage>
    if (index === 3) {
      // alpha
      return parseFloat(value) / 100;
    }
    return (parseFloat(value) * 255) / 100;
  }
  if (colorFunc[index] === 'h') {
    // hue
    if (/turn$/.test(value)) {
      return parseFloat(value) * 360;
    }
    if (/rad$/.test(value)) {
      return parseFloat(value) * 57.3;
    }
  }
  return parseFloat(value);
}

/**
 * Convert HSL to RGB
 */
function hslToRgb([hue, saturation, lightness, alpha]) {
  // Must be fractions of 1
  saturation /= 255;
  lightness /= 255;

  const high = (1 - Math.abs(2 * lightness - 1)) * saturation;
  const low = high * (1 - Math.abs(((hue / 60) % 2) - 1));
  const base = lightness - high / 2;

  let colors;
  if (hue < 60) {
    // red - yellow
    colors = [high, low, 0];
  } else if (hue < 120) {
    // yellow - green
    colors = [low, high, 0];
  } else if (hue < 180) {
    // green - cyan
    colors = [0, high, low];
  } else if (hue < 240) {
    // cyan - blue
    colors = [0, low, high];
  } else if (hue < 300) {
    // blue - purple
    colors = [low, 0, high];
  } else {
    // purple - red
    colors = [high, 0, low];
  }

  return colors
    .map(color => {
      return Math.round((color + base) * 255);
    })
    .concat(alpha);
}

/**
 * @class Color
 * @memberof axe.commons.color
 * @param {number} red
 * @param {number} green
 * @param {number} blue
 * @param {number} alpha
 */
function Color(red, green, blue, alpha) {
  /** @type {number} */
  this.red = red;

  /** @type {number} */
  this.green = green;

  /** @type {number} */
  this.blue = blue;

  /** @type {number} */
  this.alpha = alpha;

  /**
   * Provide the hex string value for the color
   * @method toHexString
   * @memberof axe.commons.color.Color
   * @instance
   * @return {string}
   */
  this.toHexString = function toHexString() {
    var redString = Math.round(this.red).toString(16);
    var greenString = Math.round(this.green).toString(16);
    var blueString = Math.round(this.blue).toString(16);
    return (
      '#' +
      (this.red > 15.5 ? redString : '0' + redString) +
      (this.green > 15.5 ? greenString : '0' + greenString) +
      (this.blue > 15.5 ? blueString : '0' + blueString)
    );
  };

  const hexRegex = /^#[0-9a-f]{3,8}$/i;
  const colorFnRegex = /^((?:rgb|hsl)a?)\s*\(([^\)]*)\)/i;

  /**
   * Parse any valid color string and assign its values to "this"
   * @method parseString
   * @memberof axe.commons.color.Color
   * @instance
   */
  this.parseString = function parseString(colorString) {
    // IE occasionally returns named colors instead of RGB(A) values
    if (standards.cssColors[colorString] || colorString === 'transparent') {
      const [red, green, blue] = standards.cssColors[colorString] || [0, 0, 0];
      this.red = red;
      this.green = green;
      this.blue = blue;
      this.alpha = colorString === 'transparent' ? 0 : 1;
      return;
    }

    if (colorString.match(colorFnRegex)) {
      this.parseColorFnString(colorString);
      return;
    }

    if (colorString.match(hexRegex)) {
      this.parseHexString(colorString);
      return;
    }
    throw new Error(`Unable to parse color "${colorString}"`);
  };

  /**
   * Set the color value based on a CSS RGB/RGBA string
   * @method parseRgbString
   * @deprecated
   * @memberof axe.commons.color.Color
   * @instance
   * @param  {string}  rgb  The string value
   */
  this.parseRgbString = function parseRgbString(colorString) {
    // IE can pass transparent as value instead of rgba
    if (colorString === 'transparent') {
      this.red = 0;
      this.green = 0;
      this.blue = 0;
      this.alpha = 0;
      return;
    }
    this.parseColorFnString(colorString);
  };

  /**
   * Set the color value based on a CSS RGB/RGBA string
   * @method parseHexString
   * @deprecated
   * @memberof axe.commons.color.Color
   * @instance
   * @param  {string}  rgb  The string value
   */
  this.parseHexString = function parseHexString(colorString) {
    if (!colorString.match(hexRegex) || [6, 8].includes(colorString.length)) {
      return;
    }
    colorString = colorString.replace('#', '');
    if (colorString.length < 6) {
      const [r, g, b, a] = colorString;
      colorString = r + r + g + g + b + b;
      if (a) {
        colorString += a + a;
      }
    }

    var aRgbHex = colorString.match(/.{1,2}/g);
    this.red = parseInt(aRgbHex[0], 16);
    this.green = parseInt(aRgbHex[1], 16);
    this.blue = parseInt(aRgbHex[2], 16);
    if (aRgbHex[3]) {
      this.alpha = parseInt(aRgbHex[3], 16) / 255;
    } else {
      this.alpha = 1;
    }
  };

  /**
   * Set the color value based on a CSS RGB/RGBA string
   * @method parseColorFnString
   * @deprecated
   * @memberof axe.commons.color.Color
   * @instance
   * @param  {string}  rgb  The string value
   */
  this.parseColorFnString = function parseColorFnString(colorString) {
    const [, colorFunc, colorValStr] = colorString.match(colorFnRegex) || [];
    if (!colorFunc || !colorValStr) {
      return;
    }

    // Get array of color number strings from the string:
    const colorVals = colorValStr
      .split(/\s*[,\/\s]\s*/)
      .map(str => str.replace(',', '').trim())
      .filter(str => str !== '');

    // Convert to numbers
    let colorNums = colorVals.map((val, index) => {
      return convertColorVal(colorFunc, val, index);
    });

    if (colorFunc.substr(0, 3) === 'hsl') {
      colorNums = hslToRgb(colorNums);
    }

    this.red = colorNums[0];
    this.green = colorNums[1];
    this.blue = colorNums[2];
    this.alpha = typeof colorNums[3] === 'number' ? colorNums[3] : 1;
  };

  /**
   * Get the relative luminance value
   * using algorithm from http://www.w3.org/WAI/GL/wiki/Relative_luminance
   * @method getRelativeLuminance
   * @memberof axe.commons.color.Color
   * @instance
   * @return {number} The luminance value, ranges from 0 to 1
   */
  this.getRelativeLuminance = function getRelativeLuminance() {
    var rSRGB = this.red / 255;
    var gSRGB = this.green / 255;
    var bSRGB = this.blue / 255;

    var r =
      rSRGB <= 0.03928 ? rSRGB / 12.92 : Math.pow((rSRGB + 0.055) / 1.055, 2.4);
    var g =
      gSRGB <= 0.03928 ? gSRGB / 12.92 : Math.pow((gSRGB + 0.055) / 1.055, 2.4);
    var b =
      bSRGB <= 0.03928 ? bSRGB / 12.92 : Math.pow((bSRGB + 0.055) / 1.055, 2.4);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
}

export default Color;
