"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeStoriesEntry = exports.normalizeStories = exports.getDirectoryFromWorkingDir = void 0;

var _fs = _interopRequireDefault(require("fs"));

var _path = _interopRequireDefault(require("path"));

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _picomatch = require("picomatch");

var _slash = _interopRequireDefault(require("slash"));

var _paths = require("./paths");

var _globToRegexp = require("./glob-to-regexp");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var DEFAULT_TITLE_PREFIX = '';
var DEFAULT_FILES = '**/*.stories.@(mdx|tsx|ts|jsx|js)'; // LEGACY support for bad glob patterns we had in SB 5 - remove in SB7

var fixBadGlob = (0, _utilDeprecate.default)(function (match) {
  return match.input.replace(match[1], `@${match[1]}`);
}, (0, _tsDedent.default)`
    You have specified an invalid glob, we've attempted to fix it, please ensure that the glob you specify is valid. See: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#correct-globs-in-mainjs
  `);

var detectBadGlob = function (val) {
  var match = val.match(/\.(\([^)]+\))/);

  if (match) {
    return fixBadGlob(match);
  }

  return val;
};

var isDirectory = function (configDir, entry) {
  try {
    return _fs.default.lstatSync(_path.default.resolve(configDir, entry)).isDirectory();
  } catch (err) {
    return false;
  }
};

var getDirectoryFromWorkingDir = function ({
  configDir: configDir,
  workingDir: workingDir,
  directory: directory
}) {
  var directoryFromConfig = _path.default.resolve(configDir, directory);

  var directoryFromWorking = _path.default.relative(workingDir, directoryFromConfig); // relative('/foo', '/foo/src') => 'src'
  // but we want `./src` to match importPaths


  return (0, _paths.normalizeStoryPath)(directoryFromWorking);
};

exports.getDirectoryFromWorkingDir = getDirectoryFromWorkingDir;

var normalizeStoriesEntry = function (entry, {
  configDir: configDir,
  workingDir: workingDir
}) {
  var specifierWithoutMatcher;

  if (typeof entry === 'string') {
    var fixedEntry = detectBadGlob(entry);
    var globResult = (0, _picomatch.scan)(fixedEntry);

    if (globResult.isGlob) {
      var _directory = globResult.prefix + globResult.base;

      var _files = globResult.glob;
      specifierWithoutMatcher = {
        titlePrefix: DEFAULT_TITLE_PREFIX,
        directory: _directory,
        files: _files
      };
    } else if (isDirectory(configDir, entry)) {
      specifierWithoutMatcher = {
        titlePrefix: DEFAULT_TITLE_PREFIX,
        directory: entry,
        files: DEFAULT_FILES
      };
    } else {
      specifierWithoutMatcher = {
        titlePrefix: DEFAULT_TITLE_PREFIX,
        directory: _path.default.dirname(entry),
        files: _path.default.basename(entry)
      };
    }
  } else {
    specifierWithoutMatcher = _objectSpread({
      titlePrefix: DEFAULT_TITLE_PREFIX,
      files: DEFAULT_FILES
    }, entry);
  } // We are going to be doing everything with node importPaths which use
  // URL format, i.e. `/` as a separator, so let's make sure we've normalized


  var files = (0, _slash.default)(specifierWithoutMatcher.files); // At this stage `directory` is relative to `main.js` (the config dir)
  // We want to work relative to the working dir, so we transform it here.

  var _specifierWithoutMatc = specifierWithoutMatcher,
      directoryRelativeToConfig = _specifierWithoutMatc.directory;
  var directory = (0, _slash.default)(getDirectoryFromWorkingDir({
    configDir: configDir,
    workingDir: workingDir,
    directory: directoryRelativeToConfig
  })).replace(/\/$/, ''); // Now make the importFn matcher.

  var importPathMatcher = (0, _globToRegexp.globToRegexp)(`${directory}/${files}`);
  return _objectSpread(_objectSpread({}, specifierWithoutMatcher), {}, {
    directory: directory,
    importPathMatcher: importPathMatcher
  });
};

exports.normalizeStoriesEntry = normalizeStoriesEntry;

var normalizeStories = function (entries, options) {
  return entries.map(function (entry) {
    return normalizeStoriesEntry(entry, options);
  });
};

exports.normalizeStories = normalizeStories;