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
    addUtilities(_lodash.default.fromPairs(_lodash.default.map(theme('flexGrow'), (value, modifier) => {
      const className = modifier === 'default' ? 'flex-grow' : `flex-grow-${modifier}`;
      return [`.${e(className)}`, {
        'flex-grow': value
      }];
    })), variants('flexGrow'));
  };
}