'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = collectHandles;
exports.formatHandleErrors = formatHandleErrors;

function asyncHooks() {
  const data = _interopRequireWildcard(require('async_hooks'));

  asyncHooks = function () {
    return data;
  };

  return data;
}

function _stripAnsi() {
  const data = _interopRequireDefault(require('strip-ansi'));

  _stripAnsi = function () {
    return data;
  };

  return data;
}

function _jestMessageUtil() {
  const data = require('jest-message-util');

  _jestMessageUtil = function () {
    return data;
  };

  return data;
}

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
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
 */

/* eslint-disable local/ban-types-eventually */
function stackIsFromUser(stack) {
  // Either the test file, or something required by it
  if (stack.includes('Runtime.requireModule')) {
    return true;
  } // jest-jasmine it or describe call

  if (stack.includes('asyncJestTest') || stack.includes('asyncJestLifecycle')) {
    return true;
  } // An async function call from within circus

  if (stack.includes('callAsyncCircusFn')) {
    // jest-circus it or describe call
    return (
      stack.includes('_callCircusTest') || stack.includes('_callCircusHook')
    );
  }

  return false;
}

const alwaysActive = () => true; // Inspired by https://github.com/mafintosh/why-is-node-running/blob/master/index.js
// Extracted as we want to format the result ourselves

function collectHandles() {
  const activeHandles = new Map();
  const hook = asyncHooks().createHook({
    destroy(asyncId) {
      activeHandles.delete(asyncId);
    },

    init: function initHook(asyncId, type, _triggerAsyncId, resource) {
      if (
        type === 'PROMISE' ||
        type === 'TIMERWRAP' ||
        type === 'ELDHISTOGRAM'
      ) {
        return;
      }

      const error = new (_jestUtil().ErrorWithStack)(type, initHook);

      if (stackIsFromUser(error.stack || '')) {
        let isActive;

        if (type === 'Timeout' || type === 'Immediate') {
          if ('hasRef' in resource) {
            // Timer that supports hasRef (Node v11+)
            // @ts-expect-error: doesn't exist in v10 typings
            isActive = resource.hasRef.bind(resource);
          } else {
            // Timer that doesn't support hasRef
            isActive = alwaysActive;
          }
        } else {
          // Any other async resource
          isActive = alwaysActive;
        }

        activeHandles.set(asyncId, {
          error,
          isActive
        });
      }
    }
  });
  hook.enable();
  return () => {
    hook.disable(); // Get errors for every async resource still referenced at this moment

    const result = Array.from(activeHandles.values())
      .filter(({isActive}) => isActive())
      .map(({error}) => error);
    activeHandles.clear();
    return result;
  };
}

function formatHandleErrors(errors, config) {
  const stacks = new Set();
  return (
    errors
      .map(err =>
        (0, _jestMessageUtil().formatExecError)(
          err,
          config,
          {
            noStackTrace: false
          },
          undefined,
          true
        )
      ) // E.g. timeouts might give multiple traces to the same line of code
      // This hairy filtering tries to remove entries with duplicate stack traces
      .filter(handle => {
        const ansiFree = (0, _stripAnsi().default)(handle);
        const match = ansiFree.match(/\s+at(.*)/);

        if (!match || match.length < 2) {
          return true;
        }

        const stack = ansiFree.substr(ansiFree.indexOf(match[1])).trim();

        if (stacks.has(stack)) {
          return false;
        }

        stacks.add(stack);
        return true;
      })
  );
}
