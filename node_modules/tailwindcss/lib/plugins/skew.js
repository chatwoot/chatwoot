"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _createUtilityPlugin = _interopRequireDefault(require("../util/createUtilityPlugin"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default() {
  return function ({
    target,
    ...args
  }) {
    if (target('skew') === 'ie11') {
      (0, _createUtilityPlugin.default)('skew', [['skew-x', ['transform'], value => `skewX(${value})`], ['skew-y', ['transform'], value => `skewY(${value})`]])({
        target,
        ...args
      });
      return;
    }

    (0, _createUtilityPlugin.default)('skew', [['skew-x', ['--transform-skew-x']], ['skew-y', ['--transform-skew-y']]])({
      target,
      ...args
    });
  };
}