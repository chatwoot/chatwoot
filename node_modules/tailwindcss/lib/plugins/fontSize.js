"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _lodash = _interopRequireDefault(require("lodash"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default() {
  return function ({
    addUtilities,
    e,
    theme,
    variants
  }) {
    const utilities = _lodash.default.fromPairs(_lodash.default.map(theme('fontSize'), (value, modifier) => {
      const [fontSize, options] = Array.isArray(value) ? value : [value];
      const {
        lineHeight,
        letterSpacing
      } = _lodash.default.isPlainObject(options) ? options : {
        lineHeight: options
      };
      return [`.${e(`text-${modifier}`)}`, {
        'font-size': fontSize,
        ...(lineHeight === undefined ? {} : {
          'line-height': lineHeight
        }),
        ...(letterSpacing === undefined ? {} : {
          'letter-spacing': letterSpacing
        })
      }];
    }));

    addUtilities(utilities, variants('fontSize'));
  };
}