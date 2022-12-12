function ownKeys(object, enumerableOnly) { var keys = Object.keys(object); if (Object.getOwnPropertySymbols) { var symbols = Object.getOwnPropertySymbols(object); enumerableOnly && (symbols = symbols.filter(function (sym) { return Object.getOwnPropertyDescriptor(object, sym).enumerable; })), keys.push.apply(keys, symbols); } return keys; }

function _objectSpread(target) { for (var i = 1; i < arguments.length; i++) { var source = null != arguments[i] ? arguments[i] : {}; i % 2 ? ownKeys(Object(source), !0).forEach(function (key) { _defineProperty(target, key, source[key]); }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function (key) { Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key)); }); } return target; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

import fs from 'fs';
import path from 'path';
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import { scan } from 'picomatch';
import slash from 'slash';
import { normalizeStoryPath } from './paths';
import { globToRegexp } from './glob-to-regexp';
var DEFAULT_TITLE_PREFIX = '';
var DEFAULT_FILES = '**/*.stories.@(mdx|tsx|ts|jsx|js)'; // LEGACY support for bad glob patterns we had in SB 5 - remove in SB7

var fixBadGlob = deprecate(function (match) {
  return match.input.replace(match[1], `@${match[1]}`);
}, dedent`
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
    return fs.lstatSync(path.resolve(configDir, entry)).isDirectory();
  } catch (err) {
    return false;
  }
};

export var getDirectoryFromWorkingDir = function ({
  configDir: configDir,
  workingDir: workingDir,
  directory: directory
}) {
  var directoryFromConfig = path.resolve(configDir, directory);
  var directoryFromWorking = path.relative(workingDir, directoryFromConfig); // relative('/foo', '/foo/src') => 'src'
  // but we want `./src` to match importPaths

  return normalizeStoryPath(directoryFromWorking);
};
export var normalizeStoriesEntry = function (entry, {
  configDir: configDir,
  workingDir: workingDir
}) {
  var specifierWithoutMatcher;

  if (typeof entry === 'string') {
    var fixedEntry = detectBadGlob(entry);
    var globResult = scan(fixedEntry);

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
        directory: path.dirname(entry),
        files: path.basename(entry)
      };
    }
  } else {
    specifierWithoutMatcher = _objectSpread({
      titlePrefix: DEFAULT_TITLE_PREFIX,
      files: DEFAULT_FILES
    }, entry);
  } // We are going to be doing everything with node importPaths which use
  // URL format, i.e. `/` as a separator, so let's make sure we've normalized


  var files = slash(specifierWithoutMatcher.files); // At this stage `directory` is relative to `main.js` (the config dir)
  // We want to work relative to the working dir, so we transform it here.

  var _specifierWithoutMatc = specifierWithoutMatcher,
      directoryRelativeToConfig = _specifierWithoutMatc.directory;
  var directory = slash(getDirectoryFromWorkingDir({
    configDir: configDir,
    workingDir: workingDir,
    directory: directoryRelativeToConfig
  })).replace(/\/$/, ''); // Now make the importFn matcher.

  var importPathMatcher = globToRegexp(`${directory}/${files}`);
  return _objectSpread(_objectSpread({}, specifierWithoutMatcher), {}, {
    directory: directory,
    importPathMatcher: importPathMatcher
  });
};
export var normalizeStories = function (entries, options) {
  return entries.map(function (entry) {
    return normalizeStoriesEntry(entry, options);
  });
};