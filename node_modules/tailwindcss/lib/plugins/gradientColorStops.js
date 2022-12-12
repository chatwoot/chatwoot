"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _lodash = _interopRequireDefault(require("lodash"));

var _flattenColorPalette = _interopRequireDefault(require("../util/flattenColorPalette"));

var _toColorValue = _interopRequireDefault(require("../util/toColorValue"));

var _withAlphaVariable = require("../util/withAlphaVariable");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default() {
  return function ({
    addUtilities,
    e,
    theme,
    variants,
    target
  }) {
    if (target('gradientColorStops') === 'ie11') {
      return;
    }

    const colors = (0, _flattenColorPalette.default)(theme('gradientColorStops'));
    const utilities = (0, _lodash.default)(colors).map((value, modifier) => {
      const transparentTo = (() => {
        if (_lodash.default.isFunction(value)) {
          return value({
            opacityValue: 0
          });
        }

        try {
          const [r, g, b] = (0, _withAlphaVariable.toRgba)(value);
          return `rgba(${r}, ${g}, ${b}, 0)`;
        } catch (_error) {
          return `rgba(255, 255, 255, 0)`;
        }
      })();

      return [[`.${e(`from-${modifier}`)}`, {
        '--gradient-from-color': (0, _toColorValue.default)(value, 'from'),
        '--gradient-color-stops': `var(--gradient-from-color), var(--gradient-to-color, ${transparentTo})`
      }], [`.${e(`via-${modifier}`)}`, {
        '--gradient-via-color': (0, _toColorValue.default)(value, 'via'),
        '--gradient-color-stops': `var(--gradient-from-color), var(--gradient-via-color), var(--gradient-to-color, ${transparentTo})`
      }], [`.${e(`to-${modifier}`)}`, {
        '--gradient-to-color': (0, _toColorValue.default)(value, 'to')
      }]];
    }).unzip().flatten().fromPairs().value();
    addUtilities(utilities, variants('gradientColorStops'));
  };
}