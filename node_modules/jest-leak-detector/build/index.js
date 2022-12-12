'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _util() {
  const data = require('util');

  _util = function () {
    return data;
  };

  return data;
}

function _v() {
  const data = require('v8');

  _v = function () {
    return data;
  };

  return data;
}

function _vm() {
  const data = require('vm');

  _vm = function () {
    return data;
  };

  return data;
}

function _jestGetType() {
  const data = require('jest-get-type');

  _jestGetType = function () {
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

const tick = (0, _util().promisify)(setImmediate);

class _default {
  constructor(value) {
    _defineProperty(this, '_isReferenceBeingHeld', void 0);

    if ((0, _jestGetType().isPrimitive)(value)) {
      throw new TypeError(
        [
          'Primitives cannot leak memory.',
          'You passed a ' +
            typeof value +
            ': <' +
            (0, _prettyFormat().default)(value) +
            '>'
        ].join(' ')
      );
    }

    let weak;

    try {
      // eslint-disable-next-line import/no-extraneous-dependencies
      weak = require('weak-napi');
    } catch (err) {
      if (!err || err.code !== 'MODULE_NOT_FOUND') {
        throw err;
      }

      throw new Error(
        'The leaking detection mechanism requires the "weak-napi" package to be installed and work. ' +
          'Please install it as a dependency on your main project'
      );
    }

    weak(value, () => (this._isReferenceBeingHeld = false));
    this._isReferenceBeingHeld = true; // Ensure value is not leaked by the closure created by the "weak" callback.

    value = null;
  }

  async isLeaking() {
    this._runGarbageCollector(); // wait some ticks to allow GC to run properly, see https://github.com/nodejs/node/issues/34636#issuecomment-669366235

    for (let i = 0; i < 10; i++) {
      await tick();
    }

    return this._isReferenceBeingHeld;
  }

  _runGarbageCollector() {
    const isGarbageCollectorHidden = !global.gc; // GC is usually hidden, so we have to expose it before running.

    (0, _v().setFlagsFromString)('--expose-gc');
    (0, _vm().runInNewContext)('gc')(); // The GC was not initially exposed, so let's hide it again.

    if (isGarbageCollectorHidden) {
      (0, _v().setFlagsFromString)('--no-expose-gc');
    }
  }
}

exports.default = _default;
