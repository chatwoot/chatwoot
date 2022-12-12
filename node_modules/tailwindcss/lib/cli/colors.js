"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.bold = bold;
exports.info = info;
exports.error = error;
exports.command = command;
exports.file = file;

var _chalk = _interopRequireDefault(require("chalk"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * Applies colors to emphasize
 *
 * @param {...string} msgs
 */
function bold(...msgs) {
  return _chalk.default.bold(...msgs);
}
/**
 * Applies colors to inform
 *
 * @param {...string} msgs
 */


function info(...msgs) {
  return _chalk.default.bold.cyan(...msgs);
}
/**
 * Applies colors to signify error
 *
 * @param {...string} msgs
 */


function error(...msgs) {
  return _chalk.default.bold.red(...msgs);
}
/**
 * Applies colors to represent a command
 *
 * @param {...string} msgs
 */


function command(...msgs) {
  return _chalk.default.bold.magenta(...msgs);
}
/**
 * Applies colors to represent a file
 *
 * @param {...string} msgs
 */


function file(...msgs) {
  return _chalk.default.bold.magenta(...msgs);
}