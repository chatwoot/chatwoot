"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.toRgba = toRgba;
exports.default = withAlphaVariable;

var _color = _interopRequireDefault(require("color"));

var _lodash = _interopRequireDefault(require("lodash"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function hasAlpha(color) {
  return color.startsWith('rgba(') || color.startsWith('hsla(') || color.startsWith('#') && color.length === 9 || color.startsWith('#') && color.length === 5;
}

function toRgba(color) {
  const [r, g, b, a] = (0, _color.default)(color).rgb().array();
  return [r, g, b, a === undefined && hasAlpha(color) ? 1 : a];
}

function withAlphaVariable({
  color,
  property,
  variable
}) {
  if (_lodash.default.isFunction(color)) {
    return {
      [variable]: '1',
      [property]: color({
        opacityVariable: variable
      })
    };
  }

  try {
    const [r, g, b, a] = toRgba(color);

    if (a !== undefined) {
      return {
        [property]: color
      };
    }

    return {
      [variable]: '1',
      [property]: [color, `rgba(${r}, ${g}, ${b}, var(${variable}))`]
    };
  } catch (error) {
    return {
      [property]: color
    };
  }
}