"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _lodash = _interopRequireDefault(require("lodash"));

var _flattenColorPalette = _interopRequireDefault(require("../util/flattenColorPalette"));

var _toColorValue = _interopRequireDefault(require("../util/toColorValue"));

var _withAlphaVariable = _interopRequireDefault(require("../util/withAlphaVariable"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default() {
  return function ({
    addUtilities,
    e,
    theme,
    variants,
    target,
    corePlugins
  }) {
    const colors = (0, _flattenColorPalette.default)(theme('divideColor'));

    const getProperties = value => {
      if (target('divideColor') === 'ie11') {
        return {
          'border-color': (0, _toColorValue.default)(value)
        };
      }

      if (corePlugins('divideOpacity')) {
        return (0, _withAlphaVariable.default)({
          color: value,
          property: 'border-color',
          variable: '--divide-opacity'
        });
      }

      return {
        'border-color': (0, _toColorValue.default)(value)
      };
    };

    const utilities = _lodash.default.fromPairs(_lodash.default.map(_lodash.default.omit(colors, 'default'), (value, modifier) => {
      return [`.${e(`divide-${modifier}`)} > :not(template) ~ :not(template)`, getProperties(value)];
    }));

    addUtilities(utilities, variants('divideColor'));
  };
}