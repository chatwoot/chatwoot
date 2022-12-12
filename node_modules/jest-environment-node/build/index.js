'use strict';

function _vm() {
  const data = require('vm');

  _vm = function () {
    return data;
  };

  return data;
}

function _fakeTimers() {
  const data = require('@jest/fake-timers');

  _fakeTimers = function () {
    return data;
  };

  return data;
}

function _jestMock() {
  const data = require('jest-mock');

  _jestMock = function () {
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

class NodeEnvironment {
  constructor(config) {
    _defineProperty(this, 'context', void 0);

    _defineProperty(this, 'fakeTimers', void 0);

    _defineProperty(this, 'fakeTimersModern', void 0);

    _defineProperty(this, 'global', void 0);

    _defineProperty(this, 'moduleMocker', void 0);

    this.context = (0, _vm().createContext)();
    const global = (this.global = (0, _vm().runInContext)(
      'this',
      Object.assign(this.context, config.testEnvironmentOptions)
    ));
    global.global = global;
    global.clearInterval = clearInterval;
    global.clearTimeout = clearTimeout;
    global.setInterval = setInterval;
    global.setTimeout = setTimeout;
    global.ArrayBuffer = ArrayBuffer; // TextEncoder (global or via 'util') references a Uint8Array constructor
    // different than the global one used by users in tests. This makes sure the
    // same constructor is referenced by both.

    global.Uint8Array = Uint8Array; // URL and URLSearchParams are global in Node >= 10

    if (typeof URL !== 'undefined' && typeof URLSearchParams !== 'undefined') {
      global.URL = URL;
      global.URLSearchParams = URLSearchParams;
    } // TextDecoder and TextDecoder are global in Node >= 11

    if (
      typeof TextEncoder !== 'undefined' &&
      typeof TextDecoder !== 'undefined'
    ) {
      global.TextEncoder = TextEncoder;
      global.TextDecoder = TextDecoder;
    } // queueMicrotask is global in Node >= 11

    if (typeof queueMicrotask !== 'undefined') {
      global.queueMicrotask = queueMicrotask;
    }

    (0, _jestUtil().installCommonGlobals)(global, config.globals);
    this.moduleMocker = new (_jestMock().ModuleMocker)(global);

    const timerIdToRef = id => ({
      id,

      ref() {
        return this;
      },

      unref() {
        return this;
      }
    });

    const timerRefToId = timer => (timer && timer.id) || undefined;

    const timerConfig = {
      idToRef: timerIdToRef,
      refToId: timerRefToId
    };
    this.fakeTimers = new (_fakeTimers().LegacyFakeTimers)({
      config,
      global,
      moduleMocker: this.moduleMocker,
      timerConfig
    });
    this.fakeTimersModern = new (_fakeTimers().ModernFakeTimers)({
      config,
      global
    });
  }

  async setup() {}

  async teardown() {
    if (this.fakeTimers) {
      this.fakeTimers.dispose();
    }

    if (this.fakeTimersModern) {
      this.fakeTimersModern.dispose();
    }

    this.context = null;
    this.fakeTimers = null;
    this.fakeTimersModern = null;
  } // TS infers the return type to be `any`, since that's what `runInContext`
  // returns.

  runScript(script) {
    if (this.context) {
      return script.runInContext(this.context);
    }

    return null;
  }

  getVmContext() {
    return this.context;
  }
}

module.exports = NodeEnvironment;
