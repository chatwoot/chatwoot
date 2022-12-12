'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _fakeTimers() {
  const data = require('@sinonjs/fake-timers');

  _fakeTimers = function () {
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

class FakeTimers {
  constructor({global, config, maxLoops}) {
    _defineProperty(this, '_clock', void 0);

    _defineProperty(this, '_config', void 0);

    _defineProperty(this, '_fakingTime', void 0);

    _defineProperty(this, '_global', void 0);

    _defineProperty(this, '_fakeTimers', void 0);

    _defineProperty(this, '_maxLoops', void 0);

    this._global = global;
    this._config = config;
    this._maxLoops = maxLoops || 100000;
    this._fakingTime = false;
    this._fakeTimers = (0, _fakeTimers().withGlobal)(global);
  }

  clearAllTimers() {
    if (this._fakingTime) {
      this._clock.reset();
    }
  }

  dispose() {
    this.useRealTimers();
  }

  runAllTimers() {
    if (this._checkFakeTimers()) {
      this._clock.runAll();
    }
  }

  runOnlyPendingTimers() {
    if (this._checkFakeTimers()) {
      this._clock.runToLast();
    }
  }

  advanceTimersToNextTimer(steps = 1) {
    if (this._checkFakeTimers()) {
      for (let i = steps; i > 0; i--) {
        this._clock.next(); // Fire all timers at this point: https://github.com/sinonjs/fake-timers/issues/250

        this._clock.tick(0);

        if (this._clock.countTimers() === 0) {
          break;
        }
      }
    }
  }

  advanceTimersByTime(msToRun) {
    if (this._checkFakeTimers()) {
      this._clock.tick(msToRun);
    }
  }

  runAllTicks() {
    if (this._checkFakeTimers()) {
      // @ts-expect-error
      this._clock.runMicrotasks();
    }
  }

  useRealTimers() {
    if (this._fakingTime) {
      this._clock.uninstall();

      this._fakingTime = false;
    }
  }

  useFakeTimers() {
    if (!this._fakingTime) {
      const toFake = Object.keys(this._fakeTimers.timers);
      this._clock = this._fakeTimers.install({
        loopLimit: this._maxLoops,
        now: Date.now(),
        target: this._global,
        toFake
      });
      this._fakingTime = true;
    }
  }

  reset() {
    if (this._checkFakeTimers()) {
      const {now} = this._clock;

      this._clock.reset();

      this._clock.setSystemTime(now);
    }
  }

  setSystemTime(now) {
    if (this._checkFakeTimers()) {
      this._clock.setSystemTime(now);
    }
  }

  getRealSystemTime() {
    return Date.now();
  }

  getTimerCount() {
    if (this._checkFakeTimers()) {
      return this._clock.countTimers();
    }

    return 0;
  }

  _checkFakeTimers() {
    if (!this._fakingTime) {
      this._global.console.warn(
        'A function to advance timers was called but the timers API is not ' +
          'mocked with fake timers. Call `jest.useFakeTimers()` in this test or ' +
          'enable fake timers globally by setting `"timers": "fake"` in the ' +
          'configuration file\nStack Trace:\n' +
          (0, _jestMessageUtil().formatStackTrace)(
            new Error().stack,
            this._config,
            {
              noStackTrace: false
            }
          )
      );
    }

    return this._fakingTime;
  }
}

exports.default = FakeTimers;
