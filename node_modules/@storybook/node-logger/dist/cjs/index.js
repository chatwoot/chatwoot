"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.colors = void 0;
Object.defineProperty(exports, "instance", {
  enumerable: true,
  get: function () {
    return _npmlog.default;
  }
});
exports.once = exports.logger = void 0;

var _npmlog = _interopRequireDefault(require("npmlog"));

var _prettyHrtime = _interopRequireDefault(require("pretty-hrtime"));

var _chalk = _interopRequireDefault(require("chalk"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/* eslint-disable no-console */
var colors = {
  pink: _chalk.default.hex('F1618C'),
  purple: _chalk.default.hex('B57EE5'),
  orange: _chalk.default.hex('F3AD38'),
  green: _chalk.default.hex('A2E05E'),
  blue: _chalk.default.hex('6DABF5'),
  red: _chalk.default.hex('F16161'),
  gray: _chalk.default.gray
};
exports.colors = colors;
var logger = {
  verbose: function (message) {
    return _npmlog.default.verbose('', message);
  },
  info: function (message) {
    return _npmlog.default.info('', message);
  },
  plain: function (message) {
    return console.log(message);
  },
  line: function (count = 1) {
    return console.log(`${Array(count - 1).fill('\n')}`);
  },
  warn: function (message) {
    return _npmlog.default.warn('', message);
  },
  error: function (message) {
    return _npmlog.default.error('', message);
  },
  trace: function ({
    message: message,
    time: time
  }) {
    return _npmlog.default.info('', `${message} (${colors.purple((0, _prettyHrtime.default)(time))})`);
  },
  setLevel: function (level = 'info') {
    _npmlog.default.level = level;
  }
};
exports.logger = logger;
var logged = new Set();

var once = function (type) {
  return function (message) {
    if (logged.has(message)) return undefined;
    logged.add(message);
    return logger[type](message);
  };
};

exports.once = once;

once.clear = function () {
  return logged.clear();
};

once.verbose = once('verbose');
once.info = once('info');
once.warn = once('warn');
once.error = once('error');