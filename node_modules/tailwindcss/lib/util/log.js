"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = void 0;

var _chalk = _interopRequireDefault(require("chalk"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var _default = {
  info(messages) {
    console.warn('');
    messages.forEach(message => {
      console.warn(_chalk.default.bold.cyan('info'), '-', message);
    });
  },

  warn(messages) {
    console.warn('');
    messages.forEach(message => {
      console.warn(_chalk.default.bold.yellow('warn'), '-', message);
    });
  },

  risk(messages) {
    console.warn('');
    messages.forEach(message => {
      console.warn(_chalk.default.bold.magenta('risk'), '-', message);
    });
  }

};
exports.default = _default;