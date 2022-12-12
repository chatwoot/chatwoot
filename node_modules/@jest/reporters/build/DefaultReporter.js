'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
    return data;
  };

  return data;
}

function _console() {
  const data = require('@jest/console');

  _console = function () {
    return data;
  };

  return data;
}

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
    return data;
  };

  return data;
}

var _BaseReporter = _interopRequireDefault(require('./BaseReporter'));

var _Status = _interopRequireDefault(require('./Status'));

var _getResultHeader = _interopRequireDefault(require('./getResultHeader'));

var _getSnapshotStatus = _interopRequireDefault(require('./getSnapshotStatus'));

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
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

const TITLE_BULLET = _chalk().default.bold('\u25cf ');

class DefaultReporter extends _BaseReporter.default {
  // ANSI clear sequence for the last printed status
  constructor(globalConfig) {
    super();

    _defineProperty(this, '_clear', void 0);

    _defineProperty(this, '_err', void 0);

    _defineProperty(this, '_globalConfig', void 0);

    _defineProperty(this, '_out', void 0);

    _defineProperty(this, '_status', void 0);

    _defineProperty(this, '_bufferedOutput', void 0);

    this._globalConfig = globalConfig;
    this._clear = '';
    this._out = process.stdout.write.bind(process.stdout);
    this._err = process.stderr.write.bind(process.stderr);
    this._status = new _Status.default();
    this._bufferedOutput = new Set();

    this._wrapStdio(process.stdout);

    this._wrapStdio(process.stderr);

    this._status.onChange(() => {
      this._clearStatus();

      this._printStatus();
    });
  }

  _wrapStdio(stream) {
    const originalWrite = stream.write;
    let buffer = [];
    let timeout = null;

    const flushBufferedOutput = () => {
      const string = buffer.join('');
      buffer = []; // This is to avoid conflicts between random output and status text

      this._clearStatus();

      if (string) {
        originalWrite.call(stream, string);
      }

      this._printStatus();

      this._bufferedOutput.delete(flushBufferedOutput);
    };

    this._bufferedOutput.add(flushBufferedOutput);

    const debouncedFlush = () => {
      // If the process blows up no errors would be printed.
      // There should be a smart way to buffer stderr, but for now
      // we just won't buffer it.
      if (stream === process.stderr) {
        flushBufferedOutput();
      } else {
        if (!timeout) {
          timeout = setTimeout(() => {
            flushBufferedOutput();
            timeout = null;
          }, 100);
        }
      }
    };

    stream.write = chunk => {
      buffer.push(chunk);
      debouncedFlush();
      return true;
    };
  } // Don't wait for the debounced call and flush all output immediately.

  forceFlushBufferedOutput() {
    for (const flushBufferedOutput of this._bufferedOutput) {
      flushBufferedOutput();
    }
  }

  _clearStatus() {
    if (_jestUtil().isInteractive) {
      if (this._globalConfig.useStderr) {
        this._err(this._clear);
      } else {
        this._out(this._clear);
      }
    }
  }

  _printStatus() {
    const {content, clear} = this._status.get();

    this._clear = clear;

    if (_jestUtil().isInteractive) {
      if (this._globalConfig.useStderr) {
        this._err(content);
      } else {
        this._out(content);
      }
    }
  }

  onRunStart(aggregatedResults, options) {
    this._status.runStarted(aggregatedResults, options);
  }

  onTestStart(test) {
    this._status.testStarted(test.path, test.context.config);
  }

  onTestCaseResult(test, testCaseResult) {
    this._status.addTestCaseResult(test, testCaseResult);
  }

  onRunComplete() {
    this.forceFlushBufferedOutput();

    this._status.runFinished();

    process.stdout.write = this._out;
    process.stderr.write = this._err;
    (0, _jestUtil().clearLine)(process.stderr);
  }

  onTestResult(test, testResult, aggregatedResults) {
    this.testFinished(test.context.config, testResult, aggregatedResults);

    if (!testResult.skipped) {
      this.printTestFileHeader(
        testResult.testFilePath,
        test.context.config,
        testResult
      );
      this.printTestFileFailureMessage(
        testResult.testFilePath,
        test.context.config,
        testResult
      );
    }

    this.forceFlushBufferedOutput();
  }

  testFinished(config, testResult, aggregatedResults) {
    this._status.testFinished(config, testResult, aggregatedResults);
  }

  printTestFileHeader(_testPath, config, result) {
    this.log((0, _getResultHeader.default)(result, this._globalConfig, config));

    if (result.console) {
      this.log(
        '  ' +
          TITLE_BULLET +
          'Console\n\n' +
          (0, _console().getConsoleOutput)(
            config.cwd,
            !!this._globalConfig.verbose,
            result.console,
            config,
            this._globalConfig
          )
      );
    }
  }

  printTestFileFailureMessage(_testPath, _config, result) {
    if (result.failureMessage) {
      this.log(result.failureMessage);
    }

    const didUpdate = this._globalConfig.updateSnapshot === 'all';
    const snapshotStatuses = (0, _getSnapshotStatus.default)(
      result.snapshot,
      didUpdate
    );
    snapshotStatuses.forEach(this.log);
  }
}

exports.default = DefaultReporter;
