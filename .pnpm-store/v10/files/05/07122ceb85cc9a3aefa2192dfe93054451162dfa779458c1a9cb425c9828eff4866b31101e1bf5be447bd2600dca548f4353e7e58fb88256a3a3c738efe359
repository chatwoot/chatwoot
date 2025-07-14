(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
  typeof define === 'function' && define.amd ? define(['exports'], factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, factory(global.color2k = {}));
})(this, (function (exports) { 'use strict';

  /**
   * A simple guard function:
   *
   * ```js
   * Math.min(Math.max(low, value), high)
   * ```
   */
  function guard(low, high, value) {
    return Math.min(Math.max(low, value), high);
  }

  class ColorError extends Error {
    constructor(color) {
      super(`Failed to parse color: "${color}"`);
    }
  }
  var ColorError$1 = ColorError;

  /**
   * Parses a color into red, gree, blue, alpha parts
   *
   * @param color the input color. Can be a RGB, RBGA, HSL, HSLA, or named color
   */
  function parseToRgba(color) {
    if (typeof color !== 'string') throw new ColorError$1(color);
    if (color.trim().toLowerCase() === 'transparent') return [0, 0, 0, 0];
    let normalizedColor = color.trim();
    normalizedColor = namedColorRegex.test(color) ? nameToHex(color) : color;
    const reducedHexMatch = reducedHexRegex.exec(normalizedColor);
    if (reducedHexMatch) {
      const arr = Array.from(reducedHexMatch).slice(1);
      return [...arr.slice(0, 3).map(x => parseInt(r(x, 2), 16)), parseInt(r(arr[3] || 'f', 2), 16) / 255];
    }
    const hexMatch = hexRegex.exec(normalizedColor);
    if (hexMatch) {
      const arr = Array.from(hexMatch).slice(1);
      return [...arr.slice(0, 3).map(x => parseInt(x, 16)), parseInt(arr[3] || 'ff', 16) / 255];
    }
    const rgbaMatch = rgbaRegex.exec(normalizedColor);
    if (rgbaMatch) {
      const arr = Array.from(rgbaMatch).slice(1);
      return [...arr.slice(0, 3).map(x => parseInt(x, 10)), parseFloat(arr[3] || '1')];
    }
    const hslaMatch = hslaRegex.exec(normalizedColor);
    if (hslaMatch) {
      const [h, s, l, a] = Array.from(hslaMatch).slice(1).map(parseFloat);
      if (guard(0, 100, s) !== s) throw new ColorError$1(color);
      if (guard(0, 100, l) !== l) throw new ColorError$1(color);
      return [...hslToRgb(h, s, l), Number.isNaN(a) ? 1 : a];
    }
    throw new ColorError$1(color);
  }
  function hash(str) {
    let hash = 5381;
    let i = str.length;
    while (i) {
      hash = hash * 33 ^ str.charCodeAt(--i);
    }

    /* JavaScript does bitwise operations (like XOR, above) on 32-bit signed
     * integers. Since we want the results to be always positive, convert the
     * signed int to an unsigned by doing an unsigned bitshift. */
    return (hash >>> 0) % 2341;
  }
  const colorToInt = x => parseInt(x.replace(/_/g, ''), 36);
  const compressedColorMap = '1q29ehhb 1n09sgk7 1kl1ekf_ _yl4zsno 16z9eiv3 1p29lhp8 _bd9zg04 17u0____ _iw9zhe5 _to73___ _r45e31e _7l6g016 _jh8ouiv _zn3qba8 1jy4zshs 11u87k0u 1ro9yvyo 1aj3xael 1gz9zjz0 _3w8l4xo 1bf1ekf_ _ke3v___ _4rrkb__ 13j776yz _646mbhl _nrjr4__ _le6mbhl 1n37ehkb _m75f91n _qj3bzfz 1939yygw 11i5z6x8 _1k5f8xs 1509441m 15t5lwgf _ae2th1n _tg1ugcv 1lp1ugcv 16e14up_ _h55rw7n _ny9yavn _7a11xb_ 1ih442g9 _pv442g9 1mv16xof 14e6y7tu 1oo9zkds 17d1cisi _4v9y70f _y98m8kc 1019pq0v 12o9zda8 _348j4f4 1et50i2o _8epa8__ _ts6senj 1o350i2o 1mi9eiuo 1259yrp0 1ln80gnw _632xcoy 1cn9zldc _f29edu4 1n490c8q _9f9ziet 1b94vk74 _m49zkct 1kz6s73a 1eu9dtog _q58s1rz 1dy9sjiq __u89jo3 _aj5nkwg _ld89jo3 13h9z6wx _qa9z2ii _l119xgq _bs5arju 1hj4nwk9 1qt4nwk9 1ge6wau6 14j9zlcw 11p1edc_ _ms1zcxe _439shk6 _jt9y70f _754zsow 1la40eju _oq5p___ _x279qkz 1fa5r3rv _yd2d9ip _424tcku _8y1di2_ _zi2uabw _yy7rn9h 12yz980_ __39ljp6 1b59zg0x _n39zfzp 1fy9zest _b33k___ _hp9wq92 1il50hz4 _io472ub _lj9z3eo 19z9ykg0 _8t8iu3a 12b9bl4a 1ak5yw0o _896v4ku _tb8k8lv _s59zi6t _c09ze0p 1lg80oqn 1id9z8wb _238nba5 1kq6wgdi _154zssg _tn3zk49 _da9y6tc 1sg7cv4f _r12jvtt 1gq5fmkz 1cs9rvci _lp9jn1c _xw1tdnb 13f9zje6 16f6973h _vo7ir40 _bt5arjf _rc45e4t _hr4e100 10v4e100 _hc9zke2 _w91egv_ _sj2r1kk 13c87yx8 _vqpds__ _ni8ggk8 _tj9yqfb 1ia2j4r4 _7x9b10u 1fc9ld4j 1eq9zldr _5j9lhpx _ez9zl6o _md61fzm'.split(' ').reduce((acc, next) => {
    const key = colorToInt(next.substring(0, 3));
    const hex = colorToInt(next.substring(3)).toString(16);

    // NOTE: padStart could be used here but it breaks Node 6 compat
    // https://github.com/ricokahler/color2k/issues/351
    let prefix = '';
    for (let i = 0; i < 6 - hex.length; i++) {
      prefix += '0';
    }
    acc[key] = `${prefix}${hex}`;
    return acc;
  }, {});

  /**
   * Checks if a string is a CSS named color and returns its equivalent hex value, otherwise returns the original color.
   */
  function nameToHex(color) {
    const normalizedColorName = color.toLowerCase().trim();
    const result = compressedColorMap[hash(normalizedColorName)];
    if (!result) throw new ColorError$1(color);
    return `#${result}`;
  }
  const r = (str, amount) => Array.from(Array(amount)).map(() => str).join('');
  const reducedHexRegex = new RegExp(`^#${r('([a-f0-9])', 3)}([a-f0-9])?$`, 'i');
  const hexRegex = new RegExp(`^#${r('([a-f0-9]{2})', 3)}([a-f0-9]{2})?$`, 'i');
  const rgbaRegex = new RegExp(`^rgba?\\(\\s*(\\d+)\\s*${r(',\\s*(\\d+)\\s*', 2)}(?:,\\s*([\\d.]+))?\\s*\\)$`, 'i');
  const hslaRegex = /^hsla?\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%(?:\s*,\s*([\d.]+))?\s*\)$/i;
  const namedColorRegex = /^[a-z]+$/i;
  const roundColor = color => {
    return Math.round(color * 255);
  };
  const hslToRgb = (hue, saturation, lightness) => {
    let l = lightness / 100;
    if (saturation === 0) {
      // achromatic
      return [l, l, l].map(roundColor);
    }

    // formulae from https://en.wikipedia.org/wiki/HSL_and_HSV
    const huePrime = (hue % 360 + 360) % 360 / 60;
    const chroma = (1 - Math.abs(2 * l - 1)) * (saturation / 100);
    const secondComponent = chroma * (1 - Math.abs(huePrime % 2 - 1));
    let red = 0;
    let green = 0;
    let blue = 0;
    if (huePrime >= 0 && huePrime < 1) {
      red = chroma;
      green = secondComponent;
    } else if (huePrime >= 1 && huePrime < 2) {
      red = secondComponent;
      green = chroma;
    } else if (huePrime >= 2 && huePrime < 3) {
      green = chroma;
      blue = secondComponent;
    } else if (huePrime >= 3 && huePrime < 4) {
      green = secondComponent;
      blue = chroma;
    } else if (huePrime >= 4 && huePrime < 5) {
      red = secondComponent;
      blue = chroma;
    } else if (huePrime >= 5 && huePrime < 6) {
      red = chroma;
      blue = secondComponent;
    }
    const lightnessModification = l - chroma / 2;
    const finalRed = red + lightnessModification;
    const finalGreen = green + lightnessModification;
    const finalBlue = blue + lightnessModification;
    return [finalRed, finalGreen, finalBlue].map(roundColor);
  };

  // taken from:
  // https://github.com/styled-components/polished/blob/a23a6a2bb26802b3d922d9c3b67bac3f3a54a310/src/internalHelpers/_rgbToHsl.js

  /**
   * Parses a color in hue, saturation, lightness, and the alpha channel.
   *
   * Hue is a number between 0 and 360, saturation, lightness, and alpha are
   * decimal percentages between 0 and 1
   */
  function parseToHsla(color) {
    const [red, green, blue, alpha] = parseToRgba(color).map((value, index) =>
    // 3rd index is alpha channel which is already normalized
    index === 3 ? value : value / 255);
    const max = Math.max(red, green, blue);
    const min = Math.min(red, green, blue);
    const lightness = (max + min) / 2;

    // achromatic
    if (max === min) return [0, 0, lightness, alpha];
    const delta = max - min;
    const saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min);
    const hue = 60 * (red === max ? (green - blue) / delta + (green < blue ? 6 : 0) : green === max ? (blue - red) / delta + 2 : (red - green) / delta + 4);
    return [hue, saturation, lightness, alpha];
  }

  /**
   * Takes in hsla parts and constructs an hsla string
   *
   * @param hue The color circle (from 0 to 360) - 0 (or 360) is red, 120 is green, 240 is blue
   * @param saturation Percentage of saturation, given as a decimal between 0 and 1
   * @param lightness Percentage of lightness, given as a decimal between 0 and 1
   * @param alpha Percentage of opacity, given as a decimal between 0 and 1
   */
  function hsla(hue, saturation, lightness, alpha) {
    return `hsla(${(hue % 360).toFixed()}, ${guard(0, 100, saturation * 100).toFixed()}%, ${guard(0, 100, lightness * 100).toFixed()}%, ${parseFloat(guard(0, 1, alpha).toFixed(3))})`;
  }

  /**
   * Adjusts the current hue of the color by the given degrees. Wraps around when
   * over 360.
   *
   * @param color input color
   * @param degrees degrees to adjust the input color, accepts degree integers
   * (0 - 360) and wraps around on overflow
   */
  function adjustHue(color, degrees) {
    const [h, s, l, a] = parseToHsla(color);
    return hsla(h + degrees, s, l, a);
  }

  /**
   * Darkens using lightness. This is equivalent to subtracting the lightness
   * from the L in HSL.
   *
   * @param amount The amount to darken, given as a decimal between 0 and 1
   */
  function darken(color, amount) {
    const [hue, saturation, lightness, alpha] = parseToHsla(color);
    return hsla(hue, saturation, lightness - amount, alpha);
  }

  /**
   * Desaturates the input color by the given amount via subtracting from the `s`
   * in `hsla`.
   *
   * @param amount The amount to desaturate, given as a decimal between 0 and 1
   */
  function desaturate(color, amount) {
    const [h, s, l, a] = parseToHsla(color);
    return hsla(h, s - amount, l, a);
  }

  // taken from:
  // https://github.com/styled-components/polished/blob/0764c982551b487469043acb56281b0358b3107b/src/color/getLuminance.js

  /**
   * Returns a number (float) representing the luminance of a color.
   */
  function getLuminance(color) {
    if (color === 'transparent') return 0;
    function f(x) {
      const channel = x / 255;
      return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
    }
    const [r, g, b] = parseToRgba(color);
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  }

  // taken from:
  // https://github.com/styled-components/polished/blob/0764c982551b487469043acb56281b0358b3107b/src/color/getContrast.js

  /**
   * Returns the contrast ratio between two colors based on
   * [W3's recommended equation for calculating contrast](http://www.w3.org/TR/WCAG20/#contrast-ratiodef).
   */
  function getContrast(color1, color2) {
    const luminance1 = getLuminance(color1);
    const luminance2 = getLuminance(color2);
    return luminance1 > luminance2 ? (luminance1 + 0.05) / (luminance2 + 0.05) : (luminance2 + 0.05) / (luminance1 + 0.05);
  }

  /**
   * Takes in rgba parts and returns an rgba string
   *
   * @param red The amount of red in the red channel, given in a number between 0 and 255 inclusive
   * @param green The amount of green in the red channel, given in a number between 0 and 255 inclusive
   * @param blue The amount of blue in the red channel, given in a number between 0 and 255 inclusive
   * @param alpha Percentage of opacity, given as a decimal between 0 and 1
   */
  function rgba(red, green, blue, alpha) {
    return `rgba(${guard(0, 255, red).toFixed()}, ${guard(0, 255, green).toFixed()}, ${guard(0, 255, blue).toFixed()}, ${parseFloat(guard(0, 1, alpha).toFixed(3))})`;
  }

  /**
   * Mixes two colors together. Taken from sass's implementation.
   */
  function mix(color1, color2, weight) {
    const normalize = (n, index) =>
    // 3rd index is alpha channel which is already normalized
    index === 3 ? n : n / 255;
    const [r1, g1, b1, a1] = parseToRgba(color1).map(normalize);
    const [r2, g2, b2, a2] = parseToRgba(color2).map(normalize);

    // The formula is copied from the original Sass implementation:
    // http://sass-lang.com/documentation/Sass/Script/Functions.html#mix-instance_method
    const alphaDelta = a2 - a1;
    const normalizedWeight = weight * 2 - 1;
    const combinedWeight = normalizedWeight * alphaDelta === -1 ? normalizedWeight : normalizedWeight + alphaDelta / (1 + normalizedWeight * alphaDelta);
    const weight2 = (combinedWeight + 1) / 2;
    const weight1 = 1 - weight2;
    const r = (r1 * weight1 + r2 * weight2) * 255;
    const g = (g1 * weight1 + g2 * weight2) * 255;
    const b = (b1 * weight1 + b2 * weight2) * 255;
    const a = a2 * weight + a1 * (1 - weight);
    return rgba(r, g, b, a);
  }

  /**
   * Given a series colors, this function will return a `scale(x)` function that
   * accepts a percentage as a decimal between 0 and 1 and returns the color at
   * that percentage in the scale.
   *
   * ```js
   * const scale = getScale('red', 'yellow', 'green');
   * console.log(scale(0)); // rgba(255, 0, 0, 1)
   * console.log(scale(0.5)); // rgba(255, 255, 0, 1)
   * console.log(scale(1)); // rgba(0, 128, 0, 1)
   * ```
   *
   * If you'd like to limit the domain and range like chroma-js, we recommend
   * wrapping scale again.
   *
   * ```js
   * const _scale = getScale('red', 'yellow', 'green');
   * const scale = x => _scale(x / 100);
   *
   * console.log(scale(0)); // rgba(255, 0, 0, 1)
   * console.log(scale(50)); // rgba(255, 255, 0, 1)
   * console.log(scale(100)); // rgba(0, 128, 0, 1)
   * ```
   */
  function getScale() {
    for (var _len = arguments.length, colors = new Array(_len), _key = 0; _key < _len; _key++) {
      colors[_key] = arguments[_key];
    }
    return n => {
      const lastIndex = colors.length - 1;
      const lowIndex = guard(0, lastIndex, Math.floor(n * lastIndex));
      const highIndex = guard(0, lastIndex, Math.ceil(n * lastIndex));
      const color1 = colors[lowIndex];
      const color2 = colors[highIndex];
      const unit = 1 / lastIndex;
      const weight = (n - unit * lowIndex) / unit;
      return mix(color1, color2, weight);
    };
  }

  const guidelines = {
    decorative: 1.5,
    readable: 3,
    aa: 4.5,
    aaa: 7
  };

  /**
   * Returns whether or not a color has bad contrast against a background
   * according to a given standard.
   */
  function hasBadContrast(color) {
    let standard = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'aa';
    let background = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : '#fff';
    return getContrast(color, background) < guidelines[standard];
  }

  /**
   * Lightens a color by a given amount. This is equivalent to
   * `darken(color, -amount)`
   *
   * @param amount The amount to darken, given as a decimal between 0 and 1
   */
  function lighten(color, amount) {
    return darken(color, -amount);
  }

  /**
   * Takes in a color and makes it more transparent by convert to `rgba` and
   * decreasing the amount in the alpha channel.
   *
   * @param amount The amount to increase the transparency by, given as a decimal between 0 and 1
   */
  function transparentize(color, amount) {
    const [r, g, b, a] = parseToRgba(color);
    return rgba(r, g, b, a - amount);
  }

  /**
   * Takes a color and un-transparentizes it. Equivalent to
   * `transparentize(color, -amount)`
   *
   * @param amount The amount to increase the opacity by, given as a decimal between 0 and 1
   */
  function opacify(color, amount) {
    return transparentize(color, -amount);
  }

  /**
   * An alternative function to `readableColor`. Returns whether or not the 
   * readable color (i.e. the color to be place on top the input color) should be
   * black.
   */
  function readableColorIsBlack(color) {
    return getLuminance(color) > 0.179;
  }

  /**
   * Returns black or white for best contrast depending on the luminosity of the
   * given color.
   */
  function readableColor(color) {
    return readableColorIsBlack(color) ? '#000' : '#fff';
  }

  /**
   * Saturates a color by converting it to `hsl` and increasing the saturation
   * amount. Equivalent to `desaturate(color, -amount)`
   * 
   * @param color Input color
   * @param amount The amount to darken, given as a decimal between 0 and 1
   */
  function saturate(color, amount) {
    return desaturate(color, -amount);
  }

  /**
   * Takes in any color and returns it as a hex code.
   */
  function toHex(color) {
    const [r, g, b, a] = parseToRgba(color);
    let hex = x => {
      const h = guard(0, 255, x).toString(16);
      // NOTE: padStart could be used here but it breaks Node 6 compat
      // https://github.com/ricokahler/color2k/issues/351
      return h.length === 1 ? `0${h}` : h;
    };
    return `#${hex(r)}${hex(g)}${hex(b)}${a < 1 ? hex(Math.round(a * 255)) : ''}`;
  }

  /**
   * Takes in any color and returns it as an rgba string.
   */
  function toRgba(color) {
    return rgba(...parseToRgba(color));
  }

  /**
   * Takes in any color and returns it as an hsla string.
   */
  function toHsla(color) {
    return hsla(...parseToHsla(color));
  }

  exports.ColorError = ColorError$1;
  exports.adjustHue = adjustHue;
  exports.darken = darken;
  exports.desaturate = desaturate;
  exports.getContrast = getContrast;
  exports.getLuminance = getLuminance;
  exports.getScale = getScale;
  exports.guard = guard;
  exports.hasBadContrast = hasBadContrast;
  exports.hsla = hsla;
  exports.lighten = lighten;
  exports.mix = mix;
  exports.opacify = opacify;
  exports.parseToHsla = parseToHsla;
  exports.parseToRgba = parseToRgba;
  exports.readableColor = readableColor;
  exports.readableColorIsBlack = readableColorIsBlack;
  exports.rgba = rgba;
  exports.saturate = saturate;
  exports.toHex = toHex;
  exports.toHsla = toHsla;
  exports.toRgba = toRgba;
  exports.transparentize = transparentize;

}));
//# sourceMappingURL=index.unpkg.umd.js.map
