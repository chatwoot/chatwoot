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
    if (target('scale') === 'ie11') {
      (0, _createUtilityPlugin.default)('scale', [['scale', ['transform'], value => `scale(${value})`], ['scale-x', ['transform'], value => `scaleX(${value})`], ['scale-y', ['transform'], value => `scaleY(${value})`]])({
        target,
        ...args
      });
      return;
    }

    (0, _createUtilityPlugin.default)('scale', [['scale', ['--transform-scale-x', '--transform-scale-y']], ['scale-x', ['--transform-scale-x']], ['scale-y', ['--transform-scale-y']]])({
      target,
      ...args
    });
  };
}