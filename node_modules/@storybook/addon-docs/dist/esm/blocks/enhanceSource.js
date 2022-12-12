function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import "core-js/modules/es.array.join.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.function.name.js";
import { combineParameters } from '@storybook/store'; // ============================================================
// START @storybook/source-loader/extract-source
//
// This code duplicated because tree-shaking isn't working.
// It's not DRY, but source-loader is on the chopping block for
// the next version of addon-docs, so it's not the worst sin.
// ============================================================

/**
 * given a location, extract the text from the full source
 */
function extractSource(location, lines) {
  var start = location.startBody,
      end = location.endBody;

  if (start.line === end.line && lines[start.line - 1] !== undefined) {
    return lines[start.line - 1].substring(start.col, end.col);
  } // NOTE: storysource locations are 1-based not 0-based!


  var startLine = lines[start.line - 1];
  var endLine = lines[end.line - 1];

  if (startLine === undefined || endLine === undefined) {
    return null;
  }

  return [startLine.substring(start.col)].concat(_toConsumableArray(lines.slice(start.line, end.line - 1)), [endLine.substring(0, end.col)]).join('\n');
} // ============================================================
// END @storybook/source-loader/extract-source
// ============================================================


/**
 * Replaces full story id name like: story-kind--story-name -> story-name
 * @param id
 */
var storyIdToSanitizedStoryName = function storyIdToSanitizedStoryName(id) {
  return id.replace(/^.*?--/, '');
};

var extract = function extract(targetId, _ref) {
  var source = _ref.source,
      locationsMap = _ref.locationsMap;

  if (!locationsMap) {
    return source;
  }

  var sanitizedStoryName = storyIdToSanitizedStoryName(targetId);
  var location = locationsMap[sanitizedStoryName];

  if (!location) {
    return source;
  }

  var lines = source.split('\n');
  return extractSource(location, lines);
};

export var enhanceSource = function enhanceSource(story) {
  var _docs$source;

  var id = story.id,
      parameters = story.parameters;
  var storySource = parameters.storySource,
      _parameters$docs = parameters.docs,
      docs = _parameters$docs === void 0 ? {} : _parameters$docs;
  var transformSource = docs.transformSource; // no input or user has manually overridden the output

  if (!(storySource !== null && storySource !== void 0 && storySource.source) || (_docs$source = docs.source) !== null && _docs$source !== void 0 && _docs$source.code) {
    return null;
  }

  var input = extract(id, storySource);
  var code = transformSource ? transformSource(input, story) : input;
  return {
    docs: combineParameters(docs, {
      source: {
        code: code
      }
    })
  };
};