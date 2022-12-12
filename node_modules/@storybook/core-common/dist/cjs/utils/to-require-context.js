"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.toRequireContextString = exports.toRequireContext = void 0;

var _globToRegexp = require("./glob-to-regexp");

var toRequireContext = function (specifier) {
  var directory = specifier.directory,
      files = specifier.files; // The importPathMatcher is a `./`-prefixed matcher that includes the directory
  // For `require.context()` we want the same thing, relative to directory

  var match = (0, _globToRegexp.globToRegexp)(`./${files}`);
  return {
    path: directory,
    recursive: files.includes('**') || files.split('/').length > 1,
    match: match
  };
};

exports.toRequireContext = toRequireContext;

var toRequireContextString = function (specifier) {
  var _toRequireContext = toRequireContext(specifier),
      p = _toRequireContext.path,
      r = _toRequireContext.recursive,
      m = _toRequireContext.match;

  var result = `require.context('${p}', ${r}, ${m})`;
  return result;
};

exports.toRequireContextString = toRequireContextString;