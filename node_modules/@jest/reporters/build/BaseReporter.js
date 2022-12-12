'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
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

const {remove: preRunMessageRemove} = _jestUtil().preRunMessage;

class BaseReporter {
  constructor() {
    _defineProperty(this, '_error', void 0);
  }

  log(message) {
    process.stderr.write(message + '\n');
  }

  onRunStart(_results, _options) {
    preRunMessageRemove(process.stderr);
  }

  onTestCaseResult(_test, _testCaseResult) {}

  onTestResult(_test, _testResult, _results) {}

  onTestStart(_test) {}

  onRunComplete(_contexts, _aggregatedResults) {}

  _setError(error) {
    this._error = error;
  } // Return an error that occurred during reporting. This error will
  // define whether the test run was successful or failed.

  getLastError() {
    return this._error;
  }
}

exports.default = BaseReporter;
