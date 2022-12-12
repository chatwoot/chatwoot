'use strict';

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
    return data;
  };

  return data;
}

function _emittery() {
  const data = _interopRequireDefault(require('emittery'));

  _emittery = function () {
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

function _throat() {
  const data = _interopRequireDefault(require('throat'));

  _throat = function () {
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

function _jestWorker() {
  const data = _interopRequireDefault(require('jest-worker'));

  _jestWorker = function () {
    return data;
  };

  return data;
}

var _runTest = _interopRequireDefault(require('./runTest'));

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

const TEST_WORKER_PATH = require.resolve('./testWorker');

class TestRunner {
  constructor(globalConfig, context) {
    _defineProperty(this, '_globalConfig', void 0);

    _defineProperty(this, '_context', void 0);

    _defineProperty(this, 'eventEmitter', new (_emittery().default.Typed)());

    _defineProperty(
      this,
      '__PRIVATE_UNSTABLE_API_supportsEventEmitters__',
      true
    );

    _defineProperty(this, 'isSerial', void 0);

    _defineProperty(this, 'on', this.eventEmitter.on.bind(this.eventEmitter));

    this._globalConfig = globalConfig;
    this._context = context || {};
  }

  async runTests(tests, watcher, onStart, onResult, onFailure, options) {
    return await (options.serial
      ? this._createInBandTestRun(tests, watcher, onStart, onResult, onFailure)
      : this._createParallelTestRun(
          tests,
          watcher,
          onStart,
          onResult,
          onFailure
        ));
  }

  async _createInBandTestRun(tests, watcher, onStart, onResult, onFailure) {
    process.env.JEST_WORKER_ID = '1';
    const mutex = (0, _throat().default)(1);
    return tests.reduce(
      (promise, test) =>
        mutex(() =>
          promise
            .then(async () => {
              if (watcher.isInterrupted()) {
                throw new CancelRun();
              }

              let sendMessageToJest; // Remove `if(onStart)` in Jest 27

              if (onStart) {
                await onStart(test);
                return (0, _runTest.default)(
                  test.path,
                  this._globalConfig,
                  test.context.config,
                  test.context.resolver,
                  this._context,
                  undefined
                );
              } else {
                // `deepCyclicCopy` used here to avoid mem-leak
                sendMessageToJest = (eventName, args) =>
                  this.eventEmitter.emit(
                    eventName,
                    (0, _jestUtil().deepCyclicCopy)(args, {
                      keepPrototype: false
                    })
                  );

                await this.eventEmitter.emit('test-file-start', [test]);
                return (0, _runTest.default)(
                  test.path,
                  this._globalConfig,
                  test.context.config,
                  test.context.resolver,
                  this._context,
                  sendMessageToJest
                );
              }
            })
            .then(result => {
              if (onResult) {
                return onResult(test, result);
              } else {
                return this.eventEmitter.emit('test-file-success', [
                  test,
                  result
                ]);
              }
            })
            .catch(err => {
              if (onFailure) {
                return onFailure(test, err);
              } else {
                return this.eventEmitter.emit('test-file-failure', [test, err]);
              }
            })
        ),
      Promise.resolve()
    );
  }

  async _createParallelTestRun(tests, watcher, onStart, onResult, onFailure) {
    const resolvers = new Map();

    for (const test of tests) {
      if (!resolvers.has(test.context.config.name)) {
        resolvers.set(test.context.config.name, {
          config: test.context.config,
          serializableModuleMap: test.context.moduleMap.toJSON()
        });
      }
    }

    const worker = new (_jestWorker().default)(TEST_WORKER_PATH, {
      exposedMethods: ['worker'],
      forkOptions: {
        stdio: 'pipe'
      },
      maxRetries: 3,
      numWorkers: this._globalConfig.maxWorkers,
      setupArgs: [
        {
          serializableResolvers: Array.from(resolvers.values())
        }
      ]
    });
    if (worker.getStdout()) worker.getStdout().pipe(process.stdout);
    if (worker.getStderr()) worker.getStderr().pipe(process.stderr);
    const mutex = (0, _throat().default)(this._globalConfig.maxWorkers); // Send test suites to workers continuously instead of all at once to track
    // the start time of individual tests.

    const runTestInWorker = test =>
      mutex(async () => {
        if (watcher.isInterrupted()) {
          return Promise.reject();
        } // Remove `if(onStart)` in Jest 27

        if (onStart) {
          await onStart(test);
        } else {
          await this.eventEmitter.emit('test-file-start', [test]);
        }

        const promise = worker.worker({
          config: test.context.config,
          context: {
            ...this._context,
            changedFiles:
              this._context.changedFiles &&
              Array.from(this._context.changedFiles),
            sourcesRelatedToTestsInChangedFiles:
              this._context.sourcesRelatedToTestsInChangedFiles &&
              Array.from(this._context.sourcesRelatedToTestsInChangedFiles)
          },
          globalConfig: this._globalConfig,
          path: test.path
        });

        if (promise.UNSTABLE_onCustomMessage) {
          // TODO: Get appropriate type for `onCustomMessage`
          promise.UNSTABLE_onCustomMessage(([event, payload]) => {
            this.eventEmitter.emit(event, payload);
          });
        }

        return promise;
      });

    const onError = async (err, test) => {
      // Remove `if(onFailure)` in Jest 27
      if (onFailure) {
        await onFailure(test, err);
      } else {
        await this.eventEmitter.emit('test-file-failure', [test, err]);
      }

      if (err.type === 'ProcessTerminatedError') {
        console.error(
          'A worker process has quit unexpectedly! ' +
            'Most likely this is an initialization error.'
        );
        (0, _exit().default)(1);
      }
    };

    const onInterrupt = new Promise((_, reject) => {
      watcher.on('change', state => {
        if (state.interrupted) {
          reject(new CancelRun());
        }
      });
    });
    const runAllTests = Promise.all(
      tests.map(test =>
        runTestInWorker(test)
          .then(result => {
            if (onResult) {
              return onResult(test, result);
            } else {
              return this.eventEmitter.emit('test-file-success', [
                test,
                result
              ]);
            }
          })
          .catch(error => onError(error, test))
      )
    );

    const cleanup = async () => {
      const {forceExited} = await worker.end();

      if (forceExited) {
        console.error(
          _chalk().default.yellow(
            'A worker process has failed to exit gracefully and has been force exited. ' +
              'This is likely caused by tests leaking due to improper teardown. ' +
              'Try running with --detectOpenHandles to find leaks.'
          )
        );
      }
    };

    return Promise.race([runAllTests, onInterrupt]).then(cleanup, cleanup);
  }
}

class CancelRun extends Error {
  constructor(message) {
    super(message);
    this.name = 'CancelRun';
  }
}

module.exports = TestRunner;
