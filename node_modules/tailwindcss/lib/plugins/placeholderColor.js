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
    const colors = (0, _flattenColorPalette.default)(theme('placeholderColor'));

    const getProperties = value => {
      if (target('placeholderColor') === 'ie11') {
        return {
          color: (0, _toColorValue.default)(value)
        };
      }

      if (corePlugins('placeholderOpacity')) {
        return (0, _withAlphaVariable.default)({
          color: value,
          property: 'color',
          variable: '--placeholder-opacity'
        });
      }

      return {
        color: (0, _toColorValue.default)(value)
      };
    };

    const utilities = _lodash.default.fromPairs(_lodash.default.map(colors, (value, modifier) => {
      return [`.${e(`placeholder-${modifier}`)}::placeholder`, getProperties(value)];
    }));

    addUtilities(utilities, variants('placeholderColor'));
  };
}