"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.logConfig = logConfig;

var _chalk = _interopRequireDefault(require("chalk"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/* eslint-disable no-console */
function logConfig(caption, config) {
  console.log(_chalk.default.cyan(caption));
  console.dir(config, {
    depth: null
  });
}