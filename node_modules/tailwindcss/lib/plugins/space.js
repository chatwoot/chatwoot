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
    variants,
    target
  }) {
    if (target('space') === 'ie11') {
      const generators = [(size, modifier) => ({
        [`.${e((0, _prefixNegativeModifiers.default)('space-y', modifier))} > :not(template) ~ :not(template)`]: {
          'margin-top': size
        },
        [`.${e((0, _prefixNegativeModifiers.default)('space-x', modifier))} > :not(template) ~ :not(template)`]: {
          'margin-left': size
        }
      })];

      const utilities = _lodash.default.flatMap(generators, generator => {
        return _lodash.default.flatMap(theme('space'), generator);
      });

      addUtilities(utilities, variants('space'));
      return;
    }

    const generators = [(size, modifier) => ({
      [`.${e((0, _prefixNegativeModifiers.default)('space-y', modifier))} > :not(template) ~ :not(template)`]: {
        '--space-y-reverse': '0',
        'margin-top': `calc(${size === '0' ? '0px' : size} * calc(1 - var(--space-y-reverse)))`,
        'margin-bottom': `calc(${size === '0' ? '0px' : size} * var(--space-y-reverse))`
      },
      [`.${e((0, _prefixNegativeModifiers.default)('space-x', modifier))} > :not(template) ~ :not(template)`]: {
        '--space-x-reverse': '0',
        'margin-right': `calc(${size === '0' ? '0px' : size} * var(--space-x-reverse))`,
        'margin-left': `calc(${size === '0' ? '0px' : size} * calc(1 - var(--space-x-reverse)))`
      }
    })];

    const utilities = _lodash.default.flatMap(generators, generator => {
      return [..._lodash.default.flatMap(theme('space'), generator), {
        '.space-y-reverse > :not(template) ~ :not(template)': {
          '--space-y-reverse': '1'
        },
        '.space-x-reverse > :not(template) ~ :not(template)': {
          '--space-x-reverse': '1'
        }
      }];
    });

    addUtilities(utilities, variants('space'));
  };
}