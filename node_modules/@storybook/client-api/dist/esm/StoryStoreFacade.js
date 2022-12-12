import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.object.freeze.js";
var _excluded = ["default", "__namedExportsOrder"];

var _templateObject;

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.regexp.constructor.js";
import "core-js/modules/es.regexp.exec.js";
import "core-js/modules/es.regexp.to-string.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.function.name.js";

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

import global from 'global';
import dedent from 'ts-dedent';
import { SynchronousPromise } from 'synchronous-promise';
import { toId, isExportStory, storyNameFromExport } from '@storybook/csf';
import { userOrAutoTitle, sortStoriesV6 } from '@storybook/store';
import { logger } from '@storybook/client-logger';
export var StoryStoreFacade = /*#__PURE__*/function () {
  function StoryStoreFacade() {
    _classCallCheck(this, StoryStoreFacade);

    this.projectAnnotations = void 0;
    this.stories = void 0;
    this.csfExports = void 0;
    this.projectAnnotations = {
      loaders: [],
      decorators: [],
      parameters: {},
      argsEnhancers: [],
      argTypesEnhancers: [],
      args: {},
      argTypes: {}
    };
    this.stories = {};
    this.csfExports = {};
  } // This doesn't actually import anything because the client-api loads fully
  // on startup, but this is a shim after all.


  _createClass(StoryStoreFacade, [{
    key: "importFn",
    value: function importFn(path) {
      var _this = this;

      return SynchronousPromise.resolve().then(function () {
        var moduleExports = _this.csfExports[path];
        if (!moduleExports) throw new Error("Unknown path: ".concat(path));
        return moduleExports;
      });
    }
  }, {
    key: "getStoryIndex",
    value: function getStoryIndex(store) {
      var _this$projectAnnotati,
          _this$projectAnnotati2,
          _this2 = this;

      var fileNameOrder = Object.keys(this.csfExports);
      var storySortParameter = (_this$projectAnnotati = this.projectAnnotations.parameters) === null || _this$projectAnnotati === void 0 ? void 0 : (_this$projectAnnotati2 = _this$projectAnnotati.options) === null || _this$projectAnnotati2 === void 0 ? void 0 : _this$projectAnnotati2.storySort;
      var storyEntries = Object.entries(this.stories); // Add the kind parameters and global parameters to each entry

      var sortableV6 = storyEntries.map(function (_ref) {
        var _ref2 = _slicedToArray(_ref, 2),
            storyId = _ref2[0],
            importPath = _ref2[1].importPath;

        var exports = _this2.csfExports[importPath];
        var csfFile = store.processCSFFileWithCache(exports, importPath, exports.default.title);
        return [storyId, store.storyFromCSFFile({
          storyId: storyId,
          csfFile: csfFile
        }), csfFile.meta.parameters, _this2.projectAnnotations.parameters];
      }); // NOTE: the sortStoriesV6 version returns the v7 data format. confusing but more convenient!

      var sortedV7;

      try {
        sortedV7 = sortStoriesV6(sortableV6, storySortParameter, fileNameOrder);
      } catch (err) {
        if (typeof storySortParameter === 'function') {
          throw new Error(dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n          Error sorting stories with sort parameter ", ":\n\n          > ", "\n          \n          Are you using a V7-style sort function in V6 compatibility mode?\n          \n          More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#v7-style-story-sort\n        "])), storySortParameter, err.message));
        }

        throw err;
      }

      var stories = sortedV7.reduce(function (acc, s) {
        // We use the original entry we stored in `this.stories` because it is possible that the CSF file itself
        // exports a `parameters.fileName` which can be different and mess up our `importFn`.
        // In fact, in Storyshots there is a Jest transformer that does exactly that.
        // NOTE: this doesn't actually change the story object, just the index.
        acc[s.id] = _this2.stories[s.id];
        return acc;
      }, {});
      return {
        v: 3,
        stories: stories
      };
    }
  }, {
    key: "clearFilenameExports",
    value: function clearFilenameExports(fileName) {
      var _this3 = this;

      if (!this.csfExports[fileName]) {
        return;
      } // Clear this module's stories from the storyList and existing exports


      Object.entries(this.stories).forEach(function (_ref3) {
        var _ref4 = _slicedToArray(_ref3, 2),
            id = _ref4[0],
            importPath = _ref4[1].importPath;

        if (importPath === fileName) {
          delete _this3.stories[id];
        }
      }); // We keep this as an empty record so we can use it to maintain component order

      this.csfExports[fileName] = {};
    } // NOTE: we could potentially share some of this code with the stories.json generation

  }, {
    key: "addStoriesFromExports",
    value: function addStoriesFromExports(fileName, fileExports) {
      var _this4 = this;

      // if the export haven't changed since last time we added them, this is a no-op
      if (this.csfExports[fileName] === fileExports) {
        return;
      } // OTOH, if they have changed, let's clear them out first


      this.clearFilenameExports(fileName);

      var defaultExport = fileExports.default,
          __namedExportsOrder = fileExports.__namedExportsOrder,
          namedExports = _objectWithoutProperties(fileExports, _excluded); // eslint-disable-next-line prefer-const


      var _ref5 = defaultExport || {},
          componentId = _ref5.id,
          title = _ref5.title;

      var specifiers = (global.STORIES || []).map(function (specifier) {
        return Object.assign({}, specifier, {
          importPathMatcher: new RegExp(specifier.importPathMatcher)
        });
      });
      title = userOrAutoTitle(fileName, specifiers, title);

      if (!title) {
        logger.info("Unexpected default export without title in '".concat(fileName, "': ").concat(JSON.stringify(fileExports.default)));
        return;
      }

      this.csfExports[fileName] = Object.assign({}, fileExports, {
        default: Object.assign({}, defaultExport, {
          title: title
        })
      });
      var sortedExports = namedExports; // prefer a user/loader provided `__namedExportsOrder` array if supplied
      // we do this as es module exports are always ordered alphabetically
      // see https://github.com/storybookjs/storybook/issues/9136

      if (Array.isArray(__namedExportsOrder)) {
        sortedExports = {};

        __namedExportsOrder.forEach(function (name) {
          var namedExport = namedExports[name];
          if (namedExport) sortedExports[name] = namedExport;
        });
      }

      Object.entries(sortedExports).filter(function (_ref6) {
        var _ref7 = _slicedToArray(_ref6, 1),
            key = _ref7[0];

        return isExportStory(key, defaultExport);
      }).forEach(function (_ref8) {
        var _storyExport$paramete, _storyExport$story;

        var _ref9 = _slicedToArray(_ref8, 2),
            key = _ref9[0],
            storyExport = _ref9[1];

        var exportName = storyNameFromExport(key);
        var id = ((_storyExport$paramete = storyExport.parameters) === null || _storyExport$paramete === void 0 ? void 0 : _storyExport$paramete.__id) || toId(componentId || title, exportName);
        var name = typeof storyExport !== 'function' && storyExport.name || storyExport.storyName || ((_storyExport$story = storyExport.story) === null || _storyExport$story === void 0 ? void 0 : _storyExport$story.name) || exportName;
        _this4.stories[id] = {
          id: id,
          name: name,
          title: title,
          importPath: fileName
        };
      });
    }
  }]);

  return StoryStoreFacade;
}();