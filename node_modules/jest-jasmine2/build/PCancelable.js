'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;
var Symbol = global['jest-symbol-do-not-touch'] || global.Symbol;
var Symbol = global['jest-symbol-do-not-touch'] || global.Symbol;
var Promise = global[Symbol.for('jest-native-promise')] || global.Promise;

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }
  return obj;
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
class CancelError extends Error {
  constructor() {
    super('Promise was canceled');
    this.name = 'CancelError';
  }
}

class PCancelable extends Promise {
  constructor(executor) {
    super(resolve => resolve());

    _defineProperty(this, '_pending', true);

    _defineProperty(this, '_canceled', false);

    _defineProperty(this, '_promise', void 0);

    _defineProperty(this, '_cancel', void 0);

    _defineProperty(this, '_reject', () => {});

    this._promise = new Promise((resolve, reject) => {
      this._reject = reject;
      return executor(
        fn => {
          this._cancel = fn;
        },
        val => {
          this._pending = false;
          resolve(val);
        },
        err => {
          this._pending = false;
          reject(err);
        }
      );
    });
  }

  then(onFulfilled, onRejected) {
    return this._promise.then(onFulfilled, onRejected);
  }

  catch(onRejected) {
    return this._promise.catch(onRejected);
  }

  cancel() {
    if (!this._pending || this._canceled) {
      return;
    }

    if (typeof this._cancel === 'function') {
      try {
        this._cancel();
      } catch (err) {
        this._reject(err);
      }
    }

    this._canceled = true;

    this._reject(new CancelError());
  }
}

exports.default = PCancelable;
