"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _lodash = _interopRequireDefault(require("lodash"));

var _prefixNegativeModifiers = _interopRequireDefault(require("../util/prefixNegativeModifiers"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default() {
  return function ({
    addUtilities,
    e,
    theme,
    variants
  }) {
    const generators = [(size, modifier) => ({
      [`.${e((0, _prefixNegativeModifiers.default)('m', modifier))}`]: {
        margin: `${size}`
      }
    }), (size, modifier) => ({
      [`.${e((0, _prefixNegativeModifiers.default)('my', modifier))}`]: {
        'margin-top': `${size}`,
        'margin-bottom': `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('mx', modifier))}`]: {
        'margin-left': `${size}`,
        'margin-right': `${size}`
      }
    }), (size, modifier) => ({
      [`.${e((0, _prefixNegativeModifiers.default)('mt', modifier))}`]: {
        'margin-top': `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('mr', modifier))}`]: {
        'margin-right': `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('mb', modifier))}`]: {
        'margin-bottom': `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('ml', modifier))}`]: {
        'margin-left': `${size}`
      }
    })];

    const utilities = _lodash.default.flatMap(generators, generator => {
      return _lodash.default.flatMap(theme('margin'), generator);
    });

    addUtilities(utilities, variants('margin'));
  };
}