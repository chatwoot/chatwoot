"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.DocsRender = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.promise.js");

var _global = _interopRequireDefault(require("global"));

var _coreEvents = require("@storybook/core-events");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

var DocsRender = /*#__PURE__*/function () {
  // eslint-disable-next-line no-useless-constructor
  function DocsRender(channel, store, id, story) {
    _classCallCheck(this, DocsRender);

    this.channel = channel;
    this.store = store;
    this.id = id;
    this.story = story;
    this.canvasElement = void 0;
    this.context = void 0;
    this.disableKeyListeners = false;
  } // DocsRender doesn't prepare, it is created *from* a prepared StoryRender


  _createClass(DocsRender, [{
    key: "isPreparing",
    value: function isPreparing() {
      return false;
    }
  }, {
    key: "renderToElement",
    value: function () {
      var _renderToElement = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(canvasElement, renderStoryToElement) {
        var _this = this,
            _global$FEATURES;

        var _this$story, id, title, name, csfFile;

        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                this.canvasElement = canvasElement;
                _this$story = this.story, id = _this$story.id, title = _this$story.title, name = _this$story.name;
                _context.next = 4;
                return this.store.loadCSFFileByStoryId(this.id);

              case 4:
                csfFile = _context.sent;
                this.context = Object.assign({
                  id: id,
                  title: title,
                  name: name,
                  // NOTE: these two functions are *sync* so cannot access stories from other CSF files
                  storyById: function storyById(storyId) {
                    return _this.store.storyFromCSFFile({
                      storyId: storyId,
                      csfFile: csfFile
                    });
                  },
                  componentStories: function componentStories() {
                    return _this.store.componentStoriesFromCSFFile({
                      csfFile: csfFile
                    });
                  },
                  loadStory: function loadStory(storyId) {
                    return _this.store.loadStory({
                      storyId: storyId
                    });
                  },
                  renderStoryToElement: renderStoryToElement,
                  getStoryContext: function getStoryContext(renderedStory) {
                    return Object.assign({}, _this.store.getStoryContext(renderedStory), {
                      viewMode: 'docs'
                    });
                  }
                }, !((_global$FEATURES = _global.default.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.breakingChangesV7) && this.store.getStoryContext(this.story));
                return _context.abrupt("return", this.render());

              case 7:
              case "end":
                return _context.stop();
            }
          }
        }, _callee, this);
      }));

      function renderToElement(_x, _x2) {
        return _renderToElement.apply(this, arguments);
      }

      return renderToElement;
    }()
  }, {
    key: "render",
    value: function () {
      var _render = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
        var _this2 = this;

        var renderer;
        return regeneratorRuntime.wrap(function _callee2$(_context2) {
          while (1) {
            switch (_context2.prev = _context2.next) {
              case 0:
                if (!(!this.story || !this.context || !this.canvasElement)) {
                  _context2.next = 2;
                  break;
                }

                throw new Error('DocsRender not ready to render');

              case 2:
                _context2.next = 4;
                return Promise.resolve().then(function () {
                  return _interopRequireWildcard(require('./renderDocs'));
                });

              case 4:
                renderer = _context2.sent;
                renderer.renderDocs(this.story, this.context, this.canvasElement, function () {
                  return _this2.channel.emit(_coreEvents.DOCS_RENDERED, _this2.id);
                });

              case 6:
              case "end":
                return _context2.stop();
            }
          }
        }, _callee2, this);
      }));

      function render() {
        return _render.apply(this, arguments);
      }

      return render;
    }()
  }, {
    key: "rerender",
    value: function () {
      var _rerender = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3() {
        var _global$FEATURES2;

        return regeneratorRuntime.wrap(function _callee3$(_context3) {
          while (1) {
            switch (_context3.prev = _context3.next) {
              case 0:
                if ((_global$FEATURES2 = _global.default.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.modernInlineRender) {
                  _context3.next = 3;
                  break;
                }

                _context3.next = 3;
                return this.render();

              case 3:
              case "end":
                return _context3.stop();
            }
          }
        }, _callee3, this);
      }));

      function rerender() {
        return _rerender.apply(this, arguments);
      }

      return rerender;
    }()
  }, {
    key: "teardown",
    value: function () {
      var _teardown = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4() {
        var _ref,
            viewModeChanged,
            renderer,
            _args4 = arguments;

        return regeneratorRuntime.wrap(function _callee4$(_context4) {
          while (1) {
            switch (_context4.prev = _context4.next) {
              case 0:
                _ref = _args4.length > 0 && _args4[0] !== undefined ? _args4[0] : {}, viewModeChanged = _ref.viewModeChanged;

                if (!(!viewModeChanged || !this.canvasElement)) {
                  _context4.next = 3;
                  break;
                }

                return _context4.abrupt("return");

              case 3:
                _context4.next = 5;
                return Promise.resolve().then(function () {
                  return _interopRequireWildcard(require('./renderDocs'));
                });

              case 5:
                renderer = _context4.sent;
                renderer.unmountDocs(this.canvasElement);

              case 7:
              case "end":
                return _context4.stop();
            }
          }
        }, _callee4, this);
      }));

      function teardown() {
        return _teardown.apply(this, arguments);
      }

      return teardown;
    }()
  }], [{
    key: "fromStoryRender",
    value: function fromStoryRender(storyRender) {
      var channel = storyRender.channel,
          store = storyRender.store,
          id = storyRender.id,
          story = storyRender.story;
      return new DocsRender(channel, store, id, story);
    }
  }]);

  return DocsRender;
}();

exports.DocsRender = DocsRender;
DocsRender.displayName = "DocsRender";