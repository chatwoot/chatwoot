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
    const utilities = _lodash.default.fromPairs(_lodash.default.map(theme('boxShadow'), (value, modifier) => {
      const className = modifier === 'default' ? 'shadow' : `${e((0, _prefixNegativeModifiers.default)('shadow', modifier))}`;
      return [`.${className}`, {
        'box-shadow': value
      }];
    }));

    addUtilities(utilities, variants('boxShadow'));
  };
}