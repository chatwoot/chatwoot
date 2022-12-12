'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.wrapAnsiString = exports.getSummary = exports.relativePath = exports.formatTestPath = exports.trimAndFormatPath = exports.printDisplayName = void 0;

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

function _slash() {
  const data = _interopRequireDefault(require('slash'));

  _slash = function () {
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
const PROGRESS_BAR_WIDTH = 40;

const printDisplayName = config => {
  const {displayName} = config;

  const white = _chalk().default.reset.inverse.white;

  if (!displayName) {
    return '';
  }

  const {name, color} = displayName;
  const chosenColor = _chalk().default.reset.inverse[color]
    ? _chalk().default.reset.inverse[color]
    : white;
  return _chalk().default.supportsColor ? chosenColor(` ${name} `) : name;
};

exports.printDisplayName = printDisplayName;

const trimAndFormatPath = (pad, config, testPath, columns) => {
  const maxLength = columns - pad;
  const relative = relativePath(config, testPath);
  const {basename} = relative;
  let {dirname} = relative; // length is ok

  if ((dirname + path().sep + basename).length <= maxLength) {
    return (0, _slash().default)(
      _chalk().default.dim(dirname + path().sep) +
        _chalk().default.bold(basename)
    );
  } // we can fit trimmed dirname and full basename

  const basenameLength = basename.length;

  if (basenameLength + 4 < maxLength) {
    const dirnameLength = maxLength - 4 - basenameLength;
    dirname =
      '...' + dirname.slice(dirname.length - dirnameLength, dirname.length);
    return (0, _slash().default)(
      _chalk().default.dim(dirname + path().sep) +
        _chalk().default.bold(basename)
    );
  }

  if (basenameLength + 4 === maxLength) {
    return (0, _slash().default)(
      _chalk().default.dim('...' + path().sep) + _chalk().default.bold(basename)
    );
  } // can't fit dirname, but can fit trimmed basename

  return (0, _slash().default)(
    _chalk().default.bold(
      '...' + basename.slice(basename.length - maxLength - 4, basename.length)
    )
  );
};

exports.trimAndFormatPath = trimAndFormatPath;

const formatTestPath = (config, testPath) => {
  const {dirname, basename} = relativePath(config, testPath);
  return (0, _slash().default)(
    _chalk().default.dim(dirname + path().sep) + _chalk().default.bold(basename)
  );
};

exports.formatTestPath = formatTestPath;

const relativePath = (config, testPath) => {
  // this function can be called with ProjectConfigs or GlobalConfigs. GlobalConfigs
  // do not have config.cwd, only config.rootDir. Try using config.cwd, fallback
  // to config.rootDir. (Also, some unit just use config.rootDir, which is ok)
  testPath = path().relative(config.cwd || config.rootDir, testPath);
  const dirname = path().dirname(testPath);
  const basename = path().basename(testPath);
  return {
    basename,
    dirname
  };
};

exports.relativePath = relativePath;

const getValuesCurrentTestCases = (currentTestCases = []) => {
  let numFailingTests = 0;
  let numPassingTests = 0;
  let numPendingTests = 0;
  let numTodoTests = 0;
  let numTotalTests = 0;
  currentTestCases.forEach(testCase => {
    switch (testCase.testCaseResult.status) {
      case 'failed': {
        numFailingTests++;
        break;
      }

      case 'passed': {
        numPassingTests++;
        break;
      }

      case 'skipped': {
        numPendingTests++;
        break;
      }

      case 'todo': {
        numTodoTests++;
        break;
      }
    }

    numTotalTests++;
  });
  return {
    numFailingTests,
    numPassingTests,
    numPendingTests,
    numTodoTests,
    numTotalTests
  };
};

const getSummary = (aggregatedResults, options) => {
  let runTime = (Date.now() - aggregatedResults.startTime) / 1000;

  if (options && options.roundTime) {
    runTime = Math.floor(runTime);
  }

  const valuesForCurrentTestCases = getValuesCurrentTestCases(
    options === null || options === void 0 ? void 0 : options.currentTestCases
  );
  const estimatedTime = (options && options.estimatedTime) || 0;
  const snapshotResults = aggregatedResults.snapshot;
  const snapshotsAdded = snapshotResults.added;
  const snapshotsFailed = snapshotResults.unmatched;
  const snapshotsOutdated = snapshotResults.unchecked;
  const snapshotsFilesRemoved = snapshotResults.filesRemoved;
  const snapshotsDidUpdate = snapshotResults.didUpdate;
  const snapshotsPassed = snapshotResults.matched;
  const snapshotsTotal = snapshotResults.total;
  const snapshotsUpdated = snapshotResults.updated;
  const suitesFailed = aggregatedResults.numFailedTestSuites;
  const suitesPassed = aggregatedResults.numPassedTestSuites;
  const suitesPending = aggregatedResults.numPendingTestSuites;
  const suitesRun = suitesFailed + suitesPassed;
  const suitesTotal = aggregatedResults.numTotalTestSuites;
  const testsFailed = aggregatedResults.numFailedTests;
  const testsPassed = aggregatedResults.numPassedTests;
  const testsPending = aggregatedResults.numPendingTests;
  const testsTodo = aggregatedResults.numTodoTests;
  const testsTotal = aggregatedResults.numTotalTests;
  const width = (options && options.width) || 0;
  const suites =
    _chalk().default.bold('Test Suites: ') +
    (suitesFailed
      ? _chalk().default.bold.red(`${suitesFailed} failed`) + ', '
      : '') +
    (suitesPending
      ? _chalk().default.bold.yellow(`${suitesPending} skipped`) + ', '
      : '') +
    (suitesPassed
      ? _chalk().default.bold.green(`${suitesPassed} passed`) + ', '
      : '') +
    (suitesRun !== suitesTotal
      ? suitesRun + ' of ' + suitesTotal
      : suitesTotal) +
    ` total`;
  const updatedTestsFailed =
    testsFailed + valuesForCurrentTestCases.numFailingTests;
  const updatedTestsPending =
    testsPending + valuesForCurrentTestCases.numPendingTests;
  const updatedTestsTodo = testsTodo + valuesForCurrentTestCases.numTodoTests;
  const updatedTestsPassed =
    testsPassed + valuesForCurrentTestCases.numPassingTests;
  const updatedTestsTotal =
    testsTotal + valuesForCurrentTestCases.numTotalTests;
  const tests =
    _chalk().default.bold('Tests:       ') +
    (updatedTestsFailed > 0
      ? _chalk().default.bold.red(`${updatedTestsFailed} failed`) + ', '
      : '') +
    (updatedTestsPending > 0
      ? _chalk().default.bold.yellow(`${updatedTestsPending} skipped`) + ', '
      : '') +
    (updatedTestsTodo > 0
      ? _chalk().default.bold.magenta(`${updatedTestsTodo} todo`) + ', '
      : '') +
    (updatedTestsPassed > 0
      ? _chalk().default.bold.green(`${updatedTestsPassed} passed`) + ', '
      : '') +
    `${updatedTestsTotal} total`;
  const snapshots =
    _chalk().default.bold('Snapshots:   ') +
    (snapshotsFailed
      ? _chalk().default.bold.red(`${snapshotsFailed} failed`) + ', '
      : '') +
    (snapshotsOutdated && !snapshotsDidUpdate
      ? _chalk().default.bold.yellow(`${snapshotsOutdated} obsolete`) + ', '
      : '') +
    (snapshotsOutdated && snapshotsDidUpdate
      ? _chalk().default.bold.green(`${snapshotsOutdated} removed`) + ', '
      : '') +
    (snapshotsFilesRemoved && !snapshotsDidUpdate
      ? _chalk().default.bold.yellow(
          (0, _jestUtil().pluralize)('file', snapshotsFilesRemoved) +
            ' obsolete'
        ) + ', '
      : '') +
    (snapshotsFilesRemoved && snapshotsDidUpdate
      ? _chalk().default.bold.green(
          (0, _jestUtil().pluralize)('file', snapshotsFilesRemoved) + ' removed'
        ) + ', '
      : '') +
    (snapshotsUpdated
      ? _chalk().default.bold.green(`${snapshotsUpdated} updated`) + ', '
      : '') +
    (snapshotsAdded
      ? _chalk().default.bold.green(`${snapshotsAdded} written`) + ', '
      : '') +
    (snapshotsPassed
      ? _chalk().default.bold.green(`${snapshotsPassed} passed`) + ', '
      : '') +
    `${snapshotsTotal} total`;
  const time = renderTime(runTime, estimatedTime, width);
  return [suites, tests, snapshots, time].join('\n');
};

exports.getSummary = getSummary;

const renderTime = (runTime, estimatedTime, width) => {
  // If we are more than one second over the estimated time, highlight it.
  const renderedTime =
    estimatedTime && runTime >= estimatedTime + 1
      ? _chalk().default.bold.yellow((0, _jestUtil().formatTime)(runTime, 0))
      : (0, _jestUtil().formatTime)(runTime, 0);
  let time = _chalk().default.bold(`Time:`) + `        ${renderedTime}`;

  if (runTime < estimatedTime) {
    time += `, estimated ${(0, _jestUtil().formatTime)(estimatedTime, 0)}`;
  } // Only show a progress bar if the test run is actually going to take
  // some time.

  if (estimatedTime > 2 && runTime < estimatedTime && width) {
    const availableWidth = Math.min(PROGRESS_BAR_WIDTH, width);
    const length = Math.min(
      Math.floor((runTime / estimatedTime) * availableWidth),
      availableWidth
    );

    if (availableWidth >= 2) {
      time +=
        '\n' +
        _chalk().default.green('█').repeat(length) +
        _chalk()
          .default.white('█')
          .repeat(availableWidth - length);
    }
  }

  return time;
}; // word-wrap a string that contains ANSI escape sequences.
// ANSI escape sequences do not add to the string length.

const wrapAnsiString = (string, terminalWidth) => {
  if (terminalWidth === 0) {
    // if the terminal width is zero, don't bother word-wrapping
    return string;
  }

  const ANSI_REGEXP = /[\u001b\u009b]\[\d{1,2}m/g;
  const tokens = [];
  let lastIndex = 0;
  let match;

  while ((match = ANSI_REGEXP.exec(string))) {
    const ansi = match[0];
    const index = match['index'];

    if (index != lastIndex) {
      tokens.push(['string', string.slice(lastIndex, index)]);
    }

    tokens.push(['ansi', ansi]);
    lastIndex = index + ansi.length;
  }

  if (lastIndex != string.length - 1) {
    tokens.push(['string', string.slice(lastIndex, string.length)]);
  }

  let lastLineLength = 0;
  return tokens
    .reduce(
      (lines, [kind, token]) => {
        if (kind === 'string') {
          if (lastLineLength + token.length > terminalWidth) {
            while (token.length) {
              const chunk = token.slice(0, terminalWidth - lastLineLength);
              const remaining = token.slice(
                terminalWidth - lastLineLength,
                token.length
              );
              lines[lines.length - 1] += chunk;
              lastLineLength += chunk.length;
              token = remaining;

              if (token.length) {
                lines.push('');
                lastLineLength = 0;
              }
            }
          } else {
            lines[lines.length - 1] += token;
            lastLineLength += token.length;
          }
        } else {
          lines[lines.length - 1] += token;
        }

        return lines;
      },
      ['']
    )
    .join('\n');
};

exports.wrapAnsiString = wrapAnsiString;
