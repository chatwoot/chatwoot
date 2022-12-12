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
    const utilities = _lodash.default.fromPairs(_lodash.default.map(theme('zIndex'), (value, modifier) => {
      return [`.${e((0, _prefixNegativeModifiers.default)('z', modifier))}`, {
        'z-index': value
      }];
    }));

    addUtilities(utilities, variants('zIndex'));
  };
}