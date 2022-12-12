import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.array.from.js";
var _excluded = ["source"];

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.string.replace.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.string.trim.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.join.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.string.split.js";
import "core-js/modules/es.object.entries.js";
import { storyNameFromExport, sanitize } from '@storybook/csf';
import mapKeys from 'lodash/mapKeys';
import { patchNode } from './parse-helpers';
import getParser from './parsers';
import { splitSTORYOF, findAddsMap, splitExports, popParametersObjectFromDefaultExport, findExportsMap as generateExportsMap } from './traverse-helpers';
import { extractSource } from '../extract-source';
export function sanitizeSource(source) {
  return JSON.stringify(source).replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
}

function isUglyComment(comment, uglyCommentsRegex) {
  return uglyCommentsRegex.some(function (regex) {
    return regex.test(comment);
  });
}

function generateSourceWithoutUglyComments(source, _ref) {
  var comments = _ref.comments,
      uglyCommentsRegex = _ref.uglyCommentsRegex;
  var lastIndex = 0;
  var parts = [source];
  comments.filter(function (comment) {
    return isUglyComment(comment.value.trim(), uglyCommentsRegex);
  }).map(patchNode).forEach(function (comment) {
    parts.pop();
    var start = source.slice(lastIndex, comment.start);
    var end = source.slice(comment.end);
    parts.push(start, end);
    lastIndex = comment.end;
  });
  return parts.join('');
}

function prettifyCode(source, _ref2) {
  var prettierConfig = _ref2.prettierConfig,
      parser = _ref2.parser,
      filepath = _ref2.filepath;
  var config = prettierConfig;
  var foundParser = null;
  if (parser === 'flow') foundParser = 'flow';
  if (parser === 'javascript' || /jsx?/.test(parser)) foundParser = 'javascript';
  if (parser === 'typescript' || /tsx?/.test(parser)) foundParser = 'typescript';

  if (!config.parser) {
    config = Object.assign({}, prettierConfig);
  } else if (filepath) {
    config = Object.assign({}, prettierConfig, {
      filepath: filepath
    });
  } else {
    config = Object.assign({}, prettierConfig);
  }

  try {
    return getParser(foundParser || 'javascript').format(source, config);
  } catch (e) {
    // Can fail when the source is a JSON
    return source;
  }
}

var ADD_PARAMETERS_STATEMENT = '.addParameters({ storySource: { source: __STORY__, locationsMap: __LOCATIONS_MAP__ } })';

var applyExportDecoratorStatement = function applyExportDecoratorStatement(part) {
  return part.declaration.isVariableDeclaration ? " ".concat(part.source, ";") : " const ".concat(part.declaration.ident, " = ").concat(part.source, ";");
};

export function generateSourceWithDecorators(source, ast) {
  var _ast$comments = ast.comments,
      comments = _ast$comments === void 0 ? [] : _ast$comments;
  var partsUsingStoryOfToken = splitSTORYOF(ast, source);

  if (partsUsingStoryOfToken.length > 1) {
    var _newSource = partsUsingStoryOfToken.join(ADD_PARAMETERS_STATEMENT);

    return {
      storyOfTokenFound: true,
      changed: partsUsingStoryOfToken.length > 1,
      source: _newSource,
      comments: comments
    };
  }

  var partsUsingExports = splitExports(ast, source);
  var newSource = partsUsingExports.map(function (part, i) {
    return i % 2 === 0 ? part.source : applyExportDecoratorStatement(part);
  }).join('');
  return {
    exportTokenFound: true,
    changed: partsUsingExports.length > 1,
    source: newSource,
    comments: comments
  };
}
export function generateSourceWithoutDecorators(source, ast) {
  var _ast$comments2 = ast.comments,
      comments = _ast$comments2 === void 0 ? [] : _ast$comments2;
  return {
    changed: true,
    source: source,
    comments: comments
  };
}
export function generateAddsMap(ast, storiesOfIdentifiers) {
  return findAddsMap(ast, storiesOfIdentifiers);
}
export function generateStoriesLocationsMap(ast, storiesOfIdentifiers) {
  var usingAddsMap = generateAddsMap(ast, storiesOfIdentifiers);
  var addsMap = usingAddsMap;

  if (Object.keys(addsMap).length > 0) {
    return usingAddsMap;
  }

  var usingExportsMap = generateExportsMap(ast);
  return usingExportsMap || usingAddsMap;
}
export function generateStorySource(_ref3) {
  var source = _ref3.source,
      options = _objectWithoutProperties(_ref3, _excluded);

  var storySource = source;
  storySource = generateSourceWithoutUglyComments(storySource, options);
  storySource = prettifyCode(storySource, options);
  return storySource;
}

function transformLocationMapToIds(parameters) {
  if (!(parameters !== null && parameters !== void 0 && parameters.locationsMap)) return parameters;
  var locationsMap = mapKeys(parameters.locationsMap, function (_value, key) {
    return sanitize(storyNameFromExport(key));
  });
  return Object.assign({}, parameters, {
    locationsMap: locationsMap
  });
}

export function generateSourcesInExportedParameters(source, ast, additionalParameters) {
  var _popParametersObjectF = popParametersObjectFromDefaultExport(source, ast),
      splicedSource = _popParametersObjectF.splicedSource,
      parametersSliceOfCode = _popParametersObjectF.parametersSliceOfCode,
      indexWhereToAppend = _popParametersObjectF.indexWhereToAppend,
      foundParametersProperty = _popParametersObjectF.foundParametersProperty;

  if (indexWhereToAppend !== -1) {
    var additionalParametersAsJson = JSON.stringify({
      storySource: transformLocationMapToIds(additionalParameters)
    }).slice(0, -1);
    var propertyDeclaration = foundParametersProperty ? '' : 'parameters: ';
    var comma = foundParametersProperty ? '' : ',';
    var newParameters = "".concat(propertyDeclaration).concat(additionalParametersAsJson, ",").concat(parametersSliceOfCode.substring(1)).concat(comma);
    var additionalComma = comma === ',' ? '' : ',';
    var result = "".concat(splicedSource.substring(0, indexWhereToAppend)).concat(newParameters).concat(additionalComma).concat(splicedSource.substring(indexWhereToAppend));
    return result;
  }

  return source;
}

function addStorySourceParameter(key, snippet) {
  var source = sanitizeSource(snippet);
  return "".concat(key, ".parameters = { storySource: { source: ").concat(source, " }, ...").concat(key, ".parameters };");
}

export function generateSourcesInStoryParameters(source, ast, additionalParameters) {
  if (!additionalParameters || !additionalParameters.source || !additionalParameters.locationsMap) {
    return source;
  }

  var sanitizedSource = additionalParameters.source,
      locationsMap = additionalParameters.locationsMap;
  var lines = sanitizedSource.split('\n');
  var suffix = Object.entries(locationsMap).reduce(function (acc, _ref4) {
    var _ref5 = _slicedToArray(_ref4, 2),
        exportName = _ref5[0],
        location = _ref5[1];

    var exportSource = extractSource(location, lines);

    if (exportSource) {
      var generated = addStorySourceParameter(exportName, exportSource);
      return "".concat(acc, "\n").concat(generated);
    }

    return acc;
  }, '');
  return suffix ? "".concat(source, "\n\n").concat(suffix) : source;
}