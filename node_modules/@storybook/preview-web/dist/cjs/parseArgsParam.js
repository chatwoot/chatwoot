"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.object.freeze.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.parseArgsParam = void 0;

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/es.regexp.to-string.js");

require("core-js/modules/es.string.starts-with.js");

require("core-js/modules/es.string.ends-with.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.string.match.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.number.constructor.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.string.split.js");

require("core-js/modules/es.string.replace.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.object.assign.js");

var _qs = _interopRequireDefault(require("qs"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _clientLogger = require("@storybook/client-logger");

var _isPlainObject = _interopRequireDefault(require("lodash/isPlainObject"));

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

// Keep this in sync with validateArgs in router/src/utils.ts
var VALIDATION_REGEXP = /^[a-zA-Z0-9 _-]*$/;
var NUMBER_REGEXP = /^-?[0-9]+(\.[0-9]+)?$/;
var HEX_REGEXP = /^#([a-f0-9]{3,4}|[a-f0-9]{6}|[a-f0-9]{8})$/i;
var COLOR_REGEXP = /^(rgba?|hsla?)\(([0-9]{1,3}),\s?([0-9]{1,3})%?,\s?([0-9]{1,3})%?,?\s?([0-9](\.[0-9]{1,2})?)?\)$/i;

var validateArgs = function validateArgs() {
  var key = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';
  var value = arguments.length > 1 ? arguments[1] : undefined;
  if (key === null) return false;
  if (key === '' || !VALIDATION_REGEXP.test(key)) return false;
  if (value === null || value === undefined) return true; // encoded as `!null` or `!undefined`

  if (value instanceof Date) return true; // encoded as modified ISO string

  if (typeof value === 'number' || typeof value === 'boolean') return true;

  if (typeof value === 'string') {
    return VALIDATION_REGEXP.test(value) || NUMBER_REGEXP.test(value) || HEX_REGEXP.test(value) || COLOR_REGEXP.test(value);
  }

  if (Array.isArray(value)) return value.every(function (v) {
    return validateArgs(key, v);
  });
  if ((0, _isPlainObject.default)(value)) return Object.entries(value).every(function (_ref) {
    var _ref2 = _slicedToArray(_ref, 2),
        k = _ref2[0],
        v = _ref2[1];

    return validateArgs(k, v);
  });
  return false;
};

var QS_OPTIONS = {
  delimiter: ';',
  // we're parsing a single query param
  allowDots: true,
  // objects are encoded using dot notation
  allowSparse: true,
  // arrays will be merged on top of their initial value
  decoder: function (_decoder) {
    function decoder(_x, _x2, _x3, _x4) {
      return _decoder.apply(this, arguments);
    }

    decoder.toString = function () {
      return _decoder.toString();
    };

    return decoder;
  }(function (str, defaultDecoder, charset, type) {
    if (type === 'value' && str.startsWith('!')) {
      if (str === '!undefined') return undefined;
      if (str === '!null') return null;
      if (str.startsWith('!date(') && str.endsWith(')')) return new Date(str.slice(6, -1));
      if (str.startsWith('!hex(') && str.endsWith(')')) return "#".concat(str.slice(5, -1));
      var color = str.slice(1).match(COLOR_REGEXP);

      if (color) {
        if (str.startsWith('!rgba')) return "".concat(color[1], "(").concat(color[2], ", ").concat(color[3], ", ").concat(color[4], ", ").concat(color[5], ")");
        if (str.startsWith('!hsla')) return "".concat(color[1], "(").concat(color[2], ", ").concat(color[3], "%, ").concat(color[4], "%, ").concat(color[5], ")");
        return str.startsWith('!rgb') ? "".concat(color[1], "(").concat(color[2], ", ").concat(color[3], ", ").concat(color[4], ")") : "".concat(color[1], "(").concat(color[2], ", ").concat(color[3], "%, ").concat(color[4], "%)");
      }
    }

    if (type === 'value' && NUMBER_REGEXP.test(str)) return Number(str);
    return defaultDecoder(str, defaultDecoder, charset);
  })
};

var parseArgsParam = function parseArgsParam(argsString) {
  var parts = argsString.split(';').map(function (part) {
    return part.replace('=', '~').replace(':', '=');
  });
  return Object.entries(_qs.default.parse(parts.join(';'), QS_OPTIONS)).reduce(function (acc, _ref3) {
    var _ref4 = _slicedToArray(_ref3, 2),
        key = _ref4[0],
        value = _ref4[1];

    if (validateArgs(key, value)) return Object.assign(acc, _defineProperty({}, key, value));

    _clientLogger.once.warn((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n      Omitted potentially unsafe URL args.\n\n      More info: https://storybook.js.org/docs/react/writing-stories/args#setting-args-through-the-url\n    "]))));

    return acc;
  }, {});
};

exports.parseArgsParam = parseArgsParam;