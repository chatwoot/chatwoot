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
    theme,
    variants,
    e
  }) {
    const utilities = _lodash.default.fromPairs(_lodash.default.map(theme('letterSpacing'), (value, modifier) => {
      return [`.${e((0, _prefixNegativeModifiers.default)('tracking', modifier))}`, {
        'letter-spacing': value
      }];
    }));

    addUtilities(utilities, variants('letterSpacing'));
  };
}