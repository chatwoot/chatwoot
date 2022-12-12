'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports._interface = exports.create = void 0;

var _Env = _interopRequireDefault(require('./Env'));

var _JsApiReporter = _interopRequireDefault(require('./JsApiReporter'));

var _ReportDispatcher = _interopRequireDefault(require('./ReportDispatcher'));

var _Spec = _interopRequireDefault(require('./Spec'));

var _Suite = _interopRequireDefault(require('./Suite'));

var _Timer = _interopRequireDefault(require('./Timer'));

var _createSpy = _interopRequireDefault(require('./createSpy'));

var _spyRegistry = _interopRequireDefault(require('./spyRegistry'));

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */
// This file is a heavily modified fork of Jasmine. Original license:

/*
Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* eslint-disable sort-keys, local/prefer-spread-eventually, local/prefer-rest-params-eventually */
const create = function (createOptions) {
  const j$ = {...createOptions};
  j$._DEFAULT_TIMEOUT_INTERVAL = createOptions.testTimeout || 5000;

  j$.getEnv = function (options) {
    const env = (j$.currentEnv_ = j$.currentEnv_ || new j$.Env(options)); //jasmine. singletons in here (setTimeout blah blah).

    return env;
  };

  j$.createSpy = _createSpy.default;
  j$.Env = (0, _Env.default)(j$);
  j$.JsApiReporter = _JsApiReporter.default;
  j$.ReportDispatcher = _ReportDispatcher.default;
  j$.Spec = _Spec.default;
  j$.SpyRegistry = _spyRegistry.default;
  j$.Suite = _Suite.default;
  j$.Timer = _Timer.default;
  j$.version = '2.5.2-light';
  return j$;
}; // Interface is a reserved word in strict mode, so can't export it as ESM

exports.create = create;

const _interface = function (jasmine, env) {
  const jasmineInterface = {
    describe(description, specDefinitions) {
      return env.describe(description, specDefinitions);
    },

    xdescribe(description, specDefinitions) {
      return env.xdescribe(description, specDefinitions);
    },

    fdescribe(description, specDefinitions) {
      return env.fdescribe(description, specDefinitions);
    },

    it() {
      return env.it.apply(env, arguments);
    },

    xit() {
      return env.xit.apply(env, arguments);
    },

    fit() {
      return env.fit.apply(env, arguments);
    },

    beforeEach() {
      if (typeof arguments[0] !== 'function') {
        throw new Error(
          'Invalid first argument. It must be a callback function.'
        );
      }

      return env.beforeEach.apply(env, arguments);
    },

    afterEach() {
      if (typeof arguments[0] !== 'function') {
        throw new Error(
          'Invalid first argument. It must be a callback function.'
        );
      }

      return env.afterEach.apply(env, arguments);
    },

    beforeAll() {
      if (typeof arguments[0] !== 'function') {
        throw new Error(
          'Invalid first argument. It must be a callback function.'
        );
      }

      return env.beforeAll.apply(env, arguments);
    },

    afterAll() {
      if (typeof arguments[0] !== 'function') {
        throw new Error(
          'Invalid first argument. It must be a callback function.'
        );
      }

      return env.afterAll.apply(env, arguments);
    },

    pending() {
      return env.pending.apply(env, arguments);
    },

    fail() {
      return env.fail.apply(env, arguments);
    },

    spyOn(obj, methodName, accessType) {
      return env.spyOn(obj, methodName, accessType);
    },

    jsApiReporter: new jasmine.JsApiReporter({
      timer: new jasmine.Timer()
    }),
    jasmine
  };
  return jasmineInterface;
};

exports._interface = _interface;
