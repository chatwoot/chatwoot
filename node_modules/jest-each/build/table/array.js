'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function util() {
  const data = _interopRequireWildcard(require('util'));

  util = function () {
    return data;
  };

  return data;
}

function _prettyFormat() {
  const data = _interopRequireDefault(require('pretty-format'));

  _prettyFormat = function () {
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

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
const SUPPORTED_PLACEHOLDERS = /%[sdifjoOp%]/g;
const PRETTY_PLACEHOLDER = '%p';
const INDEX_PLACEHOLDER = '%#';
const PLACEHOLDER_PREFIX = '%';
const JEST_EACH_PLACEHOLDER_ESCAPE = '@@__JEST_EACH_PLACEHOLDER_ESCAPE__@@';

var _default = (title, arrayTable) =>
  normaliseTable(arrayTable).map((row, index) => ({
    arguments: row,
    title: formatTitle(title, row, index)
  }));

exports.default = _default;

const normaliseTable = table => (isTable(table) ? table : table.map(colToRow));

const isTable = table => table.every(Array.isArray);

const colToRow = col => [col];

const formatTitle = (title, row, rowIndex) =>
  row
    .reduce((formattedTitle, value) => {
      const [placeholder] = getMatchingPlaceholders(formattedTitle);
      const normalisedValue = normalisePlaceholderValue(value);
      if (!placeholder) return formattedTitle;
      if (placeholder === PRETTY_PLACEHOLDER)
        return interpolatePrettyPlaceholder(formattedTitle, normalisedValue);
      return util().format(formattedTitle, normalisedValue);
    }, interpolateTitleIndex(title, rowIndex))
    .replace(new RegExp(JEST_EACH_PLACEHOLDER_ESCAPE, 'g'), PLACEHOLDER_PREFIX);

const normalisePlaceholderValue = value =>
  typeof value === 'string' && SUPPORTED_PLACEHOLDERS.test(value)
    ? value.replace(PLACEHOLDER_PREFIX, JEST_EACH_PLACEHOLDER_ESCAPE)
    : value;

const getMatchingPlaceholders = title =>
  title.match(SUPPORTED_PLACEHOLDERS) || [];

const interpolateTitleIndex = (title, index) =>
  title.replace(INDEX_PLACEHOLDER, index.toString());

const interpolatePrettyPlaceholder = (title, value) =>
  title.replace(
    PRETTY_PLACEHOLDER,
    (0, _prettyFormat().default)(value, {
      maxDepth: 1,
      min: true
    })
  );
