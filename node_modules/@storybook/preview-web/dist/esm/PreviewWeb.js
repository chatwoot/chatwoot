function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

import "core-js/modules/es.object.get-prototype-of.js";
import "core-js/modules/es.reflect.construct.js";
import "core-js/modules/es.reflect.get.js";
import "core-js/modules/es.object.get-own-property-descriptor.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";
import "core-js/modules/es.symbol.iterator.js";

var _templateObject, _templateObject2, _templateObject3, _templateObject4;

import "regenerator-runtime/runtime.js";

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _get() { if (typeof Reflect !== "undefined" && Reflect.get) { _get = Reflect.get; } else { _get = function _get(target, property, receiver) { var base = _superPropBase(target, property); if (!base) return; var desc = Object.getOwnPropertyDescriptor(base, property); if (desc.get) { return desc.get.call(arguments.length < 3 ? target : receiver); } return desc.value; }; } return _get.apply(this, arguments); }

function _superPropBase(object, property) { while (!Object.prototype.hasOwnProperty.call(object, property)) { object = _getPrototypeOf(object); if (object === null) break; } return object; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.promise.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.array.concat.js";
import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import global from 'global';
import { CURRENT_STORY_WAS_SET, IGNORED_EXCEPTION, PRELOAD_STORIES, PREVIEW_KEYDOWN, SET_CURRENT_STORY, SET_STORIES, STORY_ARGS_UPDATED, STORY_CHANGED, STORY_ERRORED, STORY_MISSING, STORY_PREPARED, STORY_RENDER_PHASE_CHANGED, STORY_SPECIFIED, STORY_THREW_EXCEPTION, STORY_UNCHANGED, UPDATE_QUERY_PARAMS } from '@storybook/core-events';
import { logger } from '@storybook/client-logger';
import { Preview } from './Preview';
import { UrlStore } from './UrlStore';
import { WebView } from './WebView';
import { PREPARE_ABORTED, StoryRender } from './StoryRender';
import { DocsRender } from './DocsRender';
var globalWindow = global.window;

function focusInInput(event) {
  var target = event.target;
  return /input|textarea/i.test(target.tagName) || target.getAttribute('contenteditable') !== null;
}

export var PreviewWeb = /*#__PURE__*/function (_Preview) {
  _inherits(PreviewWeb, _Preview);

  var _super = _createSuper(PreviewWeb);

  function PreviewWeb() {
    var _this;

    _classCallCheck(this, PreviewWeb);

    _this = _super.call(this);
    _this.urlStore = void 0;
    _this.view = void 0;
    _this.previewEntryError = void 0;
    _this.currentSelection = void 0;
    _this.currentRender = void 0;
    _this.view = new WebView();
    _this.urlStore = new UrlStore(); // Add deprecated APIs for back-compat
    // @ts-ignore

    _this.storyStore.getSelection = deprecate(function () {
      return _this.urlStore.selection;
    }, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n        `__STORYBOOK_STORY_STORE__.getSelection()` is deprecated and will be removed in 7.0.\n  \n        To get the current selection, use the `useStoryContext()` hook from `@storybook/addons`.\n      "], ["\n        \\`__STORYBOOK_STORY_STORE__.getSelection()\\` is deprecated and will be removed in 7.0.\n  \n        To get the current selection, use the \\`useStoryContext()\\` hook from \\`@storybook/addons\\`.\n      "]))));
    return _this;
  }

  _createClass(PreviewWeb, [{
    key: "setupListeners",
    value: function setupListeners() {
      _get(_getPrototypeOf(PreviewWeb.prototype), "setupListeners", this).call(this);

      globalWindow.onkeydown = this.onKeydown.bind(this);
      this.channel.on(SET_CURRENT_STORY, this.onSetCurrentStory.bind(this));
      this.channel.on(UPDATE_QUERY_PARAMS, this.onUpdateQueryParams.bind(this));
      this.channel.on(PRELOAD_STORIES, this.onPreloadStories.bind(this));
    }
  }, {
    key: "initializeWithProjectAnnotations",
    value: function initializeWithProjectAnnotations(projectAnnotations) {
      var _this2 = this;

      return _get(_getPrototypeOf(PreviewWeb.prototype), "initializeWithProjectAnnotations", this).call(this, projectAnnotations).then(function () {
        return _this2.setInitialGlobals();
      });
    }
  }, {
    key: "setInitialGlobals",
    value: function () {
      var _setInitialGlobals = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee() {
        var _ref, globals;

        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                _ref = this.urlStore.selectionSpecifier || {}, globals = _ref.globals;

                if (globals) {
                  this.storyStore.globals.updateFromPersisted(globals);
                }

                this.emitGlobals();

              case 3:
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
    }() // If initialization gets as far as the story index, this function runs.

  }, {
    key: "initializeWithStoryIndex",
    value: function initializeWithStoryIndex(storyIndex) {
      var _this3 = this;

      return _get(_getPrototypeOf(PreviewWeb.prototype), "initializeWithStoryIndex", this).call(this, storyIndex).then(function () {
        var _global$FEATURES;

        if (!((_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.storyStoreV7)) {
          _this3.channel.emit(SET_STORIES, _this3.storyStore.getSetStoriesPayload());
        }

        return _this3.selectSpecifiedStory();
      });
    } // Use the selection specifier to choose a story, then render it

  }, {
    key: "selectSpecifiedStory",
    value: function () {
      var _selectSpecifiedStory = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2() {
        var _this$urlStore$select, storySpecifier, viewMode, args, storyId;

        return regeneratorRuntime.wrap(function _callee2$(_context2) {
          while (1) {
            switch (_context2.prev = _context2.next) {
              case 0:
                if (this.urlStore.selectionSpecifier) {
                  _context2.next = 3;
                  break;
                }

                this.renderMissingStory();
                return _context2.abrupt("return");

              case 3:
                _this$urlStore$select = this.urlStore.selectionSpecifier, storySpecifier = _this$urlStore$select.storySpecifier, viewMode = _this$urlStore$select.viewMode, args = _this$urlStore$select.args;
                storyId = this.storyStore.storyIndex.storyIdFromSpecifier(storySpecifier);

                if (storyId) {
                  _context2.next = 8;
                  break;
                }

                if (storySpecifier === '*') {
                  this.renderStoryLoadingException(storySpecifier, new Error(dedent(_templateObject2 || (_templateObject2 = _taggedTemplateLiteral(["\n            Couldn't find any stories in your Storybook.\n            - Please check your stories field of your main.js config.\n            - Also check the browser console and terminal for error messages.\n          "])))));
                } else {
                  this.renderStoryLoadingException(storySpecifier, new Error(dedent(_templateObject3 || (_templateObject3 = _taggedTemplateLiteral(["\n            Couldn't find story matching '", "'.\n            - Are you sure a story with that id exists?\n            - Please check your stories field of your main.js config.\n            - Also check the browser console and terminal for error messages.\n          "])), storySpecifier)));
                }

                return _context2.abrupt("return");

              case 8:
                this.urlStore.setSelection({
                  storyId: storyId,
                  viewMode: viewMode
                });
                this.channel.emit(STORY_SPECIFIED, this.urlStore.selection);
                this.channel.emit(CURRENT_STORY_WAS_SET, this.urlStore.selection);
                _context2.next = 13;
                return this.renderSelection({
                  persistedArgs: args
                });

              case 13:
              case "end":
                return _context2.stop();
            }
          }
        }, _callee2, this);
      }));

      function selectSpecifiedStory() {
        return _selectSpecifiedStory.apply(this, arguments);
      }

      return selectSpecifiedStory;
    }() // EVENT HANDLERS
    // This happens when a config file gets reloaded

  }, {
    key: "onGetProjectAnnotationsChanged",
    value: function () {
      var _onGetProjectAnnotationsChanged = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee3(_ref2) {
        var getProjectAnnotations;
        return regeneratorRuntime.wrap(function _callee3$(_context3) {
          while (1) {
            switch (_context3.prev = _context3.next) {
              case 0:
                getProjectAnnotations = _ref2.getProjectAnnotations;
                _context3.next = 3;
                return _get(_getPrototypeOf(PreviewWeb.prototype), "onGetProjectAnnotationsChanged", this).call(this, {
                  getProjectAnnotations: getProjectAnnotations
                });

              case 3:
                this.renderSelection();

              case 4:
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
    }() // This happens when a glob gets HMR-ed

  }, {
    key: "onStoriesChanged",
    value: function () {
      var _onStoriesChanged = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee4(_ref3) {
        var _global$FEATURES2;

        var importFn, storyIndex;
        return regeneratorRuntime.wrap(function _callee4$(_context4) {
          while (1) {
            switch (_context4.prev = _context4.next) {
              case 0:
                importFn = _ref3.importFn, storyIndex = _ref3.storyIndex;

                _get(_getPrototypeOf(PreviewWeb.prototype), "onStoriesChanged", this).call(this, {
                  importFn: importFn,
                  storyIndex: storyIndex
                });

                if ((_global$FEATURES2 = global.FEATURES) !== null && _global$FEATURES2 !== void 0 && _global$FEATURES2.storyStoreV7) {
                  _context4.next = 9;
                  break;
                }

                _context4.t0 = this.channel;
                _context4.t1 = SET_STORIES;
                _context4.next = 7;
                return this.storyStore.getSetStoriesPayload();

              case 7:
                _context4.t2 = _context4.sent;

                _context4.t0.emit.call(_context4.t0, _context4.t1, _context4.t2);

              case 9:
                if (!this.urlStore.selection) {
                  _context4.next = 14;
                  break;
                }

                _context4.next = 12;
                return this.renderSelection();

              case 12:
                _context4.next = 16;
                break;

              case 14:
                _context4.next = 16;
                return this.selectSpecifiedStory();

              case 16:
              case "end":
                return _context4.stop();
            }
          }
        }, _callee4, this);
      }));

      function onStoriesChanged(_x2) {
        return _onStoriesChanged.apply(this, arguments);
      }

      return onStoriesChanged;
    }()
  }, {
    key: "onKeydown",
    value: function onKeydown(event) {
      var _this$currentRender;

      if (!((_this$currentRender = this.currentRender) !== null && _this$currentRender !== void 0 && _this$currentRender.disableKeyListeners) && !focusInInput(event)) {
        // We have to pick off the keys of the event that we need on the other side
        var altKey = event.altKey,
            ctrlKey = event.ctrlKey,
            metaKey = event.metaKey,
            shiftKey = event.shiftKey,
            key = event.key,
            code = event.code,
            keyCode = event.keyCode;
        this.channel.emit(PREVIEW_KEYDOWN, {
          event: {
            altKey: altKey,
            ctrlKey: ctrlKey,
            metaKey: metaKey,
            shiftKey: shiftKey,
            key: key,
            code: code,
            keyCode: keyCode
          }
        });
      }
    }
  }, {
    key: "onSetCurrentStory",
    value: function onSetCurrentStory(selection) {
      this.urlStore.setSelection(Object.assign({
        viewMode: 'story'
      }, selection));
      this.channel.emit(CURRENT_STORY_WAS_SET, this.urlStore.selection);
      this.renderSelection();
    }
  }, {
    key: "onUpdateQueryParams",
    value: function onUpdateQueryParams(queryParams) {
      this.urlStore.setQueryParams(queryParams);
    }
  }, {
    key: "onUpdateGlobals",
    value: function () {
      var _onUpdateGlobals = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee5(_ref4) {
        var globals;
        return regeneratorRuntime.wrap(function _callee5$(_context5) {
          while (1) {
            switch (_context5.prev = _context5.next) {
              case 0:
                globals = _ref4.globals;

                _get(_getPrototypeOf(PreviewWeb.prototype), "onUpdateGlobals", this).call(this, {
                  globals: globals
                });

                if (!(this.currentRender instanceof DocsRender)) {
                  _context5.next = 5;
                  break;
                }

                _context5.next = 5;
                return this.currentRender.rerender();

              case 5:
              case "end":
                return _context5.stop();
            }
          }
        }, _callee5, this);
      }));

      function onUpdateGlobals(_x3) {
        return _onUpdateGlobals.apply(this, arguments);
      }

      return onUpdateGlobals;
    }()
  }, {
    key: "onUpdateArgs",
    value: function () {
      var _onUpdateArgs = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee6(_ref5) {
        var storyId, updatedArgs;
        return regeneratorRuntime.wrap(function _callee6$(_context6) {
          while (1) {
            switch (_context6.prev = _context6.next) {
              case 0:
                storyId = _ref5.storyId, updatedArgs = _ref5.updatedArgs;

                _get(_getPrototypeOf(PreviewWeb.prototype), "onUpdateArgs", this).call(this, {
                  storyId: storyId,
                  updatedArgs: updatedArgs
                }); // NOTE: we aren't checking to see the story args are targetted at the "right" story.
                // This is because we may render >1 story on the page and there is no easy way to keep track
                // of which ones were rendered by the docs page.
                // However, in `modernInlineRender`, the individual stories track their own events as they
                // each call `renderStoryToElement` below.


                if (!(this.currentRender instanceof DocsRender)) {
                  _context6.next = 5;
                  break;
                }

                _context6.next = 5;
                return this.currentRender.rerender();

              case 5:
              case "end":
                return _context6.stop();
            }
          }
        }, _callee6, this);
      }));

      function onUpdateArgs(_x4) {
        return _onUpdateArgs.apply(this, arguments);
      }

      return onUpdateArgs;
    }()
  }, {
    key: "onPreloadStories",
    value: function () {
      var _onPreloadStories = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee7(ids) {
        var _this4 = this;

        return regeneratorRuntime.wrap(function _callee7$(_context7) {
          while (1) {
            switch (_context7.prev = _context7.next) {
              case 0:
                _context7.next = 2;
                return Promise.all(ids.map(function (id) {
                  return _this4.storyStore.loadStory({
                    storyId: id
                  });
                }));

              case 2:
              case "end":
                return _context7.stop();
            }
          }
        }, _callee7);
      }));

      function onPreloadStories(_x5) {
        return _onPreloadStories.apply(this, arguments);
      }

      return onPreloadStories;
    }() // RENDERING
    // We can either have:
    // - a story selected in "story" viewMode,
    //     in which case we render it to the root element, OR
    // - a story selected in "docs" viewMode,
    //     in which case we render the docsPage for that story

  }, {
    key: "renderSelection",
    value: function () {
      var _renderSelection = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee8() {
        var _this$currentSelectio,
            _this$currentSelectio2,
            _lastRender,
            _this5 = this,
            _global$FEATURES3;

        var _ref6,
            persistedArgs,
            selection,
            storyId,
            storyIdChanged,
            viewModeChanged,
            lastSelection,
            lastRender,
            storyRender,
            implementationChanged,
            _storyRender$context,
            parameters,
            initialArgs,
            argTypes,
            args,
            _args8 = arguments;

        return regeneratorRuntime.wrap(function _callee8$(_context8) {
          while (1) {
            switch (_context8.prev = _context8.next) {
              case 0:
                _ref6 = _args8.length > 0 && _args8[0] !== undefined ? _args8[0] : {}, persistedArgs = _ref6.persistedArgs;
                selection = this.urlStore.selection;

                if (selection) {
                  _context8.next = 4;
                  break;
                }

                throw new Error('Cannot render story as no selection was made');

              case 4:
                storyId = selection.storyId;
                storyIdChanged = ((_this$currentSelectio = this.currentSelection) === null || _this$currentSelectio === void 0 ? void 0 : _this$currentSelectio.storyId) !== storyId;
                viewModeChanged = ((_this$currentSelectio2 = this.currentSelection) === null || _this$currentSelectio2 === void 0 ? void 0 : _this$currentSelectio2.viewMode) !== selection.viewMode; // Show a spinner while we load the next story

                if (selection.viewMode === 'story') {
                  this.view.showPreparingStory({
                    immediate: viewModeChanged
                  });
                } else {
                  this.view.showPreparingDocs();
                }

                lastSelection = this.currentSelection;
                lastRender = this.currentRender; // If the last render is still preparing, let's drop it right now. Either
                //   (a) it is a different story, which means we would drop it later, OR
                //   (b) it is the *same* story, in which case we will resolve our own .prepare() at the
                //       same moment anyway, and we should just "take over" the rendering.
                // (We can't tell which it is yet, because it is possible that an HMR is going on and
                //  even though the storyId is the same, the story itself is not).

                if (!((_lastRender = lastRender) !== null && _lastRender !== void 0 && _lastRender.isPreparing())) {
                  _context8.next = 14;
                  break;
                }

                _context8.next = 13;
                return this.teardownRender(lastRender);

              case 13:
                lastRender = null;

              case 14:
                storyRender = new StoryRender(this.channel, this.storyStore, function () {
                  // At the start of renderToDOM we make the story visible (see note in WebView)
                  _this5.view.showStoryDuringRender();

                  return _this5.renderToDOM.apply(_this5, arguments);
                }, this.mainStoryCallbacks(storyId), storyId, 'story'); // We need to store this right away, so if the story changes during
                // the async `.prepare()` below, we can (potentially) cancel it

                this.currentSelection = selection; // Note this may be replaced by a docsRender after preparing

                this.currentRender = storyRender;
                _context8.prev = 17;
                _context8.next = 20;
                return storyRender.prepare();

              case 20:
                _context8.next = 29;
                break;

              case 22:
                _context8.prev = 22;
                _context8.t0 = _context8["catch"](17);

                if (!(_context8.t0 !== PREPARE_ABORTED)) {
                  _context8.next = 28;
                  break;
                }

                _context8.next = 27;
                return this.teardownRender(lastRender);

              case 27:
                this.renderStoryLoadingException(storyId, _context8.t0);

              case 28:
                return _context8.abrupt("return");

              case 29:
                implementationChanged = !storyIdChanged && !storyRender.isEqual(lastRender);
                if (persistedArgs) this.storyStore.args.updateFromPersisted(storyRender.story, persistedArgs);
                _storyRender$context = storyRender.context(), parameters = _storyRender$context.parameters, initialArgs = _storyRender$context.initialArgs, argTypes = _storyRender$context.argTypes, args = _storyRender$context.args; // Don't re-render the story if nothing has changed to justify it

                if (!(lastRender && !storyIdChanged && !implementationChanged && !viewModeChanged)) {
                  _context8.next = 37;
                  break;
                }

                this.currentRender = lastRender;
                this.channel.emit(STORY_UNCHANGED, storyId);
                this.view.showMain();
                return _context8.abrupt("return");

              case 37:
                _context8.next = 39;
                return this.teardownRender(lastRender, {
                  viewModeChanged: viewModeChanged
                });

              case 39:
                // If we are rendering something new (as opposed to re-rendering the same or first story), emit
                if (lastSelection && (storyIdChanged || viewModeChanged)) {
                  this.channel.emit(STORY_CHANGED, storyId);
                }

                if ((_global$FEATURES3 = global.FEATURES) !== null && _global$FEATURES3 !== void 0 && _global$FEATURES3.storyStoreV7) {
                  this.channel.emit(STORY_PREPARED, {
                    id: storyId,
                    parameters: parameters,
                    initialArgs: initialArgs,
                    argTypes: argTypes,
                    args: args
                  });
                } // For v6 mode / compatibility
                // If the implementation changed, or args were persisted, the args may have changed,
                // and the STORY_PREPARED event above may not be respected.


                if (implementationChanged || persistedArgs) {
                  this.channel.emit(STORY_ARGS_UPDATED, {
                    storyId: storyId,
                    args: args
                  });
                }

                if (selection.viewMode === 'docs' || parameters.docsOnly) {
                  this.currentRender = DocsRender.fromStoryRender(storyRender);
                  this.currentRender.renderToElement(this.view.prepareForDocs(), this.renderStoryToElement.bind(this));
                } else {
                  this.storyRenders.push(storyRender);
                  this.currentRender.renderToElement(this.view.prepareForStory(storyRender.story));
                }

              case 43:
              case "end":
                return _context8.stop();
            }
          }
        }, _callee8, this, [[17, 22]]);
      }));

      function renderSelection() {
        return _renderSelection.apply(this, arguments);
      }

      return renderSelection;
    }() // Used by docs' modernInlineRender to render a story to a given element
    // Note this short-circuits the `prepare()` phase of the StoryRender,
    // main to be consistent with the previous behaviour. In the future,
    // we will change it to go ahead and load the story, which will end up being
    // "instant", although async.

  }, {
    key: "renderStoryToElement",
    value: function renderStoryToElement(story, element) {
      var _this6 = this;

      var render = new StoryRender(this.channel, this.storyStore, this.renderToDOM, this.inlineStoryCallbacks(story.id), story.id, 'docs', story);
      render.renderToElement(element);
      this.storyRenders.push(render);
      return /*#__PURE__*/_asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee9() {
        return regeneratorRuntime.wrap(function _callee9$(_context9) {
          while (1) {
            switch (_context9.prev = _context9.next) {
              case 0:
                _context9.next = 2;
                return _this6.teardownRender(render);

              case 2:
              case "end":
                return _context9.stop();
            }
          }
        }, _callee9);
      }));
    }
  }, {
    key: "teardownRender",
    value: function () {
      var _teardownRender = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee10(render) {
        var _ref8,
            viewModeChanged,
            _args10 = arguments;

        return regeneratorRuntime.wrap(function _callee10$(_context10) {
          while (1) {
            switch (_context10.prev = _context10.next) {
              case 0:
                _ref8 = _args10.length > 1 && _args10[1] !== undefined ? _args10[1] : {}, viewModeChanged = _ref8.viewModeChanged;
                this.storyRenders = this.storyRenders.filter(function (r) {
                  return r !== render;
                });
                _context10.next = 4;
                return render === null || render === void 0 ? void 0 : render.teardown({
                  viewModeChanged: viewModeChanged
                });

              case 4:
              case "end":
                return _context10.stop();
            }
          }
        }, _callee10, this);
      }));

      function teardownRender(_x6) {
        return _teardownRender.apply(this, arguments);
      }

      return teardownRender;
    }() // API

  }, {
    key: "extract",
    value: function () {
      var _extract = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee11(options) {
        var _global$FEATURES4;

        return regeneratorRuntime.wrap(function _callee11$(_context11) {
          while (1) {
            switch (_context11.prev = _context11.next) {
              case 0:
                if (!this.previewEntryError) {
                  _context11.next = 2;
                  break;
                }

                throw this.previewEntryError;

              case 2:
                if (this.storyStore.projectAnnotations) {
                  _context11.next = 4;
                  break;
                }

                throw new Error(dedent(_templateObject4 || (_templateObject4 = _taggedTemplateLiteral(["Failed to initialize Storybook.\n      \n      Do you have an error in your `preview.js`? Check your Storybook's browser console for errors."], ["Failed to initialize Storybook.\n      \n      Do you have an error in your \\`preview.js\\`? Check your Storybook's browser console for errors."]))));

              case 4:
                if (!((_global$FEATURES4 = global.FEATURES) !== null && _global$FEATURES4 !== void 0 && _global$FEATURES4.storyStoreV7)) {
                  _context11.next = 7;
                  break;
                }

                _context11.next = 7;
                return this.storyStore.cacheAllCSFFiles();

              case 7:
                return _context11.abrupt("return", this.storyStore.extract(options));

              case 8:
              case "end":
                return _context11.stop();
            }
          }
        }, _callee11, this);
      }));

      function extract(_x7) {
        return _extract.apply(this, arguments);
      }

      return extract;
    }() // UTILITIES

  }, {
    key: "mainStoryCallbacks",
    value: function mainStoryCallbacks(storyId) {
      var _this7 = this;

      return {
        showMain: function showMain() {
          return _this7.view.showMain();
        },
        showError: function showError(err) {
          return _this7.renderError(storyId, err);
        },
        showException: function showException(err) {
          return _this7.renderException(storyId, err);
        }
      };
    }
  }, {
    key: "inlineStoryCallbacks",
    value: function inlineStoryCallbacks(storyId) {
      return {
        showMain: function showMain() {},
        showError: function showError(err) {
          return logger.error("Error rendering docs story (".concat(storyId, ")"), err);
        },
        showException: function showException(err) {
          return logger.error("Error rendering docs story (".concat(storyId, ")"), err);
        }
      };
    }
  }, {
    key: "renderPreviewEntryError",
    value: function renderPreviewEntryError(reason, err) {
      _get(_getPrototypeOf(PreviewWeb.prototype), "renderPreviewEntryError", this).call(this, reason, err);

      this.view.showErrorDisplay(err);
    }
  }, {
    key: "renderMissingStory",
    value: function renderMissingStory() {
      this.view.showNoPreview();
      this.channel.emit(STORY_MISSING);
    }
  }, {
    key: "renderStoryLoadingException",
    value: function renderStoryLoadingException(storySpecifier, err) {
      logger.error("Unable to load story '".concat(storySpecifier, "':"));
      logger.error(err);
      this.view.showErrorDisplay(err);
      this.channel.emit(STORY_MISSING, storySpecifier);
    } // renderException is used if we fail to render the story and it is uncaught by the app layer

  }, {
    key: "renderException",
    value: function renderException(storyId, err) {
      this.channel.emit(STORY_THREW_EXCEPTION, err);
      this.channel.emit(STORY_RENDER_PHASE_CHANGED, {
        newPhase: 'errored',
        storyId: storyId
      }); // Ignored exceptions exist for control flow purposes, and are typically handled elsewhere.

      if (err !== IGNORED_EXCEPTION) {
        this.view.showErrorDisplay(err);
        logger.error("Error rendering story '".concat(storyId, "':"));
        logger.error(err);
      }
    } // renderError is used by the various app layers to inform the user they have done something
    // wrong -- for instance returned the wrong thing from a story

  }, {
    key: "renderError",
    value: function renderError(storyId, _ref9) {
      var title = _ref9.title,
          description = _ref9.description;
      logger.error("Error rendering story ".concat(title, ": ").concat(description));
      this.channel.emit(STORY_ERRORED, {
        title: title,
        description: description
      });
      this.channel.emit(STORY_RENDER_PHASE_CHANGED, {
        newPhase: 'errored',
        storyId: storyId
      });
      this.view.showErrorDisplay({
        message: title,
        stack: description
      });
    }
  }]);

  return PreviewWeb;
}(Preview);