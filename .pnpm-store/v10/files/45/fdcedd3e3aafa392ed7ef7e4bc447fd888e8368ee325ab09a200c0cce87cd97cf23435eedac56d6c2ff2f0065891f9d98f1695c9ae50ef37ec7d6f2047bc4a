'use strict';

function _iterableToArrayLimit(r, l) {
  var t = null == r ? null : "undefined" != typeof Symbol && r[Symbol.iterator] || r["@@iterator"];
  if (null != t) {
    var e,
      n,
      i,
      u,
      a = [],
      f = !0,
      o = !1;
    try {
      if (i = (t = t.call(r)).next, 0 === l) {
        if (Object(t) !== t) return;
        f = !1;
      } else for (; !(f = (e = i.call(t)).done) && (a.push(e.value), a.length !== l); f = !0);
    } catch (r) {
      o = !0, n = r;
    } finally {
      try {
        if (!f && null != t.return && (u = t.return(), Object(u) !== u)) return;
      } finally {
        if (o) throw n;
      }
    }
    return a;
  }
}
function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}
function _defineProperties(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i];
    descriptor.enumerable = descriptor.enumerable || false;
    descriptor.configurable = true;
    if ("value" in descriptor) descriptor.writable = true;
    Object.defineProperty(target, _toPropertyKey(descriptor.key), descriptor);
  }
}
function _createClass(Constructor, protoProps, staticProps) {
  if (protoProps) _defineProperties(Constructor.prototype, protoProps);
  if (staticProps) _defineProperties(Constructor, staticProps);
  Object.defineProperty(Constructor, "prototype", {
    writable: false
  });
  return Constructor;
}
function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }
  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  Object.defineProperty(subClass, "prototype", {
    writable: false
  });
  if (superClass) _setPrototypeOf(subClass, superClass);
}
function _getPrototypeOf(o) {
  _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf.bind() : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}
function _setPrototypeOf(o, p) {
  _setPrototypeOf = Object.setPrototypeOf ? Object.setPrototypeOf.bind() : function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };
  return _setPrototypeOf(o, p);
}
function _isNativeReflectConstruct() {
  if (typeof Reflect === "undefined" || !Reflect.construct) return false;
  if (Reflect.construct.sham) return false;
  if (typeof Proxy === "function") return true;
  try {
    Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {}));
    return true;
  } catch (e) {
    return false;
  }
}
function _construct(Parent, args, Class) {
  if (_isNativeReflectConstruct()) {
    _construct = Reflect.construct.bind();
  } else {
    _construct = function _construct(Parent, args, Class) {
      var a = [null];
      a.push.apply(a, args);
      var Constructor = Function.bind.apply(Parent, a);
      var instance = new Constructor();
      if (Class) _setPrototypeOf(instance, Class.prototype);
      return instance;
    };
  }
  return _construct.apply(null, arguments);
}
function _isNativeFunction(fn) {
  return Function.toString.call(fn).indexOf("[native code]") !== -1;
}
function _wrapNativeSuper(Class) {
  var _cache = typeof Map === "function" ? new Map() : undefined;
  _wrapNativeSuper = function _wrapNativeSuper(Class) {
    if (Class === null || !_isNativeFunction(Class)) return Class;
    if (typeof Class !== "function") {
      throw new TypeError("Super expression must either be null or a function");
    }
    if (typeof _cache !== "undefined") {
      if (_cache.has(Class)) return _cache.get(Class);
      _cache.set(Class, Wrapper);
    }
    function Wrapper() {
      return _construct(Class, arguments, _getPrototypeOf(this).constructor);
    }
    Wrapper.prototype = Object.create(Class.prototype, {
      constructor: {
        value: Wrapper,
        enumerable: false,
        writable: true,
        configurable: true
      }
    });
    return _setPrototypeOf(Wrapper, Class);
  };
  return _wrapNativeSuper(Class);
}
function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }
  return self;
}
function _possibleConstructorReturn(self, call) {
  if (call && (typeof call === "object" || typeof call === "function")) {
    return call;
  } else if (call !== void 0) {
    throw new TypeError("Derived constructors may only return object or undefined");
  }
  return _assertThisInitialized(self);
}
function _createSuper(Derived) {
  var hasNativeReflectConstruct = _isNativeReflectConstruct();
  return function _createSuperInternal() {
    var Super = _getPrototypeOf(Derived),
      result;
    if (hasNativeReflectConstruct) {
      var NewTarget = _getPrototypeOf(this).constructor;
      result = Reflect.construct(Super, arguments, NewTarget);
    } else {
      result = Super.apply(this, arguments);
    }
    return _possibleConstructorReturn(this, result);
  };
}
function _slicedToArray(arr, i) {
  return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest();
}
function _toConsumableArray(arr) {
  return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
}
function _arrayWithoutHoles(arr) {
  if (Array.isArray(arr)) return _arrayLikeToArray(arr);
}
function _arrayWithHoles(arr) {
  if (Array.isArray(arr)) return arr;
}
function _iterableToArray(iter) {
  if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter);
}
function _unsupportedIterableToArray(o, minLen) {
  if (!o) return;
  if (typeof o === "string") return _arrayLikeToArray(o, minLen);
  var n = Object.prototype.toString.call(o).slice(8, -1);
  if (n === "Object" && o.constructor) n = o.constructor.name;
  if (n === "Map" || n === "Set") return Array.from(o);
  if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen);
}
function _arrayLikeToArray(arr, len) {
  if (len == null || len > arr.length) len = arr.length;
  for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i];
  return arr2;
}
function _nonIterableSpread() {
  throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}
