"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _createUtilityPlugin = _interopRequireDefault(require("../util/createUtilityPlugin"));

var _featureFlags = require("../featureFlags");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default() {
  return function ({
    target,
    config,
    ...args
  }) {
    if (target('gap') === 'ie11') {
      return;
    }

    if ((0, _featureFlags.flagEnabled)(config(), 'removeDeprecatedGapUtilities')) {
      (0, _createUtilityPlugin.default)('gap', [['gap', ['gridGap', 'gap']], ['gap-x', ['gridColumnGap', 'columnGap']], ['gap-y', ['gridRowGap', 'rowGap']]])({
        target,
        config,
        ...args
      });
    } else {
      (0, _createUtilityPlugin.default)('gap', [['gap', ['gridGap', 'gap']], ['col-gap', ['gridColumnGap', 'columnGap']], ['gap-x', ['gridColumnGap', 'columnGap']], ['row-gap', ['gridRowGap', 'rowGap']], ['gap-y', ['gridRowGap', 'rowGap']]])({
        target,
        config,
        ...args
      });
    }
  };
}