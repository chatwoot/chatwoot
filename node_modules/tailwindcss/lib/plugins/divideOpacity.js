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
    if (target('divideOpacity') === 'ie11') {
      return;
    }

    const utilities = _lodash.default.fromPairs(_lodash.default.map(theme('divideOpacity'), (value, modifier) => {
      return [`.${e(`divide-opacity-${modifier}`)} > :not(template) ~ :not(template)`, {
        '--divide-opacity': value
      }];
    }));

    addUtilities(utilities, variants('divideOpacity'));
  };
}