function _nonIterableRest() {
  throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}
function _toPrimitive(input, hint) {
  if (typeof input !== "object" || input === null) return input;
  var prim = input[Symbol.toPrimitive];
  if (prim !== undefined) {
    var res = prim.call(input, hint || "default");
    if (typeof res !== "object") return res;
    throw new TypeError("@@toPrimitive must return a primitive value.");
  }
  return (hint === "string" ? String : Number)(input);
}
function _toPropertyKey(arg) {
  var key = _toPrimitive(arg, "string");
  return typeof key === "symbol" ? key : String(key);
}

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

var ColorError = /*#__PURE__*/function (_Error) {
  _inherits(ColorError, _Error);
  var _super = _createSuper(ColorError);
  function ColorError(color) {
    _classCallCheck(this, ColorError);
    return _super.call(this, `Failed to parse color: "${color}"`);
  }
  return _createClass(ColorError);
}( /*#__PURE__*/_wrapNativeSuper(Error));
var ColorError$1 = ColorError;

/**
 * Parses a color into red, gree, blue, alpha parts
 *
 * @param color the input color. Can be a RGB, RBGA, HSL, HSLA, or named color
 */
function parseToRgba(color) {
  if (typeof color !== 'string') throw new ColorError$1(color);
  if (color.trim().toLowerCase() === 'transparent') return [0, 0, 0, 0];
  var normalizedColor = color.trim();
  normalizedColor = namedColorRegex.test(color) ? nameToHex(color) : color;
  var reducedHexMatch = reducedHexRegex.exec(normalizedColor);
  if (reducedHexMatch) {
    var arr = Array.from(reducedHexMatch).slice(1);
    return [].concat(_toConsumableArray(arr.slice(0, 3).map(function (x) {
      return parseInt(r(x, 2), 16);
    })), [parseInt(r(arr[3] || 'f', 2), 16) / 255]);
  }
  var hexMatch = hexRegex.exec(normalizedColor);
  if (hexMatch) {
    var _arr = Array.from(hexMatch).slice(1);
    return [].concat(_toConsumableArray(_arr.slice(0, 3).map(function (x) {
      return parseInt(x, 16);
    })), [parseInt(_arr[3] || 'ff', 16) / 255]);
  }
  var rgbaMatch = rgbaRegex.exec(normalizedColor);
  if (rgbaMatch) {
    var _arr2 = Array.from(rgbaMatch).slice(1);
    return [].concat(_toConsumableArray(_arr2.slice(0, 3).map(function (x) {
      return parseInt(x, 10);
    })), [parseFloat(_arr2[3] || '1')]);
  }
  var hslaMatch = hslaRegex.exec(normalizedColor);
  if (hslaMatch) {
    var _Array$from$slice$map = Array.from(hslaMatch).slice(1).map(parseFloat),
      _Array$from$slice$map2 = _slicedToArray(_Array$from$slice$map, 4),
      h = _Array$from$slice$map2[0],
      s = _Array$from$slice$map2[1],
      l = _Array$from$slice$map2[2],
      a = _Array$from$slice$map2[3];
    if (guard(0, 100, s) !== s) throw new ColorError$1(color);
    if (guard(0, 100, l) !== l) throw new ColorError$1(color);
    return [].concat(_toConsumableArray(hslToRgb(h, s, l)), [Number.isNaN(a) ? 1 : a]);
  }
  throw new ColorError$1(color);
}
function hash(str) {
  var hash = 5381;
  var i = str.length;
  while (i) {
    hash = hash * 33 ^ str.charCodeAt(--i);
  }

  /* JavaScript does bitwise operations (like XOR, above) on 32-bit signed
   * integers. Since we want the results to be always positive, convert the
   * signed int to an unsigned by doing an unsigned bitshift. */
  return (hash >>> 0) % 2341;
}
var colorToInt = function colorToInt(x) {
  return parseInt(x.replace(/_/g, ''), 36);
};
var compressedColorMap = '1q29ehhb 1n09sgk7 1kl1ekf_ _yl4zsno 16z9eiv3 1p29lhp8 _bd9zg04 17u0____ _iw9zhe5 _to73___ _r45e31e _7l6g016 _jh8ouiv _zn3qba8 1jy4zshs 11u87k0u 1ro9yvyo 1aj3xael 1gz9zjz0 _3w8l4xo 1bf1ekf_ _ke3v___ _4rrkb__ 13j776yz _646mbhl _nrjr4__ _le6mbhl 1n37ehkb _m75f91n _qj3bzfz 1939yygw 11i5z6x8 _1k5f8xs 1509441m 15t5lwgf _ae2th1n _tg1ugcv 1lp1ugcv 16e14up_ _h55rw7n _ny9yavn _7a11xb_ 1ih442g9 _pv442g9 1mv16xof 14e6y7tu 1oo9zkds 17d1cisi _4v9y70f _y98m8kc 1019pq0v 12o9zda8 _348j4f4 1et50i2o _8epa8__ _ts6senj 1o350i2o 1mi9eiuo 1259yrp0 1ln80gnw _632xcoy 1cn9zldc _f29edu4 1n490c8q _9f9ziet 1b94vk74 _m49zkct 1kz6s73a 1eu9dtog _q58s1rz 1dy9sjiq __u89jo3 _aj5nkwg _ld89jo3 13h9z6wx _qa9z2ii _l119xgq _bs5arju 1hj4nwk9 1qt4nwk9 1ge6wau6 14j9zlcw 11p1edc_ _ms1zcxe _439shk6 _jt9y70f _754zsow 1la40eju _oq5p___ _x279qkz 1fa5r3rv _yd2d9ip _424tcku _8y1di2_ _zi2uabw _yy7rn9h 12yz980_ __39ljp6 1b59zg0x _n39zfzp 1fy9zest _b33k___ _hp9wq92 1il50hz4 _io472ub _lj9z3eo 19z9ykg0 _8t8iu3a 12b9bl4a 1ak5yw0o _896v4ku _tb8k8lv _s59zi6t _c09ze0p 1lg80oqn 1id9z8wb _238nba5 1kq6wgdi _154zssg _tn3zk49 _da9y6tc 1sg7cv4f _r12jvtt 1gq5fmkz 1cs9rvci _lp9jn1c _xw1tdnb 13f9zje6 16f6973h _vo7ir40 _bt5arjf _rc45e4t _hr4e100 10v4e100 _hc9zke2 _w91egv_ _sj2r1kk 13c87yx8 _vqpds__ _ni8ggk8 _tj9yqfb 1ia2j4r4 _7x9b10u 1fc9ld4j 1eq9zldr _5j9lhpx _ez9zl6o _md61fzm'.split(' ').reduce(function (acc, next) {
  var key = colorToInt(next.substring(0, 3));
  var hex = colorToInt(next.substring(3)).toString(16);

  // NOTE: padStart could be used here but it breaks Node 6 compat
  // https://github.com/ricokahler/color2k/issues/351
  var prefix = '';
  for (var i = 0; i < 6 - hex.length; i++) {
    prefix += '0';
  }
  acc[key] = `${prefix}${hex}`;
  return acc;
}, {});

