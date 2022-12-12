'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = runJest;

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

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

function fs() {
  const data = _interopRequireWildcard(require('graceful-fs'));

  fs = function () {
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

function _testResult() {
  const data = require('@jest/test-result');

  _testResult = function () {
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

function _jestWatcher() {
  const data = require('jest-watcher');

  _jestWatcher = function () {
    return data;
  };

  return data;
}

var _SearchSource = _interopRequireDefault(require('./SearchSource'));

var _TestScheduler = _interopRequireDefault(require('./TestScheduler'));

var _collectHandles = _interopRequireDefault(require('./collectHandles'));

var _getNoTestsFoundMessage = _interopRequireDefault(
  require('./getNoTestsFoundMessage')
);

var _runGlobalHook = _interopRequireDefault(require('./runGlobalHook'));

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const getTestPaths = async (
  globalConfig,
  source,
  outputStream,
  changedFiles,
  jestHooks,
  filter
) => {
  const data = await source.getTestPaths(globalConfig, changedFiles, filter);

  if (!data.tests.length && globalConfig.onlyChanged && data.noSCM) {
    new (_console().CustomConsole)(outputStream, outputStream).log(
      'Jest can only find uncommitted changed files in a git or hg ' +
        'repository. If you make your project a git or hg ' +
        'repository (`git init` or `hg init`), Jest will be able ' +
        'to only run tests related to files changed since the last ' +
        'commit.'
    );
  }

  const shouldTestArray = await Promise.all(
    data.tests.map(test =>
      jestHooks.shouldRunTestSuite({
        config: test.context.config,
        duration: test.duration,
        testPath: test.path
      })
    )
  );
  const filteredTests = data.tests.filter((_test, i) => shouldTestArray[i]);
  return {...data, allTests: filteredTests.length, tests: filteredTests};
};

const processResults = (runResults, options) => {
  const {
    outputFile,
    json: isJSON,
    onComplete,
    outputStream,
    testResultsProcessor,
    collectHandles
  } = options;

  if (collectHandles) {
    runResults.openHandles = collectHandles();
  } else {
    runResults.openHandles = [];
  }

  if (testResultsProcessor) {
    runResults = require(testResultsProcessor)(runResults);
  }

  if (isJSON) {
    if (outputFile) {
      const cwd = (0, _jestUtil().tryRealpath)(process.cwd());
      const filePath = path().resolve(cwd, outputFile);
      fs().writeFileSync(
        filePath,
        JSON.stringify((0, _testResult().formatTestResults)(runResults))
      );
      outputStream.write(
        `Test results written to: ${path().relative(cwd, filePath)}\n`
      );
    } else {
      process.stdout.write(
        JSON.stringify((0, _testResult().formatTestResults)(runResults))
      );
    }
  }

  return onComplete && onComplete(runResults);
};

const testSchedulerContext = {
  firstRun: true,
  previousSuccess: true
};

async function runJest({
  contexts,
  globalConfig,
  outputStream,
  testWatcher,
  jestHooks = new (_jestWatcher().JestHook)().getEmitter(),
  startRun,
  changedFilesPromise,
  onComplete,
  failedTestsCache,
  filter
}) {
  const Sequencer = (0, _jestUtil().interopRequireDefault)(
    require(globalConfig.testSequencer)
  ).default;
  const sequencer = new Sequencer();
  let allTests = [];

  if (changedFilesPromise && globalConfig.watch) {
    const {repos} = await changedFilesPromise;
    const noSCM = Object.keys(repos).every(scm => repos[scm].size === 0);

    if (noSCM) {
      process.stderr.write(
        '\n' +
          _chalk().default.bold('--watch') +
          ' is not supported without git/hg, please use --watchAll ' +
          '\n'
      );
      (0, _exit().default)(1);
    }
  }

  const searchSources = contexts.map(
    context => new _SearchSource.default(context)
  );
  const testRunData = await Promise.all(
    contexts.map(async (context, index) => {
      const searchSource = searchSources[index];
      const matches = await getTestPaths(
        globalConfig,
        searchSource,
        outputStream,
        changedFilesPromise && (await changedFilesPromise),
        jestHooks,
        filter
      );
      allTests = allTests.concat(matches.tests);
      return {
        context,
        matches
      };
    })
  );
  allTests = await sequencer.sort(allTests);

  if (globalConfig.listTests) {
    const testsPaths = Array.from(new Set(allTests.map(test => test.path)));

    if (globalConfig.json) {
      console.log(JSON.stringify(testsPaths));
    } else {
      console.log(testsPaths.join('\n'));
    }

    onComplete &&
      onComplete((0, _testResult().makeEmptyAggregatedTestResult)());
    return;
  }

  if (globalConfig.onlyFailures) {
    if (failedTestsCache) {
      allTests = failedTestsCache.filterTests(allTests);
      globalConfig = failedTestsCache.updateConfig(globalConfig);
    } else {
      allTests = sequencer.allFailedTests(allTests);
    }
  }

  const hasTests = allTests.length > 0;

  if (!hasTests) {
    const noTestsFoundMessage = (0, _getNoTestsFoundMessage.default)(
      testRunData,
      globalConfig
    );

    if (
      globalConfig.passWithNoTests ||
      globalConfig.findRelatedTests ||
      globalConfig.lastCommit ||
      globalConfig.onlyChanged
    ) {
      new (_console().CustomConsole)(outputStream, outputStream).log(
        noTestsFoundMessage
      );
    } else {
      new (_console().CustomConsole)(outputStream, outputStream).error(
        noTestsFoundMessage
      );
      (0, _exit().default)(1);
    }
  } else if (
    allTests.length === 1 &&
    globalConfig.silent !== true &&
    globalConfig.verbose !== false
  ) {
    const newConfig = {...globalConfig, verbose: true};
    globalConfig = Object.freeze(newConfig);
  }

  let collectHandles;

  if (globalConfig.detectOpenHandles) {
    collectHandles = (0, _collectHandles.default)();
  }

  if (hasTests) {
    await (0, _runGlobalHook.default)({
      allTests,
      globalConfig,
      moduleName: 'globalSetup'
    });
  }

  if (changedFilesPromise) {
    const changedFilesInfo = await changedFilesPromise;

    if (changedFilesInfo.changedFiles) {
      testSchedulerContext.changedFiles = changedFilesInfo.changedFiles;
      const sourcesRelatedToTestsInChangedFilesArray = contexts
        .map((_, index) => {
          const searchSource = searchSources[index];
          const relatedSourceFromTestsInChangedFiles = searchSource.findRelatedSourcesFromTestsInChangedFiles(
            changedFilesInfo
          );
          return relatedSourceFromTestsInChangedFiles;
        })
        .reduce((total, paths) => total.concat(paths), []);
      testSchedulerContext.sourcesRelatedToTestsInChangedFiles = new Set(
        sourcesRelatedToTestsInChangedFilesArray
      );
    }
  }

  const results = await new _TestScheduler.default(
    globalConfig,
    {
      startRun
    },
    testSchedulerContext
  ).scheduleTests(allTests, testWatcher);
  sequencer.cacheResults(allTests, results);

  if (hasTests) {
    await (0, _runGlobalHook.default)({
      allTests,
      globalConfig,
      moduleName: 'globalTeardown'
    });
  }

  await processResults(results, {
    collectHandles,
    json: globalConfig.json,
    onComplete,
    outputFile: globalConfig.outputFile,
    outputStream,
    testResultsProcessor: globalConfig.testResultsProcessor
  });
}
