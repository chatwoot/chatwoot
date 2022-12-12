'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function fs() {
  const data = _interopRequireWildcard(require('graceful-fs'));

  fs = function () {
    return data;
  };

  return data;
}

function _jestHasteMap() {
  const data = require('jest-haste-map');

  _jestHasteMap = function () {
    return data;
  };

  return data;
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

const FAIL = 0;
const SUCCESS = 1;

/**
 * The TestSequencer will ultimately decide which tests should run first.
 * It is responsible for storing and reading from a local cache
 * map that stores context information for a given test, such as how long it
 * took to run during the last run and if it has failed or not.
 * Such information is used on:
 * TestSequencer.sort(tests: Array<Test>)
 * to sort the order of the provided tests.
 *
 * After the results are collected,
 * TestSequencer.cacheResults(tests: Array<Test>, results: AggregatedResult)
 * is called to store/update this information on the cache map.
 */
class TestSequencer {
  constructor() {
    _defineProperty(this, '_cache', new Map());
  }

  _getCachePath(context) {
    const {config} = context;
    return (0, _jestHasteMap().getCacheFilePath)(
      config.cacheDirectory,
      'perf-cache-' + config.name
    );
  }

  _getCache(test) {
    const {context} = test;

    if (!this._cache.has(context) && context.config.cache) {
      const cachePath = this._getCachePath(context);

      if (fs().existsSync(cachePath)) {
        try {
          this._cache.set(
            context,
            JSON.parse(fs().readFileSync(cachePath, 'utf8'))
          );
        } catch {}
      }
    }

    let cache = this._cache.get(context);

    if (!cache) {
      cache = {};

      this._cache.set(context, cache);
    }

    return cache;
  }
  /**
   * Sorting tests is very important because it has a great impact on the
   * user-perceived responsiveness and speed of the test run.
   *
   * If such information is on cache, tests are sorted based on:
   * -> Has it failed during the last run ?
   * Since it's important to provide the most expected feedback as quickly
   * as possible.
   * -> How long it took to run ?
   * Because running long tests first is an effort to minimize worker idle
   * time at the end of a long test run.
   * And if that information is not available they are sorted based on file size
   * since big test files usually take longer to complete.
   *
   * Note that a possible improvement would be to analyse other information
   * from the file other than its size.
   *
   */

  sort(tests) {
    const stats = {};

    const fileSize = ({path, context: {hasteFS}}) =>
      stats[path] || (stats[path] = hasteFS.getSize(path) || 0);

    const hasFailed = (cache, test) =>
      cache[test.path] && cache[test.path][0] === FAIL;

    const time = (cache, test) => cache[test.path] && cache[test.path][1];

    tests.forEach(test => (test.duration = time(this._getCache(test), test)));
    return tests.sort((testA, testB) => {
      const cacheA = this._getCache(testA);

      const cacheB = this._getCache(testB);

      const failedA = hasFailed(cacheA, testA);
      const failedB = hasFailed(cacheB, testB);
      const hasTimeA = testA.duration != null;

      if (failedA !== failedB) {
        return failedA ? -1 : 1;
      } else if (hasTimeA != (testB.duration != null)) {
        // If only one of two tests has timing information, run it last
        return hasTimeA ? 1 : -1;
      } else if (testA.duration != null && testB.duration != null) {
        return testA.duration < testB.duration ? 1 : -1;
      } else {
        return fileSize(testA) < fileSize(testB) ? 1 : -1;
      }
    });
  }

  allFailedTests(tests) {
    const hasFailed = (cache, test) => {
      var _cache$test$path;

      return (
        ((_cache$test$path = cache[test.path]) === null ||
        _cache$test$path === void 0
          ? void 0
          : _cache$test$path[0]) === FAIL
      );
    };

    return this.sort(
      tests.filter(test => hasFailed(this._getCache(test), test))
    );
  }

  cacheResults(tests, results) {
    const map = Object.create(null);
    tests.forEach(test => (map[test.path] = test));
    results.testResults.forEach(testResult => {
      if (testResult && map[testResult.testFilePath] && !testResult.skipped) {
        const cache = this._getCache(map[testResult.testFilePath]);

        const perf = testResult.perfStats;
        cache[testResult.testFilePath] = [
          testResult.numFailingTests ? FAIL : SUCCESS,
          perf.runtime || 0
        ];
      }
    });

    this._cache.forEach((cache, context) =>
      fs().writeFileSync(this._getCachePath(context), JSON.stringify(cache))
    );
  }
}

exports.default = TestSequencer;