/**
 * Checks if a string is a CSS named color and returns its equivalent hex value, otherwise returns the original color.
 */
function nameToHex(color) {
  var normalizedColorName = color.toLowerCase().trim();
  var result = compressedColorMap[hash(normalizedColorName)];
  if (!result) throw new ColorError$1(color);
  return `#${result}`;
}
var r = function r(str, amount) {
  return Array.from(Array(amount)).map(function () {
    return str;
  }).join('');
};
var reducedHexRegex = new RegExp(`^#${r('([a-f0-9])', 3)}([a-f0-9])?$`, 'i');
var hexRegex = new RegExp(`^#${r('([a-f0-9]{2})', 3)}([a-f0-9]{2})?$`, 'i');
var rgbaRegex = new RegExp(`^rgba?\\(\\s*(\\d+)\\s*${r(',\\s*(\\d+)\\s*', 2)}(?:,\\s*([\\d.]+))?\\s*\\)$`, 'i');
var hslaRegex = /^hsla?\(\s*([\d.]+)\s*,\s*([\d.]+)%\s*,\s*([\d.]+)%(?:\s*,\s*([\d.]+))?\s*\)$/i;
var namedColorRegex = /^[a-z]+$/i;
var roundColor = function roundColor(color) {
  return Math.round(color * 255);
};
var hslToRgb = function hslToRgb(hue, saturation, lightness) {
  var l = lightness / 100;
  if (saturation === 0) {
    // achromatic
    return [l, l, l].map(roundColor);
  }

  // formulae from https://en.wikipedia.org/wiki/HSL_and_HSV
  var huePrime = (hue % 360 + 360) % 360 / 60;
  var chroma = (1 - Math.abs(2 * l - 1)) * (saturation / 100);
  var secondComponent = chroma * (1 - Math.abs(huePrime % 2 - 1));
  var red = 0;
  var green = 0;
  var blue = 0;
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
  var lightnessModification = l - chroma / 2;
  var finalRed = red + lightnessModification;
  var finalGreen = green + lightnessModification;
  var finalBlue = blue + lightnessModification;
  return [finalRed, finalGreen, finalBlue].map(roundColor);
};

