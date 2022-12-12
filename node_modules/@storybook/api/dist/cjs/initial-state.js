"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

require("core-js/modules/es.object.to-string.js");

var _merge = _interopRequireDefault(require("./lib/merge"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// Returns the initialState of the app
var main = function main() {
  for (var _len = arguments.length, additions = new Array(_len), _key = 0; _key < _len; _key++) {
    additions[_key] = arguments[_key];
  }

  return additions.reduce(function (acc, item) {
    return (0, _merge.default)(acc, item);
  }, {});
};

var _default = main;
exports.default = _default;