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
    const generators = [(size, modifier) => ({
      [`.${e(`p-${modifier}`)}`]: {
        padding: `${size}`
      }
    }), (size, modifier) => ({
      [`.${e(`py-${modifier}`)}`]: {
        'padding-top': `${size}`,
        'padding-bottom': `${size}`
      },
      [`.${e(`px-${modifier}`)}`]: {
        'padding-left': `${size}`,
        'padding-right': `${size}`
      }
    }), (size, modifier) => ({
      [`.${e(`pt-${modifier}`)}`]: {
        'padding-top': `${size}`
      },
      [`.${e(`pr-${modifier}`)}`]: {
        'padding-right': `${size}`
      },
      [`.${e(`pb-${modifier}`)}`]: {
        'padding-bottom': `${size}`
      },
      [`.${e(`pl-${modifier}`)}`]: {
        'padding-left': `${size}`
      }
    })];

    const utilities = _lodash.default.flatMap(generators, generator => {
      return _lodash.default.flatMap(theme('padding'), generator);
    });

    addUtilities(utilities, variants('padding'));
  };
}