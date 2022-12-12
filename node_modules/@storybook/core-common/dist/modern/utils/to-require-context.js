import { globToRegexp } from './glob-to-regexp';
export var toRequireContext = function (specifier) {
  var directory = specifier.directory,
      files = specifier.files; // The importPathMatcher is a `./`-prefixed matcher that includes the directory
  // For `require.context()` we want the same thing, relative to directory

  var match = globToRegexp(`./${files}`);
  return {
    path: directory,
    recursive: files.includes('**') || files.split('/').length > 1,
    match: match
  };
};
export var toRequireContextString = function (specifier) {
  var _toRequireContext = toRequireContext(specifier),
      p = _toRequireContext.path,
      r = _toRequireContext.recursive,
      m = _toRequireContext.match;

  var result = `require.context('${p}', ${r}, ${m})`;
  return result;
};