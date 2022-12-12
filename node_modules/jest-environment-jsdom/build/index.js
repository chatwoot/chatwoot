'use strict';

function _jsdom() {
  const data = require('jsdom');

  _jsdom = function () {
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

class JSDOMEnvironment {
  constructor(config, options = {}) {
    _defineProperty(this, 'dom', void 0);

    _defineProperty(this, 'fakeTimers', void 0);

    _defineProperty(this, 'fakeTimersModern', void 0);

    _defineProperty(this, 'global', void 0);

    _defineProperty(this, 'errorEventListener', void 0);

    _defineProperty(this, 'moduleMocker', void 0);

    this.dom = new (_jsdom().JSDOM)('<!DOCTYPE html>', {
      pretendToBeVisual: true,
      runScripts: 'dangerously',
      url: config.testURL,
      virtualConsole: new (_jsdom().VirtualConsole)().sendTo(
        options.console || console
      ),
      ...config.testEnvironmentOptions
    });
    const global = (this.global = this.dom.window.document.defaultView);

    if (!global) {
      throw new Error('JSDOM did not return a Window object');
    } // In the `jsdom@16`, ArrayBuffer was not added to Window, ref: https://github.com/jsdom/jsdom/commit/3a4fd6258e6b13e9cf8341ddba60a06b9b5c7b5b
    // Install ArrayBuffer to Window to fix it. Make sure the test is passed, ref: https://github.com/facebook/jest/pull/7626

    global.ArrayBuffer = ArrayBuffer; // Node's error-message stack size is limited at 10, but it's pretty useful
    // to see more than that when a test fails.

    this.global.Error.stackTraceLimit = 100;
    (0, _jestUtil().installCommonGlobals)(global, config.globals); // Report uncaught errors.

    this.errorEventListener = event => {
      if (userErrorListenerCount === 0 && event.error) {
        process.emit('uncaughtException', event.error);
      }
    };

    global.addEventListener('error', this.errorEventListener); // However, don't report them as uncaught if the user listens to 'error' event.
    // In that case, we assume the might have custom error handling logic.

    const originalAddListener = global.addEventListener;
    const originalRemoveListener = global.removeEventListener;
    let userErrorListenerCount = 0;

    global.addEventListener = function (...args) {
      if (args[0] === 'error') {
        userErrorListenerCount++;
      }

      return originalAddListener.apply(this, args);
    };

    global.removeEventListener = function (...args) {
      if (args[0] === 'error') {
        userErrorListenerCount--;
      }

      return originalRemoveListener.apply(this, args);
    };

    this.moduleMocker = new (_jestMock().ModuleMocker)(global);
    const timerConfig = {
      idToRef: id => id,
      refToId: ref => ref
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

    if (this.global) {
      if (this.errorEventListener) {
        this.global.removeEventListener('error', this.errorEventListener);
      } // Dispose "document" to prevent "load" event from triggering.

      Object.defineProperty(this.global, 'document', {
        value: null
      });
      this.global.close();
    }

    this.errorEventListener = null; // @ts-expect-error

    this.global = null;
    this.dom = null;
    this.fakeTimers = null;
    this.fakeTimersModern = null;
  }

  runScript(script) {
    if (this.dom) {
      return script.runInContext(this.dom.getInternalVMContext());
    }

    return null;
  }

  getVmContext() {
    if (this.dom) {
      return this.dom.getInternalVMContext();
    }

    return null;
  }
}

module.exports = JSDOMEnvironment;
