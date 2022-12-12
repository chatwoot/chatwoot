"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Preview = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.set.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.object.keys.js");

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _global = _interopRequireDefault(require("global"));

var _synchronousPromise = require("synchronous-promise");

var _coreEvents = require("@storybook/core-events");

var _clientLogger = require("@storybook/client-logger");

var _addons = require("@storybook/addons");

var _store = require("@storybook/store");

var _StoryRender = require("./StoryRender");

var _templateObject, _templateObject2;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

var fetch = _global.default.fetch;
var STORY_INDEX_PATH = './stories.json';

var Preview = /*#__PURE__*/function () {
  function Preview() {
    var _global$FEATURES;

    _classCallCheck(this, Preview);

    this.channel = void 0;
    this.serverChannel = void 0;
    this.storyStore = void 0;
    this.getStoryIndex = void 0;
    this.importFn = void 0;
    this.renderToDOM = void 0;
    this.storyRenders = [];
    this.previewEntryError = void 0;
    this.channel = _addons.addons.getChannel();

    if ((_global$FEATURES = _global.default.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.storyStoreV7 && _addons.addons.hasServerChannel()) {
      this.serverChannel = _addons.addons.getServerChannel();
    }

    this.storyStore = new _store.StoryStore();
  } // INITIALIZATION
  // NOTE: the reason that the preview and store's initialization code is written in a promise
  // style and not `async-await`, and the use of `SynchronousPromise`s is in order to allow
  // storyshots to immediately call `raw()` on the store without waiting for a later tick.
  // (Even simple things like `Promise.resolve()` and `await` involve the callback happening
  // in the next promise "tick").
  // See the comment in `storyshots-core/src/api/index.ts` for more detail.


  _createClass(Preview, [{
    key: "initialize",
    value: function initialize(_ref) {
      var _this = this;

      var getStoryIndex = _ref.getStoryIndex,
          importFn = _ref.importFn,
          getProjectAnnotations = _ref.getProjectAnnotations;
      // We save these two on initialization in case `getProjectAnnotations` errors,
      // in which case we may need them later when we recover.
      this.getStoryIndex = getStoryIndex;
      this.importFn = importFn;
      this.setupListeners();
      return this.getProjectAnnotationsOrRenderError(getProjectAnnotations).then(function (projectAnnotations) {
        return _this.initializeWithProjectAnnotations(projectAnnotations);
      });
    }
  }, {
    key: "setupListeners",
    value: function setupListeners() {
      var _this$serverChannel;

      (_this$serverChannel = this.serverChannel) === null || _this$serverChannel === void 0 ? void 0 : _this$serverChannel.on(_coreEvents.STORY_INDEX_INVALIDATED, this.onStoryIndexChanged.bind(this));
      this.channel.on(_coreEvents.UPDATE_GLOBALS, this.onUpdateGlobals.bind(this));
      this.channel.on(_coreEvents.UPDATE_STORY_ARGS, this.onUpdateArgs.bind(this));
      this.channel.on(_coreEvents.RESET_STORY_ARGS, this.onResetArgs.bind(this));
      this.channel.on(_coreEvents.FORCE_RE_RENDER, this.onForceReRender.bind(this));
      this.channel.on(_coreEvents.FORCE_REMOUNT, this.onForceRemount.bind(this));
    }
  }, {
    key: "getProjectAnnotationsOrRenderError",
    value: function getProjectAnnotationsOrRenderError(getProjectAnnotations) {
      var _this2 = this;

      return _synchronousPromise.SynchronousPromise.resolve().then(getProjectAnnotations).then(function (projectAnnotations) {
        _this2.renderToDOM = projectAnnotations.renderToDOM;

        if (!_this2.renderToDOM) {
          throw new Error((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n            Expected your framework's preset to export a `renderToDOM` field.\n\n            Perhaps it needs to be upgraded for Storybook 6.4?\n\n            More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#mainjs-framework-field          \n          "], ["\n            Expected your framework's preset to export a \\`renderToDOM\\` field.\n\n            Perhaps it needs to be upgraded for Storybook 6.4?\n\n            More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#mainjs-framework-field          \n          "]))));
        }

        return projectAnnotations;
      }).catch(function (err) {
        // This is an error extracting the projectAnnotations (i.e. evaluating the previewEntries) and
        // needs to be show to the user as a simple error
        _this2.renderPreviewEntryError('Error reading preview.js:', err);

        throw err;
      });
    } // If initialization gets as far as project annotations, this function runs.

  }, {
    key: "initializeWithProjectAnnotations",
    value: function initializeWithProjectAnnotations(projectAnnotations) {
      var _global$FEATURES2,
          _this3 = this;

      this.storyStore.setProjectAnnotations(projectAnnotations);
      this.setInitialGlobals();
      var storyIndexPromise;

      if ((_global$FEATURES2 = _global.default.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.storyStoreV7) {
        storyIndexPromise = this.getStoryIndexFromServer();
      } else {
        if (!this.getStoryIndex) {
          throw new Error('No `getStoryIndex` passed defined in v6 mode');
        }

        storyIndexPromise = _synchronousPromise.SynchronousPromise.resolve().then(this.getStoryIndex);
      }

      return storyIndexPromise.then(function (storyIndex) {
        return _this3.initializeWithStoryIndex(storyIndex);
      }).catch(function (err) {
        _this3.renderPreviewEntryError('Error loading story index:', err);

        throw err;
      });
    }
  }, {
    key: "setInitialGlobals",
    value: function () {
      var _setInitialGlobals = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee() {
        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                this.emitGlobals();

              case 1:
              case "end":
                return _context.stop();
            }
          }
        }, _callee, this);
      }));

      function setInitialGlobals() {
        return _setInitialGlobals.apply(this, arguments);
      }

      return setInitialGlobals;
    }()
  }, {
    key: "emitGlobals",
    value: function emitGlobals() {
      this.channel.emit(_coreEvents.SET_GLOBALS, {
        globals: this.storyStore.globals.get() || {},
        globalTypes: this.storyStore.projectAnnotations.globalTypes || {}
      });
    }
  }, {
    key: "getStoryIndexFromServer",
    value: function () {
      var _getStoryIndexFromServer = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
        var result;
        return regeneratorRuntime.wrap(function _callee2$(_context2) {
          while (1) {
            switch (_context2.prev = _context2.next) {
              case 0:
                _context2.next = 2;
                return fetch(STORY_INDEX_PATH);

              case 2:
                result = _context2.sent;

                if (!(result.status === 200)) {
                  _context2.next = 5;
                  break;
                }

                return _context2.abrupt("return", result.json());

              case 5:
                _context2.t0 = Error;
                _context2.next = 8;
                return result.text();

              case 8:
                _context2.t1 = _context2.sent;
                throw new _context2.t0(_context2.t1);

              case 10:
              case "end":
                return _context2.stop();
            }
          }
        }, _callee2);
      }));

      function getStoryIndexFromServer() {
        return _getStoryIndexFromServer.apply(this, arguments);
      }

      return getStoryIndexFromServer;
    }() // If initialization gets as far as the story index, this function runs.

  }, {
    key: "initializeWithStoryIndex",
    value: function initializeWithStoryIndex(storyIndex) {
      var _global$FEATURES3;

      return this.storyStore.initialize({
        storyIndex: storyIndex,
        importFn: this.importFn,
        cache: !((_global$FEATURES3 = _global.default.FEATURES) !== null && _global$FEATURES3 !== void 0 && _global$FEATURES3.storyStoreV7)
      });
    } // EVENT HANDLERS
    // This happens when a config file gets reloaded

  }, {
    key: "onGetProjectAnnotationsChanged",
    value: function () {
      var _onGetProjectAnnotationsChanged = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3(_ref2) {
        var getProjectAnnotations, projectAnnotations;
        return regeneratorRuntime.wrap(function _callee3$(_context3) {
          while (1) {
            switch (_context3.prev = _context3.next) {
              case 0:
                getProjectAnnotations = _ref2.getProjectAnnotations;
                delete this.previewEntryError;
                _context3.next = 4;
                return this.getProjectAnnotationsOrRenderError(getProjectAnnotations);

              case 4:
                projectAnnotations = _context3.sent;

                if (this.storyStore.projectAnnotations) {
                  _context3.next = 9;
                  break;
                }

                _context3.next = 8;
                return this.initializeWithProjectAnnotations(projectAnnotations);

              case 8:
                return _context3.abrupt("return");

              case 9:
                _context3.next = 11;
                return this.storyStore.setProjectAnnotations(projectAnnotations);

              case 11:
                this.emitGlobals();

              case 12:
              case "end":
                return _context3.stop();
            }
          }
        }, _callee3, this);
      }));

      function onGetProjectAnnotationsChanged(_x) {
        return _onGetProjectAnnotationsChanged.apply(this, arguments);
      }

      return onGetProjectAnnotationsChanged;
    }()
  }, {
    key: "onStoryIndexChanged",
    value: function () {
      var _onStoryIndexChanged = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4() {
        var storyIndex;
        return regeneratorRuntime.wrap(function _callee4$(_context4) {
          while (1) {
            switch (_context4.prev = _context4.next) {
              case 0:
                delete this.previewEntryError;

                if (this.storyStore.projectAnnotations) {
                  _context4.next = 3;
                  break;
                }

                return _context4.abrupt("return");

              case 3:
                _context4.prev = 3;
                _context4.next = 6;
                return this.getStoryIndexFromServer();

              case 6:
                storyIndex = _context4.sent;

                if (this.storyStore.storyIndex) {
                  _context4.next = 10;
                  break;
                }

                _context4.next = 10;
                return this.initializeWithStoryIndex(storyIndex);

              case 10:
                _context4.next = 12;
                return this.onStoriesChanged({
                  storyIndex: storyIndex
                });

              case 12:
                _context4.next = 18;
                break;

              case 14:
                _context4.prev = 14;
                _context4.t0 = _context4["catch"](3);
                this.renderPreviewEntryError('Error loading story index:', _context4.t0);
                throw _context4.t0;

              case 18:
              case "end":
                return _context4.stop();
            }
          }
        }, _callee4, this, [[3, 14]]);
      }));

      function onStoryIndexChanged() {
        return _onStoryIndexChanged.apply(this, arguments);
      }

      return onStoryIndexChanged;
    }() // This happens when a glob gets HMR-ed

  }, {
    key: "onStoriesChanged",
    value: function () {
      var _onStoriesChanged = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee5(_ref3) {
        var importFn, storyIndex;
        return regeneratorRuntime.wrap(function _callee5$(_context5) {
          while (1) {
            switch (_context5.prev = _context5.next) {
              case 0:
                importFn = _ref3.importFn, storyIndex = _ref3.storyIndex;
                _context5.next = 3;
                return this.storyStore.onStoriesChanged({
                  importFn: importFn,
                  storyIndex: storyIndex
                });

              case 3:
              case "end":
                return _context5.stop();
            }
          }
        }, _callee5, this);
      }));

      function onStoriesChanged(_x2) {
        return _onStoriesChanged.apply(this, arguments);
      }

      return onStoriesChanged;
    }()
  }, {
    key: "onUpdateGlobals",
    value: function () {
      var _onUpdateGlobals = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee6(_ref4) {
        var globals;
        return regeneratorRuntime.wrap(function _callee6$(_context6) {
          while (1) {
            switch (_context6.prev = _context6.next) {
              case 0:
                globals = _ref4.globals;
                this.storyStore.globals.update(globals);
                _context6.next = 4;
                return Promise.all(this.storyRenders.map(function (r) {
                  return r.rerender();
                }));

              case 4:
                this.channel.emit(_coreEvents.GLOBALS_UPDATED, {
                  globals: this.storyStore.globals.get(),
                  initialGlobals: this.storyStore.globals.initialGlobals
                });

              case 5:
              case "end":
                return _context6.stop();
            }
          }
        }, _callee6, this);
      }));

      function onUpdateGlobals(_x3) {
        return _onUpdateGlobals.apply(this, arguments);
      }

      return onUpdateGlobals;
    }()
  }, {
    key: "onUpdateArgs",
    value: function () {
      var _onUpdateArgs = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee7(_ref5) {
        var storyId, updatedArgs;
        return regeneratorRuntime.wrap(function _callee7$(_context7) {
          while (1) {
            switch (_context7.prev = _context7.next) {
              case 0:
                storyId = _ref5.storyId, updatedArgs = _ref5.updatedArgs;
                this.storyStore.args.update(storyId, updatedArgs);
                _context7.next = 4;
                return Promise.all(this.storyRenders.filter(function (r) {
                  return r.id === storyId;
                }).map(function (r) {
                  return r.rerender();
                }));

              case 4:
                this.channel.emit(_coreEvents.STORY_ARGS_UPDATED, {
                  storyId: storyId,
                  args: this.storyStore.args.get(storyId)
                });

              case 5:
              case "end":
                return _context7.stop();
            }
          }
        }, _callee7, this);
      }));

      function onUpdateArgs(_x4) {
        return _onUpdateArgs.apply(this, arguments);
      }

      return onUpdateArgs;
    }()
  }, {
    key: "onResetArgs",
    value: function () {
      var _onResetArgs = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee8(_ref6) {
        var storyId, argNames, render, story, argNamesToReset, updatedArgs;
        return regeneratorRuntime.wrap(function _callee8$(_context8) {
          while (1) {
            switch (_context8.prev = _context8.next) {
              case 0:
                storyId = _ref6.storyId, argNames = _ref6.argNames;
                // NOTE: we have to be careful here and avoid await-ing when updating a rendered's args.
                // That's because below in `renderStoryToElement` we have also bound to this event and will
                // render the story in the same tick.
                // However, we can do that safely as the current story is available in `this.storyRenders`
                render = this.storyRenders.find(function (r) {
                  return r.id === storyId;
                });
                _context8.t0 = render === null || render === void 0 ? void 0 : render.story;

                if (_context8.t0) {
                  _context8.next = 7;
                  break;
                }

                _context8.next = 6;
                return this.storyStore.loadStory({
                  storyId: storyId
                });

              case 6:
                _context8.t0 = _context8.sent;

              case 7:
                story = _context8.t0;
                argNamesToReset = argNames || _toConsumableArray(new Set([].concat(_toConsumableArray(Object.keys(story.initialArgs)), _toConsumableArray(Object.keys(this.storyStore.args.get(storyId))))));
                updatedArgs = argNamesToReset.reduce(function (acc, argName) {
                  acc[argName] = story.initialArgs[argName];
                  return acc;
                }, {});
                _context8.next = 12;
                return this.onUpdateArgs({
                  storyId: storyId,
                  updatedArgs: updatedArgs
                });

              case 12:
              case "end":
                return _context8.stop();
            }
          }
        }, _callee8, this);
      }));

      function onResetArgs(_x5) {
        return _onResetArgs.apply(this, arguments);
      }

      return onResetArgs;
    }() // ForceReRender does not include a story id, so we simply must
    // re-render all stories in case they are relevant

  }, {
    key: "onForceReRender",
    value: function () {
      var _onForceReRender = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee9() {
        return regeneratorRuntime.wrap(function _callee9$(_context9) {
          while (1) {
            switch (_context9.prev = _context9.next) {
              case 0:
                _context9.next = 2;
                return Promise.all(this.storyRenders.map(function (r) {
                  return r.rerender();
                }));

              case 2:
              case "end":
                return _context9.stop();
            }
          }
        }, _callee9, this);
      }));

      function onForceReRender() {
        return _onForceReRender.apply(this, arguments);
      }

      return onForceReRender;
    }()
  }, {
    key: "onForceRemount",
    value: function () {
      var _onForceRemount = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee10(_ref7) {
        var storyId;
        return regeneratorRuntime.wrap(function _callee10$(_context10) {
          while (1) {
            switch (_context10.prev = _context10.next) {
              case 0:
                storyId = _ref7.storyId;
                _context10.next = 3;
                return Promise.all(this.storyRenders.filter(function (r) {
                  return r.id === storyId;
                }).map(function (r) {
                  return r.remount();
                }));

              case 3:
              case "end":
                return _context10.stop();
            }
          }
        }, _callee10, this);
      }));

      function onForceRemount(_x6) {
        return _onForceRemount.apply(this, arguments);
      }

      return onForceRemount;
    }() // Used by docs' modernInlineRender to render a story to a given element
    // Note this short-circuits the `prepare()` phase of the StoryRender,
    // main to be consistent with the previous behaviour. In the future,
    // we will change it to go ahead and load the story, which will end up being
    // "instant", although async.

  }, {
    key: "renderStoryToElement",
    value: function renderStoryToElement(story, element) {
      var _this4 = this;

      var render = new _StoryRender.StoryRender(this.channel, this.storyStore, this.renderToDOM, this.inlineStoryCallbacks(story.id), story.id, 'docs', story);
      render.renderToElement(element);
      this.storyRenders.push(render);
      return /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee11() {
        return regeneratorRuntime.wrap(function _callee11$(_context11) {
          while (1) {
            switch (_context11.prev = _context11.next) {
              case 0:
                _context11.next = 2;
                return _this4.teardownRender(render);

              case 2:
              case "end":
                return _context11.stop();
            }
          }
        }, _callee11);
      }));
    }
  }, {
    key: "teardownRender",
    value: function () {
      var _teardownRender = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee12(render) {
        var _ref9,
            viewModeChanged,
            _args12 = arguments;

        return regeneratorRuntime.wrap(function _callee12$(_context12) {
          while (1) {
            switch (_context12.prev = _context12.next) {
              case 0:
                _ref9 = _args12.length > 1 && _args12[1] !== undefined ? _args12[1] : {}, viewModeChanged = _ref9.viewModeChanged;
                this.storyRenders = this.storyRenders.filter(function (r) {
                  return r !== render;
                });
                _context12.next = 4;
                return render === null || render === void 0 ? void 0 : render.teardown({
                  viewModeChanged: viewModeChanged
                });

              case 4:
              case "end":
                return _context12.stop();
            }
          }
        }, _callee12, this);
      }));

      function teardownRender(_x7) {
        return _teardownRender.apply(this, arguments);
      }

      return teardownRender;
    }() // API

  }, {
    key: "extract",
    value: function () {
      var _extract = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee13(options) {
        var _global$FEATURES4;

        return regeneratorRuntime.wrap(function _callee13$(_context13) {
          while (1) {
            switch (_context13.prev = _context13.next) {
              case 0:
                if (!this.previewEntryError) {
                  _context13.next = 2;
                  break;
                }

                throw this.previewEntryError;

              case 2:
                if (this.storyStore.projectAnnotations) {
                  _context13.next = 4;
                  break;
                }

                throw new Error((0, _tsDedent.default)(_templateObject2 || (_templateObject2 = _taggedTemplateLiteral(["Failed to initialize Storybook.\n      \n      Do you have an error in your `preview.js`? Check your Storybook's browser console for errors."], ["Failed to initialize Storybook.\n      \n      Do you have an error in your \\`preview.js\\`? Check your Storybook's browser console for errors."]))));

              case 4:
                if (!((_global$FEATURES4 = _global.default.FEATURES) !== null && _global$FEATURES4 !== void 0 && _global$FEATURES4.storyStoreV7)) {
                  _context13.next = 7;
                  break;
                }

                _context13.next = 7;
                return this.storyStore.cacheAllCSFFiles();

              case 7:
                return _context13.abrupt("return", this.storyStore.extract(options));

              case 8:
              case "end":
                return _context13.stop();
            }
          }
        }, _callee13, this);
      }));

      function extract(_x8) {
        return _extract.apply(this, arguments);
      }

      return extract;
    }() // UTILITIES

  }, {
    key: "inlineStoryCallbacks",
    value: function inlineStoryCallbacks(storyId) {
      return {
        showMain: function showMain() {},
        showError: function showError(err) {
          return _clientLogger.logger.error("Error rendering docs story (".concat(storyId, ")"), err);
        },
        showException: function showException(err) {
          return _clientLogger.logger.error("Error rendering docs story (".concat(storyId, ")"), err);
        }
      };
    }
  }, {
    key: "renderPreviewEntryError",
    value: function renderPreviewEntryError(reason, err) {
      this.previewEntryError = err;

      _clientLogger.logger.error(reason);

      _clientLogger.logger.error(err);

      this.channel.emit(_coreEvents.CONFIG_ERROR, err);
    }
  }]);

  return Preview;
}();

exports.Preview = Preview;