'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.runCLI = runCLI;

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

function _rimraf() {
  const data = _interopRequireDefault(require('rimraf'));

  _rimraf = function () {
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

function _jestConfig() {
  const data = require('jest-config');

  _jestConfig = function () {
    return data;
  };

  return data;
}

function _jestHasteMap() {
  const data = _interopRequireDefault(require('jest-haste-map'));

  _jestHasteMap = function () {
    return data;
  };

  return data;
}

function _jestRuntime() {
  const data = _interopRequireDefault(require('jest-runtime'));

  _jestRuntime = function () {
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

function _TestWatcher() {
  const data = _interopRequireDefault(require('../TestWatcher'));

  _TestWatcher = function () {
    return data;
  };

  return data;
}

function _collectHandles() {
  const data = require('../collectHandles');

  _collectHandles = function () {
    return data;
  };

  return data;
}

function _getChangedFilesPromise() {
  const data = _interopRequireDefault(require('../getChangedFilesPromise'));

  _getChangedFilesPromise = function () {
    return data;
  };

  return data;
}

function _getConfigsOfProjectsToRun() {
  const data = _interopRequireDefault(require('../getConfigsOfProjectsToRun'));

  _getConfigsOfProjectsToRun = function () {
    return data;
  };

  return data;
}

function _getProjectNamesMissingWarning() {
  const data = _interopRequireDefault(
    require('../getProjectNamesMissingWarning')
  );

  _getProjectNamesMissingWarning = function () {
    return data;
  };

  return data;
}

function _getSelectProjectsMessage() {
  const data = _interopRequireDefault(require('../getSelectProjectsMessage'));

  _getSelectProjectsMessage = function () {
    return data;
  };

  return data;
}

function _createContext() {
  const data = _interopRequireDefault(require('../lib/createContext'));

  _createContext = function () {
    return data;
  };

  return data;
}

function _handleDeprecationWarnings() {
  const data = _interopRequireDefault(
    require('../lib/handleDeprecationWarnings')
  );

  _handleDeprecationWarnings = function () {
    return data;
  };

  return data;
}

function _logDebugMessages() {
  const data = _interopRequireDefault(require('../lib/logDebugMessages'));

  _logDebugMessages = function () {
    return data;
  };

  return data;
}

function _pluralize() {
  const data = _interopRequireDefault(require('../pluralize'));

  _pluralize = function () {
    return data;
  };

  return data;
}

function _runJest() {
  const data = _interopRequireDefault(require('../runJest'));

  _runJest = function () {
    return data;
  };

  return data;
}

function _watch() {
  const data = _interopRequireDefault(require('../watch'));

  _watch = function () {
    return data;
  };

  return data;
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const {print: preRunMessagePrint} = _jestUtil().preRunMessage;

async function runCLI(argv, projects) {
  let results; // If we output a JSON object, we can't write anything to stdout, since
  // it'll break the JSON structure and it won't be valid.

  const outputStream =
    argv.json || argv.useStderr ? process.stderr : process.stdout;
  const {globalConfig, configs, hasDeprecationWarnings} = await (0,
  _jestConfig().readConfigs)(argv, projects);

  if (argv.debug) {
    (0, _logDebugMessages().default)(globalConfig, configs, outputStream);
  }

  if (argv.showConfig) {
    (0, _logDebugMessages().default)(globalConfig, configs, process.stdout);
    (0, _exit().default)(0);
  }

  if (argv.clearCache) {
    configs.forEach(config => {
      _rimraf().default.sync(config.cacheDirectory);

      process.stdout.write(`Cleared ${config.cacheDirectory}\n`);
    });
    (0, _exit().default)(0);
  }

  let configsOfProjectsToRun = configs;

  if (argv.selectProjects) {
    const namesMissingWarning = (0, _getProjectNamesMissingWarning().default)(
      configs
    );

    if (namesMissingWarning) {
      outputStream.write(namesMissingWarning);
    }

    configsOfProjectsToRun = (0, _getConfigsOfProjectsToRun().default)(
      argv.selectProjects,
      configs
    );
    outputStream.write(
      (0, _getSelectProjectsMessage().default)(configsOfProjectsToRun)
    );
  }

  await _run10000(
    globalConfig,
    configsOfProjectsToRun,
    hasDeprecationWarnings,
    outputStream,
    r => (results = r)
  );

  if (argv.watch || argv.watchAll) {
    // If in watch mode, return the promise that will never resolve.
    // If the watch mode is interrupted, watch should handle the process
    // shutdown.
    return new Promise(() => {});
  }

  if (!results) {
    throw new Error(
      'AggregatedResult must be present after test run is complete'
    );
  }

  const {openHandles} = results;

  if (openHandles && openHandles.length) {
    const formatted = (0, _collectHandles().formatHandleErrors)(
      openHandles,
      configs[0]
    );
    const openHandlesString = (0, _pluralize().default)(
      'open handle',
      formatted.length,
      's'
    );
    const message =
      _chalk().default.red(
        `\nJest has detected the following ${openHandlesString} potentially keeping Jest from exiting:\n\n`
      ) + formatted.join('\n\n');
    console.error(message);
  }

  return {
    globalConfig,
    results
  };
}

const buildContextsAndHasteMaps = async (
  configs,
  globalConfig,
  outputStream
) => {
  const hasteMapInstances = Array(configs.length);
  const contexts = await Promise.all(
    configs.map(async (config, index) => {
      (0, _jestUtil().createDirectory)(config.cacheDirectory);

      const hasteMapInstance = _jestRuntime().default.createHasteMap(config, {
        console: new (_console().CustomConsole)(outputStream, outputStream),
        maxWorkers: Math.max(
          1,
          Math.floor(globalConfig.maxWorkers / configs.length)
        ),
        resetCache: !config.cache,
        watch: globalConfig.watch || globalConfig.watchAll,
        watchman: globalConfig.watchman
      });

      hasteMapInstances[index] = hasteMapInstance;
      return (0, _createContext().default)(
        config,
        await hasteMapInstance.build()
      );
    })
  );
  return {
    contexts,
    hasteMapInstances
  };
};

const _run10000 = async (
  globalConfig,
  configs,
  hasDeprecationWarnings,
  outputStream,
  onComplete
) => {
  // Queries to hg/git can take a while, so we need to start the process
  // as soon as possible, so by the time we need the result it's already there.
  const changedFilesPromise = (0, _getChangedFilesPromise().default)(
    globalConfig,
    configs
  ); // Filter may need to do an HTTP call or something similar to setup.
  // We will wait on an async response from this before using the filter.

  let filter;

  if (globalConfig.filter && !globalConfig.skipFilter) {
    const rawFilter = require(globalConfig.filter);

    let filterSetupPromise;

    if (rawFilter.setup) {
      // Wrap filter setup Promise to avoid "uncaught Promise" error.
      // If an error is returned, we surface it in the return value.
      filterSetupPromise = (async () => {
        try {
          await rawFilter.setup();
        } catch (err) {
          return err;
        }

        return undefined;
      })();
    }

    filter = async testPaths => {
      if (filterSetupPromise) {
        // Expect an undefined return value unless there was an error.
        const err = await filterSetupPromise;

        if (err) {
          throw err;
        }
      }

      return rawFilter(testPaths);
    };
  }

  const {contexts, hasteMapInstances} = await buildContextsAndHasteMaps(
    configs,
    globalConfig,
    outputStream
  );
  globalConfig.watch || globalConfig.watchAll
    ? await runWatch(
        contexts,
        configs,
        hasDeprecationWarnings,
        globalConfig,
        outputStream,
        hasteMapInstances,
        filter
      )
    : await runWithoutWatch(
        globalConfig,
        contexts,
        outputStream,
        onComplete,
        changedFilesPromise,
        filter
      );
};

const runWatch = async (
  contexts,
  _configs,
  hasDeprecationWarnings,
  globalConfig,
  outputStream,
  hasteMapInstances,
  filter
) => {
  if (hasDeprecationWarnings) {
    try {
      await (0, _handleDeprecationWarnings().default)(
        outputStream,
        process.stdin
      );
      return (0, _watch().default)(
        globalConfig,
        contexts,
        outputStream,
        hasteMapInstances,
        undefined,
        undefined,
        filter
      );
    } catch {
      (0, _exit().default)(0);
    }
  }

  return (0, _watch().default)(
    globalConfig,
    contexts,
    outputStream,
    hasteMapInstances,
    undefined,
    undefined,
    filter
  );
};

const runWithoutWatch = async (
  globalConfig,
  contexts,
  outputStream,
  onComplete,
  changedFilesPromise,
  filter
) => {
  const startRun = async () => {
    if (!globalConfig.listTests) {
      preRunMessagePrint(outputStream);
    }

    return (0, _runJest().default)({
      changedFilesPromise,
      contexts,
      failedTestsCache: undefined,
      filter,
      globalConfig,
      onComplete,
      outputStream,
      startRun,
      testWatcher: new (_TestWatcher().default)({
        isWatchMode: false
      })
    });
  };

  return startRun();
};
