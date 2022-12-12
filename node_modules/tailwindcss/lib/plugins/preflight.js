"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = _default;

var _fs = _interopRequireDefault(require("fs"));

var _postcss = _interopRequireDefault(require("postcss"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _default() {
  return function ({
    addBase
  }) {
    const normalizeStyles = _postcss.default.parse(_fs.default.readFileSync(require.resolve('normalize.css'), 'utf8'));

    const preflightStyles = _postcss.default.parse(_fs.default.readFileSync(`${__dirname}/css/preflight.css`, 'utf8'));

    addBase([...normalizeStyles.nodes, ...preflightStyles.nodes]);
  };
}