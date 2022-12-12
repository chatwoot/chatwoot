function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

import "core-js/modules/es.array.find.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.array.includes.js";
import "core-js/modules/es.string.includes.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.regexp.exec.js";
import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

import { EventEmitter } from 'events';
import { DOCS_RENDERED, STORY_ERRORED, STORY_MISSING, STORY_RENDERED, STORY_RENDER_PHASE_CHANGED, STORY_THREW_EXCEPTION } from '@storybook/core-events';
export var componentOneExports = {
  default: {
    title: 'Component One',
    argTypes: {
      foo: {
        type: {
          name: 'string'
        }
      }
    },
    loaders: [jest.fn()],
    parameters: {
      docs: {
        container: jest.fn()
      }
    }
  },
  a: {
    args: {
      foo: 'a'
    },
    play: jest.fn()
  },
  b: {
    args: {
      foo: 'b'
    },
    play: jest.fn()
  }
};
export var componentTwoExports = {
  default: {
    title: 'Component Two'
  },
  c: {
    args: {
      foo: 'c'
    }
  }
};
export var importFn = jest.fn( /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(path) {
    return regeneratorRuntime.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            return _context.abrupt("return", path === './src/ComponentOne.stories.js' ? componentOneExports : componentTwoExports);

          case 1:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function (_x) {
    return _ref.apply(this, arguments);
  };
}());
export var projectAnnotations = {
  globals: {
    a: 'b'
  },
  globalTypes: {},
  decorators: [jest.fn(function (s) {
    return s();
  })],
  render: jest.fn(),
  renderToDOM: jest.fn()
};
export var getProjectAnnotations = function getProjectAnnotations() {
  return projectAnnotations;
};
export var storyIndex = {
  v: 3,
  stories: {
    'component-one--a': {
      id: 'component-one--a',
      title: 'Component One',
      name: 'A',
      importPath: './src/ComponentOne.stories.js'
    },
    'component-one--b': {
      id: 'component-one--b',
      title: 'Component One',
      name: 'B',
      importPath: './src/ComponentOne.stories.js'
    },
    'component-two--c': {
      id: 'component-two--c',
      title: 'Component Two',
      name: 'C',
      importPath: './src/ComponentTwo.stories.js'
    }
  }
};
export var getStoryIndex = function getStoryIndex() {
  return storyIndex;
};
export var emitter = new EventEmitter();
export var mockChannel = {
  on: emitter.on.bind(emitter),
  off: emitter.off.bind(emitter),
  removeListener: emitter.off.bind(emitter),
  emit: jest.fn(emitter.emit.bind(emitter)) // emit: emitter.emit.bind(emitter),

};
export var waitForEvents = function waitForEvents(events) {
  var predicate = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : function () {
    return true;
  };

  // We've already emitted a render event. NOTE if you want to test a second call,
  // ensure you call `mockChannel.emit.mockClear()` before `waitFor...`
  if (mockChannel.emit.mock.calls.find(function (call) {
    return events.includes(call[0]) && predicate.apply(void 0, _toConsumableArray(call.slice(1)));
  })) {
    return Promise.resolve(null);
  }

  return new Promise(function (resolve, reject) {
    var listener = function listener() {
      if (!predicate.apply(void 0, arguments)) return;
      events.forEach(function (event) {
        return mockChannel.off(event, listener);
      });
      resolve(null);
    };

    events.forEach(function (event) {
      return mockChannel.on(event, listener);
    }); // Don't wait too long

    waitForQuiescence().then(function () {
      return reject(new Error('Event was not emitted in time'));
    });
  });
}; // The functions on the preview that trigger rendering don't wait for
// the async parts, so we need to listen for the "done" events

export var waitForRender = function waitForRender() {
  return waitForEvents([STORY_RENDERED, DOCS_RENDERED, STORY_THREW_EXCEPTION, STORY_ERRORED, STORY_MISSING]);
};
export var waitForRenderPhase = function waitForRenderPhase(phase) {
  return waitForEvents([STORY_RENDER_PHASE_CHANGED], function (_ref2) {
    var newPhase = _ref2.newPhase;
    return newPhase === phase;
  });
}; // A little trick to ensure that we always call the real `setTimeout` even when timers are mocked

var realSetTimeout = setTimeout;
export var waitForQuiescence = /*#__PURE__*/function () {
  var _ref3 = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
    return regeneratorRuntime.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            return _context2.abrupt("return", new Promise(function (r) {
              return realSetTimeout(r, 100);
            }));

          case 1:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2);
  }));

  return function waitForQuiescence() {
    return _ref3.apply(this, arguments);
  };
}();