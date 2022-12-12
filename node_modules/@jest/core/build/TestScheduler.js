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

function _exit() {
  const data = _interopRequireDefault(require('exit'));

  _exit = function () {
    return data;
  };

  return data;
}

function _reporters() {
  const data = require('@jest/reporters');

  _reporters = function () {
    return data;
  };

  return data;
}

function _testResult() {
  const data = require('@jest/test-result');

  _testResult = function () {
    return data;
  };

  return data;
}

function _jestMessageUtil() {
  const data = require('jest-message-util');

  _jestMessageUtil = function () {
    return data;
  };

  return data;
}

function _jestRunner() {
  const data = _interopRequireDefault(require('jest-runner'));

  _jestRunner = function () {
    return data;
  };

  return data;
}

function _jestSnapshot() {
  const data = _interopRequireDefault(require('jest-snapshot'));

  _jestSnapshot = function () {
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

var _ReporterDispatcher = _interopRequireDefault(
  require('./ReporterDispatcher')
);

var _testSchedulerHelper = require('./testSchedulerHelper');

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

// The default jest-runner is required because it is the default test runner
// and required implicitly through the `runner` ProjectConfig option.
_jestRunner().default;

class TestScheduler {
  constructor(globalConfig, options, context) {
    _defineProperty(this, '_dispatcher', void 0);

    _defineProperty(this, '_globalConfig', void 0);

    _defineProperty(this, '_options', void 0);

    _defineProperty(this, '_context', void 0);

    this._dispatcher = new _ReporterDispatcher.default();
    this._globalConfig = globalConfig;
    this._options = options;
    this._context = context;

    this._setupReporters();
  }

  addReporter(reporter) {
    this._dispatcher.register(reporter);
  }

  removeReporter(ReporterClass) {
    this._dispatcher.unregister(ReporterClass);
  }

  async scheduleTests(tests, watcher) {
    const onTestFileStart = this._dispatcher.onTestFileStart.bind(
      this._dispatcher
    );

    const timings = [];
    const contexts = new Set();
    tests.forEach(test => {
      contexts.add(test.context);

      if (test.duration) {
        timings.push(test.duration);
      }
    });
    const aggregatedResults = createAggregatedResults(tests.length);
    const estimatedTime = Math.ceil(
      getEstimatedTime(timings, this._globalConfig.maxWorkers) / 1000
    );
    const runInBand = (0, _testSchedulerHelper.shouldRunInBand)(
      tests,
      timings,
      this._globalConfig
    );

    const onResult = async (test, testResult) => {
      if (watcher.isInterrupted()) {
        return Promise.resolve();
      }

      if (testResult.testResults.length === 0) {
        const message = 'Your test suite must contain at least one test.';
        return onFailure(test, {
          message,
          stack: new Error(message).stack
        });
      } // Throws when the context is leaked after executing a test.

      if (testResult.leaks) {
        const message =
          _chalk().default.red.bold('EXPERIMENTAL FEATURE!\n') +
          'Your test suite is leaking memory. Please ensure all references are cleaned.\n' +
          '\n' +
          'There is a number of things that can leak memory:\n' +
          '  - Async operations that have not finished (e.g. fs.readFile).\n' +
          '  - Timers not properly mocked (e.g. setInterval, setTimeout).\n' +
          '  - Keeping references to the global scope.';
        return onFailure(test, {
          message,
          stack: new Error(message).stack
        });
      }

      (0, _testResult().addResult)(aggregatedResults, testResult);
      await this._dispatcher.onTestFileResult(
        test,
        testResult,
        aggregatedResults
      );
      return this._bailIfNeeded(contexts, aggregatedResults, watcher);
    };

    const onFailure = async (test, error) => {
      if (watcher.isInterrupted()) {
        return;
      }

      const testResult = (0, _testResult().buildFailureTestResult)(
        test.path,
        error
      );
      testResult.failureMessage = (0, _jestMessageUtil().formatExecError)(
        testResult.testExecError,
        test.context.config,
        this._globalConfig,
        test.path
      );
      (0, _testResult().addResult)(aggregatedResults, testResult);
      await this._dispatcher.onTestFileResult(
        test,
        testResult,
        aggregatedResults
      );
    };

    const updateSnapshotState = () => {
      contexts.forEach(context => {
        const status = _jestSnapshot().default.cleanup(
          context.hasteFS,
          this._globalConfig.updateSnapshot,
          _jestSnapshot().default.buildSnapshotResolver(context.config),
          context.config.testPathIgnorePatterns
        );

        aggregatedResults.snapshot.filesRemoved += status.filesRemoved;
        aggregatedResults.snapshot.filesRemovedList = (
          aggregatedResults.snapshot.filesRemovedList || []
        ).concat(status.filesRemovedList);
      });
      const updateAll = this._globalConfig.updateSnapshot === 'all';
      aggregatedResults.snapshot.didUpdate = updateAll;
      aggregatedResults.snapshot.failure = !!(
        !updateAll &&
        (aggregatedResults.snapshot.unchecked ||
          aggregatedResults.snapshot.unmatched ||
          aggregatedResults.snapshot.filesRemoved)
      );
    };

    await this._dispatcher.onRunStart(aggregatedResults, {
      estimatedTime,
      showStatus: !runInBand
    });
    const testRunners = Object.create(null);
    const contextsByTestRunner = new WeakMap();
    contexts.forEach(context => {
      const {config} = context;

      if (!testRunners[config.runner]) {
        var _this$_context, _this$_context2;

        const Runner = require(config.runner);

        const runner = new Runner(this._globalConfig, {
          changedFiles:
            (_this$_context = this._context) === null ||
            _this$_context === void 0
              ? void 0
              : _this$_context.changedFiles,
          sourcesRelatedToTestsInChangedFiles:
            (_this$_context2 = this._context) === null ||
            _this$_context2 === void 0
              ? void 0
              : _this$_context2.sourcesRelatedToTestsInChangedFiles
        });
        testRunners[config.runner] = runner;
        contextsByTestRunner.set(runner, context);
      }
    });

    const testsByRunner = this._partitionTests(testRunners, tests);

    if (testsByRunner) {
      try {
        for (const runner of Object.keys(testRunners)) {
          const testRunner = testRunners[runner];
          const context = contextsByTestRunner.get(testRunner);
          invariant(context);
          const tests = testsByRunner[runner];
          const testRunnerOptions = {
            serial: runInBand || Boolean(testRunner.isSerial)
          };
          /**
           * Test runners with event emitters are still not supported
           * for third party test runners.
           */

          if (testRunner.__PRIVATE_UNSTABLE_API_supportsEventEmitters__) {
            const unsubscribes = [
              testRunner.on('test-file-start', ([test]) =>
                onTestFileStart(test)
              ),
              testRunner.on('test-file-success', ([test, testResult]) =>
                onResult(test, testResult)
              ),
              testRunner.on('test-file-failure', ([test, error]) =>
                onFailure(test, error)
              ),
              testRunner.on(
                'test-case-result',
                ([testPath, testCaseResult]) => {
                  const test = {
                    context,
                    path: testPath
                  };

                  this._dispatcher.onTestCaseResult(test, testCaseResult);
                }
              )
            ];
            await testRunner.runTests(
              tests,
              watcher,
              undefined,
              undefined,
              undefined,
              testRunnerOptions
            );
            unsubscribes.forEach(sub => sub());
          } else {
            await testRunner.runTests(
              tests,
              watcher,
              onTestFileStart,
              onResult,
              onFailure,
              testRunnerOptions
            );
          }
        }
      } catch (error) {
        if (!watcher.isInterrupted()) {
          throw error;
        }
      }
    }

    updateSnapshotState();
    aggregatedResults.wasInterrupted = watcher.isInterrupted();
    await this._dispatcher.onRunComplete(contexts, aggregatedResults);
    const anyTestFailures = !(
      aggregatedResults.numFailedTests === 0 &&
      aggregatedResults.numRuntimeErrorTestSuites === 0
    );

    const anyReporterErrors = this._dispatcher.hasErrors();

    aggregatedResults.success = !(
      anyTestFailures ||
      aggregatedResults.snapshot.failure ||
      anyReporterErrors
    );
    return aggregatedResults;
  }

  _partitionTests(testRunners, tests) {
    if (Object.keys(testRunners).length > 1) {
      return tests.reduce((testRuns, test) => {
        const runner = test.context.config.runner;

        if (!testRuns[runner]) {
          testRuns[runner] = [];
        }

        testRuns[runner].push(test);
        return testRuns;
      }, Object.create(null));
    } else if (tests.length > 0 && tests[0] != null) {
      // If there is only one runner, don't partition the tests.
      return Object.assign(Object.create(null), {
        [tests[0].context.config.runner]: tests
      });
    } else {
      return null;
    }
  }

  _shouldAddDefaultReporters(reporters) {
    return (
      !reporters ||
      !!reporters.find(
        reporter => this._getReporterProps(reporter).path === 'default'
      )
    );
  }

  _setupReporters() {
    const {collectCoverage, notify, reporters} = this._globalConfig;

    const isDefault = this._shouldAddDefaultReporters(reporters);

    if (isDefault) {
      this._setupDefaultReporters(collectCoverage);
    }

    if (!isDefault && collectCoverage) {
      var _this$_context3, _this$_context4;

      this.addReporter(
        new (_reporters().CoverageReporter)(this._globalConfig, {
          changedFiles:
            (_this$_context3 = this._context) === null ||
            _this$_context3 === void 0
              ? void 0
              : _this$_context3.changedFiles,
          sourcesRelatedToTestsInChangedFiles:
            (_this$_context4 = this._context) === null ||
            _this$_context4 === void 0
              ? void 0
              : _this$_context4.sourcesRelatedToTestsInChangedFiles
        })
      );
    }

    if (notify) {
      this.addReporter(
        new (_reporters().NotifyReporter)(
          this._globalConfig,
          this._options.startRun,
          this._context
        )
      );
    }

    if (reporters && Array.isArray(reporters)) {
      this._addCustomReporters(reporters);
    }
  }

  _setupDefaultReporters(collectCoverage) {
    this.addReporter(
      this._globalConfig.verbose
        ? new (_reporters().VerboseReporter)(this._globalConfig)
        : new (_reporters().DefaultReporter)(this._globalConfig)
    );

    if (collectCoverage) {
      var _this$_context5, _this$_context6;

      this.addReporter(
        new (_reporters().CoverageReporter)(this._globalConfig, {
          changedFiles:
            (_this$_context5 = this._context) === null ||
            _this$_context5 === void 0
              ? void 0
              : _this$_context5.changedFiles,
          sourcesRelatedToTestsInChangedFiles:
            (_this$_context6 = this._context) === null ||
            _this$_context6 === void 0
              ? void 0
              : _this$_context6.sourcesRelatedToTestsInChangedFiles
        })
      );
    }

    this.addReporter(new (_reporters().SummaryReporter)(this._globalConfig));
  }

  _addCustomReporters(reporters) {
    reporters.forEach(reporter => {
      const {options, path} = this._getReporterProps(reporter);

      if (path === 'default') return;

      try {
        // TODO: Use `requireAndTranspileModule` for Jest 26
        const Reporter = (0, _jestUtil().interopRequireDefault)(require(path))
          .default;
        this.addReporter(new Reporter(this._globalConfig, options));
      } catch (error) {
        error.message =
          'An error occurred while adding the reporter at path "' +
          _chalk().default.bold(path) +
          '".' +
          error.message;
        throw error;
      }
    });
  }
  /**
   * Get properties of a reporter in an object
   * to make dealing with them less painful.
   */

  _getReporterProps(reporter) {
    if (typeof reporter === 'string') {
      return {
        options: this._options,
        path: reporter
      };
    } else if (Array.isArray(reporter)) {
      const [path, options] = reporter;
      return {
        options,
        path
      };
    }

    throw new Error('Reporter should be either a string or an array');
  }

  _bailIfNeeded(contexts, aggregatedResults, watcher) {
    if (
      this._globalConfig.bail !== 0 &&
      aggregatedResults.numFailedTests >= this._globalConfig.bail
    ) {
      if (watcher.isWatchMode()) {
        watcher.setState({
          interrupted: true
        });
      } else {
        const failureExit = () => (0, _exit().default)(1);

        return this._dispatcher
          .onRunComplete(contexts, aggregatedResults)
          .then(failureExit)
          .catch(failureExit);
      }
    }

    return Promise.resolve();
  }
}

exports.default = TestScheduler;

function invariant(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const createAggregatedResults = numTotalTestSuites => {
  const result = (0, _testResult().makeEmptyAggregatedTestResult)();
  result.numTotalTestSuites = numTotalTestSuites;
  result.startTime = Date.now();
  result.success = false;
  return result;
};

const getEstimatedTime = (timings, workers) => {
  if (!timings.length) {
    return 0;
  }

  const max = Math.max.apply(null, timings);
  return timings.length <= workers
    ? max
    : Math.max(timings.reduce((sum, time) => sum + time) / workers, max);
};
