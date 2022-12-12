"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.safeResolveFrom = exports.safeResolve = void 0;

var _resolveFrom = _interopRequireDefault(require("resolve-from"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var safeResolveFrom = function (path, file) {
  try {
    return (0, _resolveFrom.default)(path, file);
  } catch (e) {
    return undefined;
  }
};

exports.safeResolveFrom = safeResolveFrom;

var safeResolve = function (file) {
  try {
    return require.resolve(file);
  } catch (e) {
    return undefined;
  }
};

exports.safeResolve = safeResolve;