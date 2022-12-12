"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.isExportStory = isExportStory;
exports.parseKind = exports.storyNameFromExport = exports.toId = exports.sanitize = void 0;

var _startCase = _interopRequireDefault(require("lodash/startCase"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance"); }

function _iterableToArrayLimit(arr, i) { if (!(Symbol.iterator in Object(arr) || Object.prototype.toString.call(arr) === "[object Arguments]")) { return; } var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

/**
 * Remove punctuation and illegal characters from a story ID.
 *
 * See https://gist.github.com/davidjrice/9d2af51100e41c6c4b4a
 */
var sanitize = function sanitize(string) {
  return string.toLowerCase() // eslint-disable-next-line no-useless-escape
  .replace(/[ ’–—―′¿'`~!@#$%^&*()_|+\-=?;:'",.<>\{\}\[\]\\\/]/gi, '-').replace(/-+/g, '-').replace(/^-+/, '').replace(/-+$/, '');
};

exports.sanitize = sanitize;

var sanitizeSafe = function sanitizeSafe(string, part) {
  var sanitized = sanitize(string);

  if (sanitized === '') {
    throw new Error("Invalid ".concat(part, " '").concat(string, "', must include alphanumeric characters"));
  }

  return sanitized;
};
/**
 * Generate a storybook ID from a component/kind and story name.
 */


var toId = function toId(kind, name) {
  return "".concat(sanitizeSafe(kind, 'kind'), "--").concat(sanitizeSafe(name, 'name'));
};
/**
 * Transform a CSF named export into a readable story name
 */


exports.toId = toId;

var storyNameFromExport = function storyNameFromExport(key) {
  return (0, _startCase["default"])(key);
};

exports.storyNameFromExport = storyNameFromExport;

function matches(storyKey, arrayOrRegex) {
  if (Array.isArray(arrayOrRegex)) {
    return arrayOrRegex.includes(storyKey);
  }

  return storyKey.match(arrayOrRegex);
}
/**
 * Does a named export match CSF inclusion/exclusion options?
 */


function isExportStory(key, _ref) {
  var includeStories = _ref.includeStories,
      excludeStories = _ref.excludeStories;
  return (// https://babeljs.io/docs/en/babel-plugin-transform-modules-commonjs
    key !== '__esModule' && (!includeStories || matches(key, includeStories)) && (!excludeStories || !matches(key, excludeStories))
  );
}

/**
 * Parse out the component/kind name from a path, using the given separator config.
 */
var parseKind = function parseKind(kind, _ref2) {
  var rootSeparator = _ref2.rootSeparator,
      groupSeparator = _ref2.groupSeparator;

  var _kind$split = kind.split(rootSeparator, 2),
      _kind$split2 = _slicedToArray(_kind$split, 2),
      root = _kind$split2[0],
      remainder = _kind$split2[1];

  var groups = (remainder || kind).split(groupSeparator).filter(function (i) {
    return !!i;
  }); // when there's no remainder, it means the root wasn't found/split

  return {
    root: remainder ? root : null,
    groups: groups
  };
};

exports.parseKind = parseKind;