/**
 * Parses a color in hue, saturation, lightness, and the alpha channel.
 *
 * Hue is a number between 0 and 360, saturation, lightness, and alpha are
 * decimal percentages between 0 and 1
 */
function parseToHsla(color) {
  var _parseToRgba$map = parseToRgba(color).map(function (value, index) {
      return (
        // 3rd index is alpha channel which is already normalized
        index === 3 ? value : value / 255
      );
    }),
    _parseToRgba$map2 = _slicedToArray(_parseToRgba$map, 4),
    red = _parseToRgba$map2[0],
    green = _parseToRgba$map2[1],
    blue = _parseToRgba$map2[2],
    alpha = _parseToRgba$map2[3];
  var max = Math.max(red, green, blue);
  var min = Math.min(red, green, blue);
  var lightness = (max + min) / 2;

  // achromatic
  if (max === min) return [0, 0, lightness, alpha];
  var delta = max - min;
  var saturation = lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min);
  var hue = 60 * (red === max ? (green - blue) / delta + (green < blue ? 6 : 0) : green === max ? (blue - red) / delta + 2 : (red - green) / delta + 4);
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
  var _parseToHsla = parseToHsla(color),
    _parseToHsla2 = _slicedToArray(_parseToHsla, 4),
    h = _parseToHsla2[0],
    s = _parseToHsla2[1],
    l = _parseToHsla2[2],
    a = _parseToHsla2[3];
  return hsla(h + degrees, s, l, a);
}

/**
 * Darkens using lightness. This is equivalent to subtracting the lightness
 * from the L in HSL.
 *
 * @param amount The amount to darken, given as a decimal between 0 and 1
 */
function darken(color, amount) {
  var _parseToHsla = parseToHsla(color),
    _parseToHsla2 = _slicedToArray(_parseToHsla, 4),
    hue = _parseToHsla2[0],
    saturation = _parseToHsla2[1],
    lightness = _parseToHsla2[2],
    alpha = _parseToHsla2[3];
  return hsla(hue, saturation, lightness - amount, alpha);
}

/**
 * Desaturates the input color by the given amount via subtracting from the `s`
 * in `hsla`.
 *
 * @param amount The amount to desaturate, given as a decimal between 0 and 1
 */
