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
    const utilities = _lodash.default.fromPairs(_lodash.default.map(theme('fontWeight'), (value, modifier) => {
      return [`.${e(`font-${modifier}`)}`, {
        'font-weight': value
      }];
    }));

    addUtilities(utilities, variants('fontWeight'));
  };
}