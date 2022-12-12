/* eslint-disable no-console */
import npmLog from 'npmlog';
import prettyTime from 'pretty-hrtime';
import chalk from 'chalk';
export var colors = {
  pink: chalk.hex('F1618C'),
  purple: chalk.hex('B57EE5'),
  orange: chalk.hex('F3AD38'),
  green: chalk.hex('A2E05E'),
  blue: chalk.hex('6DABF5'),
  red: chalk.hex('F16161'),
  gray: chalk.gray
};
export var logger = {
  verbose: function (message) {
    return npmLog.verbose('', message);
  },
  info: function (message) {
    return npmLog.info('', message);
  },
  plain: function (message) {
    return console.log(message);
  },
  line: function (count = 1) {
    return console.log(`${Array(count - 1).fill('\n')}`);
  },
  warn: function (message) {
    return npmLog.warn('', message);
  },
  error: function (message) {
    return npmLog.error('', message);
  },
  trace: function ({
    message: message,
    time: time
  }) {
    return npmLog.info('', `${message} (${colors.purple(prettyTime(time))})`);
  },
  setLevel: function (level = 'info') {
    npmLog.level = level;
  }
};
export { npmLog as instance };
var logged = new Set();
export var once = function (type) {
  return function (message) {
    if (logged.has(message)) return undefined;
    logged.add(message);
    return logger[type](message);
  };
};

once.clear = function () {
  return logged.clear();
};

once.verbose = once('verbose');
once.info = once('info');
once.warn = once('warn');
once.error = once('error');