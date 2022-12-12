"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.toImportFn = toImportFn;
exports.toImportFnPart = toImportFnPart;
exports.webpackIncludeRegexp = webpackIncludeRegexp;

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _globToRegexp = require("./glob-to-regexp");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function webpackIncludeRegexp(specifier) {
  var directory = specifier.directory,
      files = specifier.files; // It appears webpack passes *something* similar to the absolute path to the file
  // on disk (prefixed with something unknown) to the matcher.
  // We don't want to include the absolute path in our bundle, so we will just pull any leading
  // `./` or `../` off our directory and match on that.
  // It's imperfect as it could match extra things in extremely unusual cases, but it'll do for now.
  // NOTE: directory is "slashed" so will contain only `/` (no `\`), even on windows

  var directoryWithoutLeadingDots = directory.replace(/^(\.+\/)+/, '/');
  var webpackIncludeGlob = ['.', '..'].includes(directory) ? files : `${directoryWithoutLeadingDots}/${files}`;
  var webpackIncludeRegexpWithCaret = (0, _globToRegexp.globToRegexp)(webpackIncludeGlob); // picomatch is creating an exact match, but we are only matching the end of the filename

  return new RegExp(webpackIncludeRegexpWithCaret.source.replace(/^\^/, ''));
}

function toImportFnPart(specifier) {
  var directory = specifier.directory,
      importPathMatcher = specifier.importPathMatcher;
  return (0, _tsDedent.default)`
      async (path) => {
        if (!${importPathMatcher}.exec(path)) {
          return;
        }

        const pathRemainder = path.substring(${directory.length + 1});
        return import(
          /* webpackChunkName: "[request]" */
          /* webpackInclude: ${webpackIncludeRegexp(specifier)} */
          '${directory}/' + pathRemainder
        );
      }

  `;
}

function toImportFn(stories) {
  return (0, _tsDedent.default)`
    const importers = [
      ${stories.map(toImportFnPart).join(',\n')}
    ];

    export async function importFn(path) {
      for (let i = 0; i < importers.length; i++) {
        const moduleExports = await importers[i](path);
        if (moduleExports) {
          return moduleExports;
        }
      }
    }
  `;
}