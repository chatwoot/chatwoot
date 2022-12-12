"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = flattenColorPalette;

var _lodash = _interopRequireDefault(require("lodash"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function flattenColorPalette(colors) {
  const result = (0, _lodash.default)(colors).flatMap((color, name) => {
    if (_lodash.default.isFunction(color) || !_lodash.default.isObject(color)) {
      return [[name, color]];
    }

    return _lodash.default.map(color, (value, key) => {
      const suffix = key === 'default' ? '' : `-${key}`;
      return [`${name}${suffix}`, value];
    });
  }).fromPairs().value();
  return result;
}