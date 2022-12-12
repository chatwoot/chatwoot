"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.StoryRender = exports.PREPARE_ABORTED = void 0;

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

require("regenerator-runtime/runtime.js");

var _global = _interopRequireDefault(require("global"));

var _coreEvents = require("@storybook/core-events");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

var AbortController = _global.default.AbortController;

function createController() {
  if (AbortController) return new AbortController(); // Polyfill for IE11

  return {
    signal: {
      aborted: false
    },
    abort: function abort() {
      this.signal.aborted = true;
    }
  };
}

var PREPARE_ABORTED = new Error('prepareAborted');
exports.PREPARE_ABORTED = PREPARE_ABORTED;

var StoryRender = /*#__PURE__*/function () {
  function StoryRender(channel, store, renderToScreen, callbacks, id, viewMode, story) {
    _classCallCheck(this, StoryRender);

    this.channel = channel;
    this.store = store;
    this.renderToScreen = renderToScreen;
    this.callbacks = callbacks;
    this.id = id;
    this.viewMode = viewMode;
    this.story = void 0;
    this.phase = void 0;
    this.abortController = void 0;
    this.canvasElement = void 0;
    this.notYetRendered = true;
    this.disableKeyListeners = false;
    this.abortController = createController(); // Allow short-circuiting preparing if we happen to already
    // have the story (this is used by docs mode)

    if (story) {
      this.story = story; // TODO -- what should the phase be now?
      // TODO -- should we emit the render phase changed event?

      this.phase = 'preparing';
    }
  }

  _createClass(StoryRender, [{
    key: "runPhase",
    value: function () {
      var _runPhase = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(signal, phase, phaseFn) {
        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                this.phase = phase;
                this.channel.emit(_coreEvents.STORY_RENDER_PHASE_CHANGED, {
                  newPhase: this.phase,
                  storyId: this.id
                });

                if (!phaseFn) {
                  _context.next = 5;
                  break;
                }

                _context.next = 5;
                return phaseFn();

              case 5:
                if (signal.aborted) {
                  this.phase = 'aborted';
                  this.channel.emit(_coreEvents.STORY_RENDER_PHASE_CHANGED, {
                    newPhase: this.phase,
                    storyId: this.id
                  });
                }

              case 6:
              case "end":
                return _context.stop();
            }
          }
        }, _callee, this);
      }));

      function runPhase(_x, _x2, _x3) {
        return _runPhase.apply(this, arguments);
      }

      return runPhase;
    }()
  }, {
    key: "prepare",
    value: function () {
      var _prepare = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3() {
        var _this = this;

        return regeneratorRuntime.wrap(function _callee3$(_context3) {
          while (1) {
            switch (_context3.prev = _context3.next) {
              case 0:
                _context3.next = 2;
                return this.runPhase(this.abortController.signal, 'preparing', /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
                  return regeneratorRuntime.wrap(function _callee2$(_context2) {
                    while (1) {
                      switch (_context2.prev = _context2.next) {
                        case 0:
                          _context2.next = 2;
                          return _this.store.loadStory({
                            storyId: _this.id
                          });

                        case 2:
                          _this.story = _context2.sent;

                        case 3:
                        case "end":
                          return _context2.stop();
                      }
                    }
                  }, _callee2);
                })));

              case 2:
                if (!this.abortController.signal.aborted) {
                  _context3.next = 5;
                  break;
                }

                this.store.cleanupStory(this.story);
                throw PREPARE_ABORTED;

              case 5:
              case "end":
                return _context3.stop();
            }
          }
        }, _callee3, this);
      }));

      function prepare() {
        return _prepare.apply(this, arguments);
      }

      return prepare;
    }() // The two story "renders" are equal and have both loaded the same story

  }, {
    key: "isEqual",
    value: function isEqual(other) {
      return other && this.id === other.id && this.story && this.story === other.story;
    }
  }, {
    key: "isPreparing",
    value: function isPreparing() {
      return ['preparing'].includes(this.phase);
    }
  }, {
    key: "isPending",
    value: function isPending() {
      return ['rendering', 'playing'].includes(this.phase);
    }
  }, {
    key: "context",
    value: function context() {
      return this.store.getStoryContext(this.story);
    }
  }, {
    key: "renderToElement",
    value: function () {
      var _renderToElement = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4(canvasElement) {
        return regeneratorRuntime.wrap(function _callee4$(_context4) {
          while (1) {
            switch (_context4.prev = _context4.next) {
              case 0:
                this.canvasElement = canvasElement; // FIXME: this comment
                // Start the first (initial) render. We don't await here because we need to return the "cleanup"
                // function below right away, so if the user changes story during the first render we can cancel
                // it without having to first wait for it to finish.
                // Whenever the selection changes we want to force the component to be remounted.

                return _context4.abrupt("return", this.render({
                  initial: true,
                  forceRemount: true
                }));

              case 2:
              case "end":
                return _context4.stop();
            }
          }
        }, _callee4, this);
      }));

      function renderToElement(_x4) {
        return _renderToElement.apply(this, arguments);
      }

      return renderToElement;
    }()
  }, {
    key: "render",
    value: function () {
      var _render = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee9() {
        var _this2 = this;

        var _ref2,
            _ref2$initial,
            initial,
            _ref2$forceRemount,
            forceRemount,
            _this$story,
            id,
            componentId,
            title,
            name,
            applyLoaders,
            unboundStoryFn,
            playFunction,
            abortSignal,
            loadedContext,
            renderStoryContext,
            _renderContext,
            _args9 = arguments;

        return regeneratorRuntime.wrap(function _callee9$(_context9) {
          while (1) {
            switch (_context9.prev = _context9.next) {
              case 0:
                _ref2 = _args9.length > 0 && _args9[0] !== undefined ? _args9[0] : {}, _ref2$initial = _ref2.initial, initial = _ref2$initial === void 0 ? false : _ref2$initial, _ref2$forceRemount = _ref2.forceRemount, forceRemount = _ref2$forceRemount === void 0 ? false : _ref2$forceRemount;

                if (this.story) {
                  _context9.next = 3;
                  break;
                }

                throw new Error('cannot render when not prepared');

              case 3:
                _this$story = this.story, id = _this$story.id, componentId = _this$story.componentId, title = _this$story.title, name = _this$story.name, applyLoaders = _this$story.applyLoaders, unboundStoryFn = _this$story.unboundStoryFn, playFunction = _this$story.playFunction;

                if (forceRemount && !initial) {
                  // NOTE: we don't check the cancel actually worked here, so the previous
                  // render could conceivably still be running after this call.
                  // We might want to change that in the future.
                  this.cancelRender();
                  this.abortController = createController();
                } // We need a stable reference to the signal -- if a re-mount happens the
                // abort controller may be torn down (above) before we actually check the signal.


                abortSignal = this.abortController.signal;
                _context9.prev = 6;
                _context9.next = 9;
                return this.runPhase(abortSignal, 'loading', /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee5() {
                  return regeneratorRuntime.wrap(function _callee5$(_context5) {
                    while (1) {
                      switch (_context5.prev = _context5.next) {
                        case 0:
                          _context5.next = 2;
                          return applyLoaders(Object.assign({}, _this2.context(), {
                            viewMode: _this2.viewMode
                          }));

                        case 2:
                          loadedContext = _context5.sent;

                        case 3:
                        case "end":
                          return _context5.stop();
                      }
                    }
                  }, _callee5);
                })));

              case 9:
                if (!abortSignal.aborted) {
                  _context9.next = 11;
                  break;
                }

                return _context9.abrupt("return");

              case 11:
                renderStoryContext = Object.assign({}, loadedContext, this.context(), {
                  abortSignal: abortSignal,
                  canvasElement: this.canvasElement
                });
                _renderContext = Object.assign({
                  componentId: componentId,
                  title: title,
                  kind: title,
                  id: id,
                  name: name,
                  story: name
                }, this.callbacks, {
                  forceRemount: forceRemount || this.notYetRendered,
                  storyContext: renderStoryContext,
                  storyFn: function storyFn() {
                    return unboundStoryFn(renderStoryContext);
                  },
                  unboundStoryFn: unboundStoryFn
                });
                _context9.next = 15;
                return this.runPhase(abortSignal, 'rendering', /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee6() {
                  return regeneratorRuntime.wrap(function _callee6$(_context6) {
                    while (1) {
                      switch (_context6.prev = _context6.next) {
                        case 0:
                          return _context6.abrupt("return", _this2.renderToScreen(_renderContext, _this2.canvasElement));

                        case 1:
                        case "end":
                          return _context6.stop();
                      }
                    }
                  }, _callee6);
                })));

              case 15:
                this.notYetRendered = false;

                if (!abortSignal.aborted) {
                  _context9.next = 18;
                  break;
                }

                return _context9.abrupt("return");

              case 18:
                if (!(forceRemount && playFunction)) {
                  _context9.next = 27;
                  break;
                }

                this.disableKeyListeners = true;
                _context9.next = 22;
                return this.runPhase(abortSignal, 'playing', /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee7() {
                  return regeneratorRuntime.wrap(function _callee7$(_context7) {
                    while (1) {
                      switch (_context7.prev = _context7.next) {
                        case 0:
                          return _context7.abrupt("return", playFunction(_renderContext.storyContext));

                        case 1:
                        case "end":
                          return _context7.stop();
                      }
                    }
                  }, _callee7);
                })));

              case 22:
                _context9.next = 24;
                return this.runPhase(abortSignal, 'played');

              case 24:
                this.disableKeyListeners = false;

                if (!abortSignal.aborted) {
                  _context9.next = 27;
                  break;
                }

                return _context9.abrupt("return");

              case 27:
                _context9.next = 29;
                return this.runPhase(abortSignal, 'completed', /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee8() {
                  return regeneratorRuntime.wrap(function _callee8$(_context8) {
                    while (1) {
                      switch (_context8.prev = _context8.next) {
                        case 0:
                          return _context8.abrupt("return", _this2.channel.emit(_coreEvents.STORY_RENDERED, id));

                        case 1:
                        case "end":
                          return _context8.stop();
                      }
                    }
                  }, _callee8);
                })));

              case 29:
                _context9.next = 34;
                break;

              case 31:
                _context9.prev = 31;
                _context9.t0 = _context9["catch"](6);
                this.callbacks.showException(_context9.t0);

              case 34:
              case "end":
                return _context9.stop();
            }
          }
        }, _callee9, this, [[6, 31]]);
      }));

      function render() {
        return _render.apply(this, arguments);
      }

      return render;
    }()
  }, {
    key: "rerender",
    value: function () {
      var _rerender = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee10() {
        return regeneratorRuntime.wrap(function _callee10$(_context10) {
          while (1) {
            switch (_context10.prev = _context10.next) {
              case 0:
                return _context10.abrupt("return", this.render());

              case 1:
              case "end":
                return _context10.stop();
            }
          }
        }, _callee10, this);
      }));

      function rerender() {
        return _rerender.apply(this, arguments);
      }

      return rerender;
    }()
  }, {
    key: "remount",
    value: function () {
      var _remount = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee11() {
        return regeneratorRuntime.wrap(function _callee11$(_context11) {
          while (1) {
            switch (_context11.prev = _context11.next) {
              case 0:
                return _context11.abrupt("return", this.render({
                  forceRemount: true
                }));

              case 1:
              case "end":
                return _context11.stop();
            }
          }
        }, _callee11, this);
      }));

      function remount() {
        return _remount.apply(this, arguments);
      }

      return remount;
    }() // If the story is torn down (either a new story is rendered or the docs page removes it)
    // we need to consider the fact that the initial render may not be finished
    // (possibly the loaders or the play function are still running). We use the controller
    // as a method to abort them, ASAP, but this is not foolproof as we cannot control what
    // happens inside the user's code.

  }, {
    key: "cancelRender",
    value: function cancelRender() {
      this.abortController.abort();
    }
  }, {
    key: "teardown",
    value: function () {
      var _teardown = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee12() {
        var options,
            i,
            _args12 = arguments;
        return regeneratorRuntime.wrap(function _callee12$(_context12) {
          while (1) {
            switch (_context12.prev = _context12.next) {
              case 0:
                options = _args12.length > 0 && _args12[0] !== undefined ? _args12[0] : {};
                this.cancelRender(); // If the story has loaded, we need to cleanup

                if (this.story) this.store.cleanupStory(this.story); // Check if we're done rendering/playing. If not, we may have to reload the page.
                // Wait several ticks that may be needed to handle the abort, then try again.
                // Note that there's a max of 5 nested timeouts before they're no longer "instant".

                i = 0;

              case 4:
                if (!(i < 3)) {
                  _context12.next = 12;
                  break;
                }

                if (this.isPending()) {
                  _context12.next = 7;
                  break;
                }

                return _context12.abrupt("return");

              case 7:
                _context12.next = 9;
                return new Promise(function (resolve) {
                  return setTimeout(resolve, 0);
                });

              case 9:
                i += 1;
                _context12.next = 4;
                break;

              case 12:
                // If we still haven't completed, reload the page (iframe) to ensure we have a clean slate
                // for the next render. Since the reload can take a brief moment to happen, we want to stop
                // further rendering by awaiting a never-resolving promise (which is destroyed on reload).
                _global.default.window.location.reload();

                _context12.next = 15;
                return new Promise(function () {});

              case 15:
              case "end":
                return _context12.stop();
            }
          }
        }, _callee12, this);
      }));

      function teardown() {
        return _teardown.apply(this, arguments);
      }

      return teardown;
    }()
  }]);

  return StoryRender;
}();

exports.StoryRender = StoryRender;
StoryRender.displayName = "StoryRender";