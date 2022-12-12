import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.freeze.js";

var _templateObject;

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.regexp.constructor.js";
import "core-js/modules/es.regexp.to-string.js";
import "core-js/modules/es.string.replace.js";
import "core-js/modules/es.array.join.js";
import "core-js/modules/es.string.split.js";

function _toArray(arr) { return _arrayWithHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import slash from 'slash';
import dedent from 'ts-dedent';
import { once } from '@storybook/client-logger'; // FIXME: types duplicated type from `core-common', to be
// removed when we remove v6 back-compat.

var stripExtension = function stripExtension(path) {
  var parts = _toConsumableArray(path);

  var last = parts[parts.length - 1];
  var dotIndex = last.indexOf('.');
  var stripped = dotIndex > 0 ? last.substr(0, dotIndex) : last;
  parts[parts.length - 1] = stripped;

  var _parts = parts,
      _parts2 = _toArray(_parts),
      first = _parts2[0],
      rest = _parts2.slice(1);

  if (first === '') {
    parts = rest;
  }

  return parts;
};

var indexRe = /^index$/i; // deal with files like "atoms/button/{button,index}.stories.js"

var removeRedundantFilename = function removeRedundantFilename(paths) {
  var prevVal;
  return paths.filter(function (val, index) {
    if (index === paths.length - 1 && (val === prevVal || indexRe.test(val))) {
      return false;
    }

    prevVal = val;
    return true;
  });
};
/**
 * Combines path parts together, without duplicating separators (slashes).  Used instead of `path.join`
 * because this code runs in the browser.
 *
 * @param paths array of paths to join together.
 * @returns joined path string, with single '/' between parts
 */


function pathJoin(paths) {
  var slashes = new RegExp('/{1,}', 'g');
  return paths.join('/').replace(slashes, '/');
}

export var userOrAutoTitleFromSpecifier = function userOrAutoTitleFromSpecifier(fileName, entry, userTitle) {
  var _ref = entry || {},
      directory = _ref.directory,
      importPathMatcher = _ref.importPathMatcher,
      _ref$titlePrefix = _ref.titlePrefix,
      titlePrefix = _ref$titlePrefix === void 0 ? '' : _ref$titlePrefix; // On Windows, backslashes are used in paths, which can cause problems here
  // slash makes sure we always handle paths with unix-style forward slash


  if (typeof fileName === 'number') {
    once.warn(dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n      CSF Auto-title received a numeric fileName. This typically happens when\n      webpack is mis-configured in production mode. To force webpack to produce\n      filenames, set optimization.moduleIds = \"named\" in your webpack config.\n    "]))));
  }

  var normalizedFileName = slash(String(fileName));

  if (importPathMatcher.exec(normalizedFileName)) {
    if (!userTitle) {
      var suffix = normalizedFileName.replace(directory, '');
      var titleAndSuffix = slash(pathJoin([titlePrefix, suffix]));
      var path = titleAndSuffix.split('/');
      path = stripExtension(path);
      path = removeRedundantFilename(path);
      return path.join('/');
    }

    if (!titlePrefix) {
      return userTitle;
    }

    return slash(pathJoin([titlePrefix, userTitle]));
  }

  return undefined;
};
export var userOrAutoTitle = function userOrAutoTitle(fileName, storiesEntries, userTitle) {
  for (var i = 0; i < storiesEntries.length; i += 1) {
    var title = userOrAutoTitleFromSpecifier(fileName, storiesEntries[i], userTitle);
    if (title) return title;
  }

  return userTitle || undefined;
};