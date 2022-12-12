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
    const generators = [(value, modifier) => ({
      [`.${e(`border${modifier}`)}`]: {
        borderWidth: `${value}`
      }
    }), (value, modifier) => ({
      [`.${e(`border-t${modifier}`)}`]: {
        borderTopWidth: `${value}`
      },
      [`.${e(`border-r${modifier}`)}`]: {
        borderRightWidth: `${value}`
      },
      [`.${e(`border-b${modifier}`)}`]: {
        borderBottomWidth: `${value}`
      },
      [`.${e(`border-l${modifier}`)}`]: {
        borderLeftWidth: `${value}`
      }
    })];

    const utilities = _lodash.default.flatMap(generators, generator => {
      return _lodash.default.flatMap(theme('borderWidth'), (value, modifier) => {
        return generator(value, modifier === 'default' ? '' : `-${modifier}`);
      });
    });

    addUtilities(utilities, variants('borderWidth'));
  };
}