function desaturate(color, amount) {
  var _parseToHsla = parseToHsla(color),
    _parseToHsla2 = _slicedToArray(_parseToHsla, 4),
    h = _parseToHsla2[0],
    s = _parseToHsla2[1],
    l = _parseToHsla2[2],
    a = _parseToHsla2[3];
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
    var channel = x / 255;
    return channel <= 0.04045 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4);
  }
  var _parseToRgba = parseToRgba(color),
    _parseToRgba2 = _slicedToArray(_parseToRgba, 3),
    r = _parseToRgba2[0],
    g = _parseToRgba2[1],
    b = _parseToRgba2[2];
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}

// taken from:
// https://github.com/styled-components/polished/blob/0764c982551b487469043acb56281b0358b3107b/src/color/getContrast.js

/**
 * Returns the contrast ratio between two colors based on
 * [W3's recommended equation for calculating contrast](http://www.w3.org/TR/WCAG20/#contrast-ratiodef).
 */
function getContrast(color1, color2) {
  var luminance1 = getLuminance(color1);
  var luminance2 = getLuminance(color2);
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
  var normalize = function normalize(n, index) {
    return (
      // 3rd index is alpha channel which is already normalized
      index === 3 ? n : n / 255
    );
  };
  var _parseToRgba$map = parseToRgba(color1).map(normalize),
    _parseToRgba$map2 = _slicedToArray(_parseToRgba$map, 4),
    r1 = _parseToRgba$map2[0],
    g1 = _parseToRgba$map2[1],
    b1 = _parseToRgba$map2[2],
    a1 = _parseToRgba$map2[3];
  var _parseToRgba$map3 = parseToRgba(color2).map(normalize),
    _parseToRgba$map4 = _slicedToArray(_parseToRgba$map3, 4),
    r2 = _parseToRgba$map4[0],
    g2 = _parseToRgba$map4[1],
    b2 = _parseToRgba$map4[2],
    a2 = _parseToRgba$map4[3];

  // The formula is copied from the original Sass implementation:
  // http://sass-lang.com/documentation/Sass/Script/Functions.html#mix-instance_method
  var alphaDelta = a2 - a1;
  var normalizedWeight = weight * 2 - 1;
  var combinedWeight = normalizedWeight * alphaDelta === -1 ? normalizedWeight : normalizedWeight + alphaDelta / (1 + normalizedWeight * alphaDelta);
  var weight2 = (combinedWeight + 1) / 2;
  var weight1 = 1 - weight2;
  var r = (r1 * weight1 + r2 * weight2) * 255;
  var g = (g1 * weight1 + g2 * weight2) * 255;
  var b = (b1 * weight1 + b2 * weight2) * 255;
  var a = a2 * weight + a1 * (1 - weight);
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
  return function (n) {
    var lastIndex = colors.length - 1;
    var lowIndex = guard(0, lastIndex, Math.floor(n * lastIndex));
    var highIndex = guard(0, lastIndex, Math.ceil(n * lastIndex));
    var color1 = colors[lowIndex];
    var color2 = colors[highIndex];
    var unit = 1 / lastIndex;
    var weight = (n - unit * lowIndex) / unit;
    return mix(color1, color2, weight);
  };
}

var guidelines = {
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
  var standard = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 'aa';
  var background = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : '#fff';
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
  var _parseToRgba = parseToRgba(color),
    _parseToRgba2 = _slicedToArray(_parseToRgba, 4),
    r = _parseToRgba2[0],
    g = _parseToRgba2[1],
    b = _parseToRgba2[2],
    a = _parseToRgba2[3];
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
  var _parseToRgba = parseToRgba(color),
    _parseToRgba2 = _slicedToArray(_parseToRgba, 4),
    r = _parseToRgba2[0],
    g = _parseToRgba2[1],
    b = _parseToRgba2[2],
    a = _parseToRgba2[3];
  var hex = function hex(x) {
    var h = guard(0, 255, x).toString(16);
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
  return rgba.apply(void 0, _toConsumableArray(parseToRgba(color)));
}

/**
 * Takes in any color and returns it as an hsla string.
 */
function toHsla(color) {
  return hsla.apply(void 0, _toConsumableArray(parseToHsla(color)));
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
//# sourceMappingURL=index.main.cjs.js.map
