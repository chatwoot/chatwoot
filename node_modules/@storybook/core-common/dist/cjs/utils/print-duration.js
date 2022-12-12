"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.printDuration = void 0;

var _prettyHrtime = _interopRequireDefault(require("pretty-hrtime"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var printDuration = function (startTime) {
  return (0, _prettyHrtime.default)(process.hrtime(startTime)).replace(' ms', ' milliseconds').replace(' s', ' seconds').replace(' m', ' minutes');
};

exports.printDuration = printDuration;