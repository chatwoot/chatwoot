"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _defaultConfig = _interopRequireDefault(require("../../defaultConfig"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _default = {
  dark: 'media',
  variants: {
    backgroundColor: [..._defaultConfig.default.variants.backgroundColor, 'dark'],
    gradientColorStops: [..._defaultConfig.default.variants.gradientColorStops, 'dark'],
    borderColor: [..._defaultConfig.default.variants.borderColor, 'dark'],
    divideColor: [..._defaultConfig.default.variants.divideColor, 'dark'],
    placeholderColor: [..._defaultConfig.default.variants.placeholderColor, 'dark'],
    textColor: [..._defaultConfig.default.variants.textColor, 'dark']
  }
};
exports.default = _default;