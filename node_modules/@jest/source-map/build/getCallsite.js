'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _callsites() {
  const data = _interopRequireDefault(require('callsites'));

  _callsites = function () {
    return data;
  };

  return data;
}

function _gracefulFs() {
  const data = require('graceful-fs');

  _gracefulFs = function () {
    return data;
  };

  return data;
}

function _sourceMap() {
  const data = require('source-map');

  _sourceMap = function () {
    return data;
  };

  return data;
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
// Copied from https://github.com/rexxars/sourcemap-decorate-callsites/blob/5b9735a156964973a75dc62fd2c7f0c1975458e8/lib/index.js#L113-L158
const addSourceMapConsumer = (callsite, consumer) => {
  const getLineNumber = callsite.getLineNumber;
  const getColumnNumber = callsite.getColumnNumber;
  let position = null;

  function getPosition() {
    if (!position) {
      position = consumer.originalPositionFor({
        column: getColumnNumber.call(callsite) || -1,
        line: getLineNumber.call(callsite) || -1
      });
    }

    return position;
  }

  Object.defineProperties(callsite, {
    getColumnNumber: {
      value() {
        return getPosition().column || getColumnNumber.call(callsite);
      },

      writable: false
    },
    getLineNumber: {
      value() {
        return getPosition().line || getLineNumber.call(callsite);
      },

      writable: false
    }
  });
};

var _default = (level, sourceMaps) => {
  const levelAfterThisCall = level + 1;
  const stack = (0, _callsites().default)()[levelAfterThisCall];
  const sourceMapFileName = sourceMaps && sourceMaps[stack.getFileName() || ''];

  if (sourceMapFileName) {
    try {
      const sourceMap = (0, _gracefulFs().readFileSync)(
        sourceMapFileName,
        'utf8'
      ); // @ts-expect-error: Not allowed to pass string

      addSourceMapConsumer(
        stack,
        new (_sourceMap().SourceMapConsumer)(sourceMap)
      );
    } catch {
      // ignore
    }
  }

  return stack;
};

exports.default = _default;
