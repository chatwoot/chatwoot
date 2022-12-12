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
      [`.${e((0, _prefixNegativeModifiers.default)('inset', modifier))}`]: {
        top: `${size}`,
        right: `${size}`,
        bottom: `${size}`,
        left: `${size}`
      }
    }), (size, modifier) => ({
      [`.${e((0, _prefixNegativeModifiers.default)('inset-y', modifier))}`]: {
        top: `${size}`,
        bottom: `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('inset-x', modifier))}`]: {
        right: `${size}`,
        left: `${size}`
      }
    }), (size, modifier) => ({
      [`.${e((0, _prefixNegativeModifiers.default)('top', modifier))}`]: {
        top: `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('right', modifier))}`]: {
        right: `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('bottom', modifier))}`]: {
        bottom: `${size}`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('left', modifier))}`]: {
        left: `${size}`
      }
    })];

    const utilities = _lodash.default.flatMap(generators, generator => {
      return _lodash.default.flatMap(theme('inset'), generator);
    });

    addUtilities(utilities, variants('inset'));
  };
}