'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _jestWatcher() {
  const data = require('jest-watcher');

  _jestWatcher = function () {
    return data;
  };

  return data;
}

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }
  return obj;
}

class QuitPlugin extends _jestWatcher().BaseWatchPlugin {
  constructor(options) {
    super(options);

    _defineProperty(this, 'isInternal', void 0);

    this.isInternal = true;
  }

  async run() {
    if (typeof this._stdin.setRawMode === 'function') {
      this._stdin.setRawMode(false);
    }

    this._stdout.write('\n');

    process.exit(0);
  }

  getUsageInfo() {
    return {
      key: 'q',
      prompt: 'quit watch mode'
    };
  }
}

var _default = QuitPlugin;
exports.default = _default;
