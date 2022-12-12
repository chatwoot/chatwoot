'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function os() {
  const data = _interopRequireWildcard(require('os'));

  os = function () {
    return data;
  };

  return data;
}

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _micromatch() {
  const data = _interopRequireDefault(require('micromatch'));

  _micromatch = function () {
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

function _jestRegexUtil() {
  const data = require('jest-regex-util');

  _jestRegexUtil = function () {
    return data;
  };

  return data;
}

function _jestResolveDependencies() {
  const data = _interopRequireDefault(require('jest-resolve-dependencies'));

  _jestResolveDependencies = function () {
    return data;
  };

  return data;
}

function _jestSnapshot() {
  const data = require('jest-snapshot');

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

const regexToMatcher = testRegex => {
  const regexes = testRegex.map(testRegex => new RegExp(testRegex));
  return path =>
    regexes.some(regex => {
      const result = regex.test(path); // prevent stateful regexes from breaking, just in case

      regex.lastIndex = 0;
      return result;
    });
};

const toTests = (context, tests) =>
  tests.map(path => ({
    context,
    duration: undefined,
    path
  }));

const hasSCM = changedFilesInfo => {
  const {repos} = changedFilesInfo; // no SCM (git/hg/...) is found in any of the roots.

  const noSCM = Object.values(repos).every(scm => scm.size === 0);
  return !noSCM;
};

class SearchSource {
  constructor(context) {
    _defineProperty(this, '_context', void 0);

    _defineProperty(this, '_dependencyResolver', void 0);

    _defineProperty(this, '_testPathCases', []);

    const {config} = context;
    this._context = context;
    this._dependencyResolver = null;
    const rootPattern = new RegExp(
      config.roots
        .map(dir => (0, _jestRegexUtil().escapePathForRegex)(dir + path().sep))
        .join('|')
    );

    this._testPathCases.push({
      isMatch: path => rootPattern.test(path),
      stat: 'roots'
    });

    if (config.testMatch.length) {
      this._testPathCases.push({
        isMatch: (0, _jestUtil().globsToMatcher)(config.testMatch),
        stat: 'testMatch'
      });
    }

    if (config.testPathIgnorePatterns.length) {
      const testIgnorePatternsRegex = new RegExp(
        config.testPathIgnorePatterns.join('|')
      );

      this._testPathCases.push({
        isMatch: path => !testIgnorePatternsRegex.test(path),
        stat: 'testPathIgnorePatterns'
      });
    }

    if (config.testRegex.length) {
      this._testPathCases.push({
        isMatch: regexToMatcher(config.testRegex),
        stat: 'testRegex'
      });
    }
  }

  _getOrBuildDependencyResolver() {
    if (!this._dependencyResolver) {
      this._dependencyResolver = new (_jestResolveDependencies().default)(
        this._context.resolver,
        this._context.hasteFS,
        (0, _jestSnapshot().buildSnapshotResolver)(this._context.config)
      );
    }

    return this._dependencyResolver;
  }

  _filterTestPathsWithStats(allPaths, testPathPattern) {
    const data = {
      stats: {
        roots: 0,
        testMatch: 0,
        testPathIgnorePatterns: 0,
        testRegex: 0
      },
      tests: [],
      total: allPaths.length
    };
    const testCases = Array.from(this._testPathCases); // clone

    if (testPathPattern) {
      const regex = (0, _jestUtil().testPathPatternToRegExp)(testPathPattern);
      testCases.push({
        isMatch: path => regex.test(path),
        stat: 'testPathPattern'
      });
      data.stats.testPathPattern = 0;
    }

    data.tests = allPaths.filter(test => {
      let filterResult = true;

      for (const {isMatch, stat} of testCases) {
        if (isMatch(test.path)) {
          data.stats[stat]++;
        } else {
          filterResult = false;
        }
      }

      return filterResult;
    });
    return data;
  }

  _getAllTestPaths(testPathPattern) {
    return this._filterTestPathsWithStats(
      toTests(this._context, this._context.hasteFS.getAllFiles()),
      testPathPattern
    );
  }

  isTestFilePath(path) {
    return this._testPathCases.every(testCase => testCase.isMatch(path));
  }

  findMatchingTests(testPathPattern) {
    return this._getAllTestPaths(testPathPattern);
  }

  findRelatedTests(allPaths, collectCoverage) {
    const dependencyResolver = this._getOrBuildDependencyResolver();

    if (!collectCoverage) {
      return {
        tests: toTests(
          this._context,
          dependencyResolver.resolveInverse(
            allPaths,
            this.isTestFilePath.bind(this),
            {
              skipNodeResolution: this._context.config.skipNodeResolution
            }
          )
        )
      };
    }

    const testModulesMap = dependencyResolver.resolveInverseModuleMap(
      allPaths,
      this.isTestFilePath.bind(this),
      {
        skipNodeResolution: this._context.config.skipNodeResolution
      }
    );
    const allPathsAbsolute = Array.from(allPaths).map(p => path().resolve(p));
    const collectCoverageFrom = new Set();
    testModulesMap.forEach(testModule => {
      if (!testModule.dependencies) {
        return;
      }

      testModule.dependencies.forEach(p => {
        if (!allPathsAbsolute.includes(p)) {
          return;
        }

        const filename = (0, _jestConfig().replaceRootDirInPath)(
          this._context.config.rootDir,
          p
        );
        collectCoverageFrom.add(
          path().isAbsolute(filename)
            ? path().relative(this._context.config.rootDir, filename)
            : filename
        );
      });
    });
    return {
      collectCoverageFrom,
      tests: toTests(
        this._context,
        testModulesMap.map(testModule => testModule.file)
      )
    };
  }

  findTestsByPaths(paths) {
    return {
      tests: toTests(
        this._context,
        paths
          .map(p => path().resolve(this._context.config.cwd, p))
          .filter(this.isTestFilePath.bind(this))
      )
    };
  }

  findRelatedTestsFromPattern(paths, collectCoverage) {
    if (Array.isArray(paths) && paths.length) {
      const resolvedPaths = paths.map(p =>
        path().resolve(this._context.config.cwd, p)
      );
      return this.findRelatedTests(new Set(resolvedPaths), collectCoverage);
    }

    return {
      tests: []
    };
  }

  findTestRelatedToChangedFiles(changedFilesInfo, collectCoverage) {
    if (!hasSCM(changedFilesInfo)) {
      return {
        noSCM: true,
        tests: []
      };
    }

    const {changedFiles} = changedFilesInfo;
    return this.findRelatedTests(changedFiles, collectCoverage);
  }

  _getTestPaths(globalConfig, changedFiles) {
    if (globalConfig.onlyChanged) {
      if (!changedFiles) {
        throw new Error('Changed files must be set when running with -o.');
      }

      return this.findTestRelatedToChangedFiles(
        changedFiles,
        globalConfig.collectCoverage
      );
    }

    let paths = globalConfig.nonFlagArgs;

    if (globalConfig.findRelatedTests && 'win32' === os().platform()) {
      const allFiles = this._context.hasteFS.getAllFiles();

      const options = {
        nocase: true,
        windows: false
      };
      paths = paths
        .map(p => {
          const relativePath = path()
            .resolve(this._context.config.cwd, p)
            .replace(/\\/g, '\\\\');
          const match = (0, _micromatch().default)(
            allFiles,
            relativePath,
            options
          );
          return match[0];
        })
        .filter(Boolean);
    }

    if (globalConfig.runTestsByPath && paths && paths.length) {
      return this.findTestsByPaths(paths);
    } else if (globalConfig.findRelatedTests && paths && paths.length) {
      return this.findRelatedTestsFromPattern(
        paths,
        globalConfig.collectCoverage
      );
    } else if (globalConfig.testPathPattern != null) {
      return this.findMatchingTests(globalConfig.testPathPattern);
    } else {
      return {
        tests: []
      };
    }
  }

  async getTestPaths(globalConfig, changedFiles, filter) {
    const searchResult = this._getTestPaths(globalConfig, changedFiles);

    const filterPath = globalConfig.filter;

    if (filter) {
      const tests = searchResult.tests;
      const filterResult = await filter(tests.map(test => test.path));

      if (!Array.isArray(filterResult.filtered)) {
        throw new Error(
          `Filter ${filterPath} did not return a valid test list`
        );
      }

      const filteredSet = new Set(
        filterResult.filtered.map(result => result.test)
      );
      return {
        ...searchResult,
        tests: tests.filter(test => filteredSet.has(test.path))
      };
    }

    return searchResult;
  }

  findRelatedSourcesFromTestsInChangedFiles(changedFilesInfo) {
    if (!hasSCM(changedFilesInfo)) {
      return [];
    }

    const {changedFiles} = changedFilesInfo;

    const dependencyResolver = this._getOrBuildDependencyResolver();

    const relatedSourcesSet = new Set();
    changedFiles.forEach(filePath => {
      if (this.isTestFilePath(filePath)) {
        const sourcePaths = dependencyResolver.resolve(filePath, {
          skipNodeResolution: this._context.config.skipNodeResolution
        });
        sourcePaths.forEach(sourcePath => relatedSourcesSet.add(sourcePath));
      }
    });
    return Array.from(relatedSourcesSet);
  }
}

exports.default = SearchSource;
