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
    if (target('placeholderOpacity') === 'ie11') {
      return;
    }

    const utilities = _lodash.default.fromPairs(_lodash.default.map(theme('placeholderOpacity'), (value, modifier) => {
      return [`.${e(`placeholder-opacity-${modifier}`)}::placeholder`, {
        '--placeholder-opacity': value
      }];
    }));

    addUtilities(utilities, variants('placeholderOpacity'));
  };
}