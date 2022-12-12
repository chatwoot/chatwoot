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
    variants,
    target
  }) {
    if (target('divideWidth') === 'ie11') {
      const generators = [(size, modifier) => ({
        [`.${e(`divide-y${modifier}`)} > :not(template) ~ :not(template)`]: {
          'border-top-width': size
        },
        [`.${e(`divide-x${modifier}`)} > :not(template) ~ :not(template)`]: {
          'border-left-width': size
        }
      })];

      const utilities = _lodash.default.flatMap(generators, generator => {
        return _lodash.default.flatMap(theme('divideWidth'), (value, modifier) => {
          return generator(value, modifier === 'default' ? '' : `-${modifier}`);
        });
      });

      addUtilities(utilities, variants('divideWidth'));
      return;
    }

    const generators = [(size, modifier) => ({
      [`.${e(`divide-y${modifier}`)} > :not(template) ~ :not(template)`]: {
        '--divide-y-reverse': '0',
        'border-top-width': `calc(${size === '0' ? '0px' : size} * calc(1 - var(--divide-y-reverse)))`,
        'border-bottom-width': `calc(${size === '0' ? '0px' : size} * var(--divide-y-reverse))`
      },
      [`.${e(`divide-x${modifier}`)} > :not(template) ~ :not(template)`]: {
        '--divide-x-reverse': '0',
        'border-right-width': `calc(${size === '0' ? '0px' : size} * var(--divide-x-reverse))`,
        'border-left-width': `calc(${size === '0' ? '0px' : size} * calc(1 - var(--divide-x-reverse)))`
      }
    })];

    const utilities = _lodash.default.flatMap(generators, generator => {
      return [..._lodash.default.flatMap(theme('divideWidth'), (value, modifier) => {
        return generator(value, modifier === 'default' ? '' : `-${modifier}`);
      }), {
        '.divide-y-reverse > :not(template) ~ :not(template)': {
          '--divide-y-reverse': '1'
        },
        '.divide-x-reverse > :not(template) ~ :not(template)': {
          '--divide-x-reverse': '1'
        }
      }];
    });

    addUtilities(utilities, variants('divideWidth'));
  };
}