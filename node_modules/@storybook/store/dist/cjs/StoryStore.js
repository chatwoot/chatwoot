"use strict";

require("core-js/modules/es.promise.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.StoryStore = void 0;

require("regenerator-runtime/runtime.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.for-each.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.array.sort.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.values.js");

var _memoizerific = _interopRequireDefault(require("memoizerific"));

var _mapValues = _interopRequireDefault(require("lodash/mapValues"));

var _pick = _interopRequireDefault(require("lodash/pick"));

var _global = _interopRequireDefault(require("global"));

var _synchronousPromise = require("synchronous-promise");

var _StoryIndexStore = require("./StoryIndexStore");

var _ArgsStore = require("./ArgsStore");

var _GlobalsStore = require("./GlobalsStore");

var _csf = require("./csf");

var _hooks = require("./hooks");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { Promise.resolve(value).then(_next, _throw); } }

function _asyncToGenerator(fn) { return function () { var self = this, args = arguments; return new Promise(function (resolve, reject) { var gen = fn.apply(self, args); function _next(value) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value); } function _throw(err) { asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err); } _next(undefined); }); }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

// TODO -- what are reasonable values for these?
var CSF_CACHE_SIZE = 1000;
var STORY_CACHE_SIZE = 10000;

var StoryStore = /*#__PURE__*/function () {
  function StoryStore() {
    var _this = this;

    _classCallCheck(this, StoryStore);

    this.storyIndex = void 0;
    this.importFn = void 0;
    this.projectAnnotations = void 0;
    this.globals = void 0;
    this.args = void 0;
    this.hooks = void 0;
    this.cachedCSFFiles = void 0;
    this.processCSFFileWithCache = void 0;
    this.prepareStoryWithCache = void 0;
    this.initializationPromise = void 0;
    this.resolveInitializationPromise = void 0;

    this.getStoriesJsonData = function () {
      var value = _this.getSetStoriesPayload();

      var allowedParameters = ['fileName', 'docsOnly', 'framework', '__id', '__isArgsStory'];
      var stories = (0, _mapValues.default)(value.stories, function (story) {
        var _global$FEATURES;

        return Object.assign({}, (0, _pick.default)(story, ['id', 'name', 'title']), {
          importPath: _this.storyIndex.stories[story.id].importPath
        }, !((_global$FEATURES = _global.default.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.breakingChangesV7) && {
          kind: story.title,
          story: story.name,
          parameters: Object.assign({}, (0, _pick.default)(story.parameters, allowedParameters), {
            fileName: _this.storyIndex.stories[story.id].importPath
          })
        });
      });
      return {
        v: 3,
        stories: stories
      };
    };

    this.globals = new _GlobalsStore.GlobalsStore();
    this.args = new _ArgsStore.ArgsStore();
    this.hooks = {}; // We use a cache for these two functions for two reasons:
    //  1. For performance
    //  2. To ensure that when the same story is prepared with the same inputs you get the same output

    this.processCSFFileWithCache = (0, _memoizerific.default)(CSF_CACHE_SIZE)(_csf.processCSFFile);
    this.prepareStoryWithCache = (0, _memoizerific.default)(STORY_CACHE_SIZE)(_csf.prepareStory); // We cannot call `loadStory()` until we've been initialized properly. But we can wait for it.

    this.initializationPromise = new _synchronousPromise.SynchronousPromise(function (resolve) {
      _this.resolveInitializationPromise = resolve;
    });
  }

  _createClass(StoryStore, [{
    key: "setProjectAnnotations",
    value: function setProjectAnnotations(projectAnnotations) {
      // By changing `this.projectAnnotations, we implicitly invalidate the `prepareStoryWithCache`
      this.projectAnnotations = (0, _csf.normalizeProjectAnnotations)(projectAnnotations);
      var globals = projectAnnotations.globals,
          globalTypes = projectAnnotations.globalTypes;
      this.globals.set({
        globals: globals,
        globalTypes: globalTypes
      });
    }
  }, {
    key: "initialize",
    value: function initialize(_ref) {
      var storyIndex = _ref.storyIndex,
          importFn = _ref.importFn,
          _ref$cache = _ref.cache,
          cache = _ref$cache === void 0 ? false : _ref$cache;
      this.storyIndex = new _StoryIndexStore.StoryIndexStore(storyIndex);
      this.importFn = importFn; // We don't need the cache to be loaded to call `loadStory`, we just need the index ready

      this.resolveInitializationPromise();
      return cache ? this.cacheAllCSFFiles() : _synchronousPromise.SynchronousPromise.resolve();
    } // This means that one of the CSF files has changed.
    // If the `importFn` has changed, we will invalidate both caches.
    // If the `storyIndex` data has changed, we may or may not invalidate the caches, depending
    // on whether we've loaded the relevant files yet.

  }, {
    key: "onStoriesChanged",
    value: function () {
      var _onStoriesChanged = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee(_ref2) {
        var importFn, storyIndex;
        return regeneratorRuntime.wrap(function _callee$(_context) {
          while (1) {
            switch (_context.prev = _context.next) {
              case 0:
                importFn = _ref2.importFn, storyIndex = _ref2.storyIndex;
                if (importFn) this.importFn = importFn;
                if (storyIndex) this.storyIndex.stories = storyIndex.stories;

                if (!this.cachedCSFFiles) {
                  _context.next = 6;
                  break;
                }

                _context.next = 6;
                return this.cacheAllCSFFiles();

              case 6:
              case "end":
                return _context.stop();
            }
          }
        }, _callee, this);
      }));

      function onStoriesChanged(_x) {
        return _onStoriesChanged.apply(this, arguments);
      }

      return onStoriesChanged;
    }() // To load a single CSF file to service a story we need to look up the importPath in the index

  }, {
    key: "loadCSFFileByStoryId",
    value: function loadCSFFileByStoryId(storyId) {
      var _this2 = this;

      var _this$storyIndex$stor = this.storyIndex.storyIdToEntry(storyId),
          importPath = _this$storyIndex$stor.importPath,
          title = _this$storyIndex$stor.title;

      return this.importFn(importPath).then(function (moduleExports) {
        return (// We pass the title in here as it may have been generated by autoTitle on the server.
          _this2.processCSFFileWithCache(moduleExports, importPath, title)
        );
      });
    }
  }, {
    key: "loadAllCSFFiles",
    value: function loadAllCSFFiles() {
      var _this3 = this;

      var importPaths = {};
      Object.entries(this.storyIndex.stories).forEach(function (_ref3) {
        var _ref4 = _slicedToArray(_ref3, 2),
            storyId = _ref4[0],
            importPath = _ref4[1].importPath;

        importPaths[importPath] = storyId;
      });
      var csfFilePromiseList = Object.entries(importPaths).map(function (_ref5) {
        var _ref6 = _slicedToArray(_ref5, 2),
            importPath = _ref6[0],
            storyId = _ref6[1];

        return _this3.loadCSFFileByStoryId(storyId).then(function (csfFile) {
          return {
            importPath: importPath,
            csfFile: csfFile
          };
        });
      });
      return _synchronousPromise.SynchronousPromise.all(csfFilePromiseList).then(function (list) {
        return list.reduce(function (acc, _ref7) {
          var importPath = _ref7.importPath,
              csfFile = _ref7.csfFile;
          acc[importPath] = csfFile;
          return acc;
        }, {});
      });
    }
  }, {
    key: "cacheAllCSFFiles",
    value: function cacheAllCSFFiles() {
      var _this4 = this;

      return this.initializationPromise.then(function () {
        return _this4.loadAllCSFFiles().then(function (csfFiles) {
          _this4.cachedCSFFiles = csfFiles;
        });
      });
    } // Load the CSF file for a story and prepare the story from it and the project annotations.

  }, {
    key: "loadStory",
    value: function () {
      var _loadStory = _asyncToGenerator( /*#__PURE__*/regeneratorRuntime.mark(function _callee2(_ref8) {
        var storyId, csfFile;
        return regeneratorRuntime.wrap(function _callee2$(_context2) {
          while (1) {
            switch (_context2.prev = _context2.next) {
              case 0:
                storyId = _ref8.storyId;
                _context2.next = 3;
                return this.initializationPromise;

              case 3:
                _context2.next = 5;
                return this.loadCSFFileByStoryId(storyId);

              case 5:
                csfFile = _context2.sent;
                return _context2.abrupt("return", this.storyFromCSFFile({
                  storyId: storyId,
                  csfFile: csfFile
                }));

              case 7:
              case "end":
                return _context2.stop();
            }
          }
        }, _callee2, this);
      }));

      function loadStory(_x2) {
        return _loadStory.apply(this, arguments);
      }

      return loadStory;
    }() // This function is synchronous for convenience -- often times if you have a CSF file already
    // it is easier not to have to await `loadStory`.

  }, {
    key: "storyFromCSFFile",
    value: function storyFromCSFFile(_ref9) {
      var storyId = _ref9.storyId,
          csfFile = _ref9.csfFile;
      var storyAnnotations = csfFile.stories[storyId];

      if (!storyAnnotations) {
        throw new Error("Didn't find '".concat(storyId, "' in CSF file, this is unexpected"));
      }

      var componentAnnotations = csfFile.meta;
      var story = this.prepareStoryWithCache(storyAnnotations, componentAnnotations, this.projectAnnotations);
      this.args.setInitial(story);
      this.hooks[story.id] = this.hooks[story.id] || new _hooks.HooksContext();
      return story;
    } // If we have a CSF file we can get all the stories from it synchronously

  }, {
    key: "componentStoriesFromCSFFile",
    value: function componentStoriesFromCSFFile(_ref10) {
      var _this5 = this;

      var csfFile = _ref10.csfFile;
      return Object.keys(this.storyIndex.stories).filter(function (storyId) {
        return !!csfFile.stories[storyId];
      }).map(function (storyId) {
        return _this5.storyFromCSFFile({
          storyId: storyId,
          csfFile: csfFile
        });
      });
    } // A prepared story does not include args, globals or hooks. These are stored in the story store
    // and updated separtely to the (immutable) story.

  }, {
    key: "getStoryContext",
    value: function getStoryContext(story) {
      return Object.assign({}, story, {
        args: this.args.get(story.id),
        globals: this.globals.get(),
        hooks: this.hooks[story.id]
      });
    }
  }, {
    key: "cleanupStory",
    value: function cleanupStory(story) {
      this.hooks[story.id].clean();
    }
  }, {
    key: "extract",
    value: function extract() {
      var _this6 = this;

      var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {
        includeDocsOnly: false
      };

      if (!this.cachedCSFFiles) {
        throw new Error('Cannot call extract() unless you call cacheAllCSFFiles() first.');
      }

      return Object.entries(this.storyIndex.stories).reduce(function (acc, _ref11) {
        var _ref12 = _slicedToArray(_ref11, 2),
            storyId = _ref12[0],
            importPath = _ref12[1].importPath;

        var csfFile = _this6.cachedCSFFiles[importPath];

        var story = _this6.storyFromCSFFile({
          storyId: storyId,
          csfFile: csfFile
        });

        if (!options.includeDocsOnly && story.parameters.docsOnly) {
          return acc;
        }

        acc[storyId] = Object.entries(story).reduce(function (storyAcc, _ref13) {
          var _ref14 = _slicedToArray(_ref13, 2),
              key = _ref14[0],
              value = _ref14[1];

          if (typeof value === 'function') {
            return storyAcc;
          }

          if (Array.isArray(value)) {
            return Object.assign(storyAcc, _defineProperty({}, key, value.slice().sort()));
          }

          return Object.assign(storyAcc, _defineProperty({}, key, value));
        }, {
          args: story.initialArgs
        });
        return acc;
      }, {});
    }
  }, {
    key: "getSetStoriesPayload",
    value: function getSetStoriesPayload() {
      var stories = this.extract({
        includeDocsOnly: true
      });
      var kindParameters = Object.values(stories).reduce(function (acc, _ref15) {
        var title = _ref15.title;
        acc[title] = {};
        return acc;
      }, {});
      return {
        v: 2,
        globals: this.globals.get(),
        globalParameters: {},
        kindParameters: kindParameters,
        stories: stories
      };
    }
  }, {
    key: "raw",
    value: function raw() {
      var _this7 = this;

      return Object.values(this.extract()).map(function (_ref16) {
        var id = _ref16.id;
        return _this7.fromId(id);
      });
    }
  }, {
    key: "fromId",
    value: function fromId(storyId) {
      var _this8 = this;

      if (!this.cachedCSFFiles) {
        throw new Error('Cannot call fromId/raw() unless you call cacheAllCSFFiles() first.');
      }

      var importPath;

      try {
        var _this$storyIndex$stor2 = this.storyIndex.storyIdToEntry(storyId);

        importPath = _this$storyIndex$stor2.importPath;
      } catch (err) {
        return null;
      }

      var csfFile = this.cachedCSFFiles[importPath];
      var story = this.storyFromCSFFile({
        storyId: storyId,
        csfFile: csfFile
      });
      return Object.assign({}, story, {
        storyFn: function storyFn(update) {
          var context = Object.assign({}, _this8.getStoryContext(story), {
            viewMode: 'story'
          });
          return story.unboundStoryFn(Object.assign({}, context, update));
        }
      });
    }
  }]);

  return StoryStore;
}();

exports.StoryStore = StoryStore;