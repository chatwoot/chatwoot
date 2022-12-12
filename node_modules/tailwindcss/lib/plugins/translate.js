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
    if (target('translate') === 'ie11') {
      (0, _createUtilityPlugin.default)('translate', [['translate-x', ['transform'], value => `translateX(${value})`], ['translate-y', ['transform'], value => `translateY(${value})`]])({
        target,
        ...args
      });
      return;
    }

    (0, _createUtilityPlugin.default)('translate', [['translate-x', ['--transform-translate-x']], ['translate-y', ['--transform-translate-y']]])({
      target,
      ...args
    });
  };
}