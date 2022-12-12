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
    const keyframesConfig = theme('keyframes');

    const keyframesStyles = _lodash.default.fromPairs(_lodash.default.toPairs(keyframesConfig).map(([name, keyframes]) => {
      return [`@keyframes ${name}`, keyframes];
    }));

    addUtilities(keyframesStyles, {
      respectImportant: false
    });
    const animationConfig = theme('animation');

    const utilities = _lodash.default.fromPairs(_lodash.default.toPairs(animationConfig).map(([suffix, animation]) => {
      return [`.${e(`animate-${suffix}`)}`, {
        animation
      }];
    }));

    addUtilities(utilities, variants('animation'));
  };
}