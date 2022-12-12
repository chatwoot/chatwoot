import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.object.freeze.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.regexp.exec.js";
var _excluded = ["globals", "globalTypes"],
    _excluded2 = ["decorators", "loaders", "component", "args", "argTypes"],
    _excluded3 = ["component", "args", "argTypes"];

var _templateObject, _templateObject2, _templateObject3, _templateObject4;

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/es.set.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.object.get-prototype-of.js";
import "core-js/modules/es.regexp.to-string.js";
import "core-js/modules/es.object.keys.js";
import "core-js/modules/es.array.concat.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.object.values.js";

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

import deprecate from 'util-deprecate';
import dedent from 'ts-dedent';
import global from 'global';
import { logger } from '@storybook/client-logger';
import { toId, sanitize } from '@storybook/csf';
import { combineParameters, normalizeInputTypes } from '@storybook/store';
import { StoryStoreFacade } from './StoryStoreFacade';
// ClientApi (and StoreStore) are really singletons. However they are not created until the
// relevant framework instanciates them via `start.js`. The good news is this happens right away.
var singleton;
var warningAlternatives = {
  addDecorator: "Instead, use `export const decorators = [];` in your `preview.js`.",
  addParameters: "Instead, use `export const parameters = {};` in your `preview.js`.",
  addLoaders: "Instead, use `export const loaders = [];` in your `preview.js`."
};

var warningMessage = function warningMessage(method) {
  return deprecate(function () {}, dedent(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n  `", "` is deprecated, and will be removed in Storybook 7.0.\n\n  ", "\n\n  Read more at https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-addparameters-and-adddecorator)."], ["\n  \\`", "\\` is deprecated, and will be removed in Storybook 7.0.\n\n  ", "\n\n  Read more at https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-addparameters-and-adddecorator)."])), method, warningAlternatives[method]));
};

var warnings = {
  addDecorator: warningMessage('addDecorator'),
  addParameters: warningMessage('addParameters'),
  addLoaders: warningMessage('addLoaders')
};

var checkMethod = function checkMethod(method, deprecationWarning) {
  var _global$FEATURES;

  if ((_global$FEATURES = global.FEATURES) !== null && _global$FEATURES !== void 0 && _global$FEATURES.storyStoreV7) {
    throw new Error(dedent(_templateObject2 || (_templateObject2 = _taggedTemplateLiteral(["You cannot use `", "` with the new Story Store.\n      \n      ", ""], ["You cannot use \\`", "\\` with the new Story Store.\n      \n      ", ""])), method, warningAlternatives[method]));
  }

  if (!singleton) {
    throw new Error("Singleton client API not yet initialized, cannot call `".concat(method, "`."));
  }

  if (deprecationWarning) {
    warnings[method]();
  }
};

export var addDecorator = function addDecorator(decorator) {
  var deprecationWarning = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
  checkMethod('addDecorator', deprecationWarning);
  singleton.addDecorator(decorator);
};
export var addParameters = function addParameters(parameters) {
  var deprecationWarning = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
  checkMethod('addParameters', deprecationWarning);
  singleton.addParameters(parameters);
};
export var addLoader = function addLoader(loader) {
  var deprecationWarning = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : true;
  checkMethod('addLoader', deprecationWarning);
  singleton.addLoader(loader);
};
export var addArgs = function addArgs(args) {
  checkMethod('addArgs', false);
  singleton.addArgs(args);
};
export var addArgTypes = function addArgTypes(argTypes) {
  checkMethod('addArgTypes', false);
  singleton.addArgTypes(argTypes);
};
export var addArgsEnhancer = function addArgsEnhancer(enhancer) {
  checkMethod('addArgsEnhancer', false);
  singleton.addArgsEnhancer(enhancer);
};
export var addArgTypesEnhancer = function addArgTypesEnhancer(enhancer) {
  checkMethod('addArgTypesEnhancer', false);
  singleton.addArgTypesEnhancer(enhancer);
};
export var getGlobalRender = function getGlobalRender() {
  checkMethod('getGlobalRender', false);
  return singleton.facade.projectAnnotations.render;
};
export var setGlobalRender = function setGlobalRender(render) {
  checkMethod('setGlobalRender', false);
  singleton.facade.projectAnnotations.render = render;
};
var invalidStoryTypes = new Set(['string', 'number', 'boolean', 'symbol']);
export var ClientApi = /*#__PURE__*/function () {
  // If we don't get passed modules so don't know filenames, we can
  // just use numeric indexes
  function ClientApi() {
    var _this = this;

    var _ref = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {},
        storyStore = _ref.storyStore;

    _classCallCheck(this, ClientApi);

    this.facade = void 0;
    this.storyStore = void 0;
    this.addons = void 0;
    this.onImportFnChanged = void 0;
    this.lastFileName = 0;
    this.setAddon = deprecate(function (addon) {
      _this.addons = Object.assign({}, _this.addons, addon);
    }, dedent(_templateObject3 || (_templateObject3 = _taggedTemplateLiteral(["\n      `setAddon` is deprecated and will be removed in Storybook 7.0.\n\n      https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-setaddon\n    "], ["\n      \\`setAddon\\` is deprecated and will be removed in Storybook 7.0.\n\n      https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-setaddon\n    "]))));

    this.addDecorator = function (decorator) {
      _this.facade.projectAnnotations.decorators.push(decorator);
    };

    this.clearDecorators = deprecate(function () {
      _this.facade.projectAnnotations.decorators = [];
    }, dedent(_templateObject4 || (_templateObject4 = _taggedTemplateLiteral(["\n      `clearDecorators` is deprecated and will be removed in Storybook 7.0.\n\n      https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-cleardecorators\n    "], ["\n      \\`clearDecorators\\` is deprecated and will be removed in Storybook 7.0.\n\n      https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-cleardecorators\n    "]))));

    this.addParameters = function (_ref2) {
      var globals = _ref2.globals,
          globalTypes = _ref2.globalTypes,
          parameters = _objectWithoutProperties(_ref2, _excluded);

      _this.facade.projectAnnotations.parameters = combineParameters(_this.facade.projectAnnotations.parameters, parameters);

      if (globals) {
        _this.facade.projectAnnotations.globals = Object.assign({}, _this.facade.projectAnnotations.globals, globals);
      }

      if (globalTypes) {
        _this.facade.projectAnnotations.globalTypes = Object.assign({}, _this.facade.projectAnnotations.globalTypes, normalizeInputTypes(globalTypes));
      }
    };

    this.addLoader = function (loader) {
      _this.facade.projectAnnotations.loaders.push(loader);
    };

    this.addArgs = function (args) {
      _this.facade.projectAnnotations.args = Object.assign({}, _this.facade.projectAnnotations.args, args);
    };

    this.addArgTypes = function (argTypes) {
      _this.facade.projectAnnotations.argTypes = Object.assign({}, _this.facade.projectAnnotations.argTypes, normalizeInputTypes(argTypes));
    };

    this.addArgsEnhancer = function (enhancer) {
      _this.facade.projectAnnotations.argsEnhancers.push(enhancer);
    };

    this.addArgTypesEnhancer = function (enhancer) {
      _this.facade.projectAnnotations.argTypesEnhancers.push(enhancer);
    };

    this.storiesOf = function (kind, m) {
      if (!kind && typeof kind !== 'string') {
        throw new Error('Invalid or missing kind provided for stories, should be a string');
      }

      if (!m) {
        logger.warn("Missing 'module' parameter for story with a kind of '".concat(kind, "'. It will break your HMR"));
      }

      if (m) {
        var proto = Object.getPrototypeOf(m);

        if (proto.exports && proto.exports.default) {
          // FIXME: throw an error in SB6.0
          logger.error("Illegal mix of CSF default export and storiesOf calls in a single file: ".concat(proto.i));
        }
      } // eslint-disable-next-line no-plusplus


      var baseFilename = m && m.id ? "".concat(m.id) : (_this.lastFileName++).toString();
      var fileName = baseFilename;
      var i = 1; // Deal with `storiesOf()` being called twice in the same file.
      // On HMR, `this.csfExports[fileName]` will be reset to `{}`, so an empty object is due
      // to this export, not a second call of `storiesOf()`.

      while (_this.facade.csfExports[fileName] && Object.keys(_this.facade.csfExports[fileName]).length > 0) {
        i += 1;
        fileName = "".concat(baseFilename, "-").concat(i);
      }

      if (m && m.hot && m.hot.accept) {
        // This module used storiesOf(), so when it re-runs on HMR, it will reload
        // itself automatically without us needing to look at our imports
        m.hot.accept();
        m.hot.dispose(function () {
          _this.facade.clearFilenameExports(fileName); // We need to update the importFn as soon as the module re-evaluates
          // (and calls storiesOf() again, etc). We could call `onImportFnChanged()`
          // at the end of every setStories call (somehow), but then we'd need to
          // debounce it somehow for initial startup. Instead, we'll take advantage of
          // the fact that the evaluation of the module happens immediately in the same tick


          setTimeout(function () {
            var _this$onImportFnChang;

            (_this$onImportFnChang = _this.onImportFnChanged) === null || _this$onImportFnChang === void 0 ? void 0 : _this$onImportFnChang.call(_this, {
              importFn: _this.importFn.bind(_this)
            });
          }, 0);
        });
      }

      var hasAdded = false;
      var api = {
        kind: kind.toString(),
        add: function add() {
          return api;
        },
        addDecorator: function addDecorator() {
          return api;
        },
        addLoader: function addLoader() {
          return api;
        },
        addParameters: function addParameters() {
          return api;
        }
      }; // apply addons

      Object.keys(_this.addons).forEach(function (name) {
        var addon = _this.addons[name];

        api[name] = function () {
          for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
            args[_key] = arguments[_key];
          }

          addon.apply(api, args);
          return api;
        };
      });
      var meta = {
        id: sanitize(kind),
        title: kind,
        decorators: [],
        loaders: [],
        parameters: {}
      }; // We map these back to a simple default export, even though we have type guarantees at this point

      _this.facade.csfExports[fileName] = {
        default: meta
      };
      var counter = 0;

      api.add = function (storyName, storyFn) {
        var parameters = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
        hasAdded = true;

        if (typeof storyName !== 'string') {
          throw new Error("Invalid or missing storyName provided for a \"".concat(kind, "\" story."));
        }

        if (!storyFn || Array.isArray(storyFn) || invalidStoryTypes.has(_typeof(storyFn))) {
          throw new Error("Cannot load story \"".concat(storyName, "\" in \"").concat(kind, "\" due to invalid format. Storybook expected a function/object but received ").concat(_typeof(storyFn), " instead."));
        }

        var decorators = parameters.decorators,
            loaders = parameters.loaders,
            component = parameters.component,
            args = parameters.args,
            argTypes = parameters.argTypes,
            storyParameters = _objectWithoutProperties(parameters, _excluded2); // eslint-disable-next-line no-underscore-dangle


        var storyId = parameters.__id || toId(kind, storyName);
        var csfExports = _this.facade.csfExports[fileName]; // Whack a _ on the front incase it is "default"

        csfExports["story".concat(counter)] = {
          name: storyName,
          parameters: Object.assign({
            fileName: fileName,
            __id: storyId
          }, storyParameters),
          decorators: decorators,
          loaders: loaders,
          args: args,
          argTypes: argTypes,
          component: component,
          render: storyFn
        };
        counter += 1;
        _this.facade.stories[storyId] = {
          id: storyId,
          title: csfExports.default.title,
          name: storyName,
          importPath: fileName
        };
        return api;
      };

      api.addDecorator = function (decorator) {
        if (hasAdded) throw new Error("You cannot add a decorator after the first story for a kind.\nRead more here: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#can-no-longer-add-decoratorsparameters-after-stories");
        meta.decorators.push(decorator);
        return api;
      };

      api.addLoader = function (loader) {
        if (hasAdded) throw new Error("You cannot add a loader after the first story for a kind.");
        meta.loaders.push(loader);
        return api;
      };

      api.addParameters = function (_ref3) {
        var component = _ref3.component,
            args = _ref3.args,
            argTypes = _ref3.argTypes,
            parameters = _objectWithoutProperties(_ref3, _excluded3);

        if (hasAdded) throw new Error("You cannot add parameters after the first story for a kind.\nRead more here: https://github.com/storybookjs/storybook/blob/master/MIGRATION.md#can-no-longer-add-decoratorsparameters-after-stories");
        meta.parameters = combineParameters(meta.parameters, parameters);
        if (component) meta.component = component;
        if (args) meta.args = Object.assign({}, meta.args, args);
        if (argTypes) meta.argTypes = Object.assign({}, meta.argTypes, argTypes);
        return api;
      };

      return api;
    };

    this.getStorybook = function () {
      var stories = _this.storyStore.storyIndex.stories;
      var kinds = {};
      Object.entries(stories).forEach(function (_ref4) {
        var _ref5 = _slicedToArray(_ref4, 2),
            storyId = _ref5[0],
            _ref5$ = _ref5[1],
            title = _ref5$.title,
            name = _ref5$.name,
            importPath = _ref5$.importPath;

        if (!kinds[title]) {
          kinds[title] = {
            kind: title,
            fileName: importPath,
            stories: []
          };
        }

        var _this$storyStore$from = _this.storyStore.fromId(storyId),
            storyFn = _this$storyStore$from.storyFn;

        kinds[title].stories.push({
          name: name,
          render: storyFn
        });
      });
      return Object.values(kinds);
    };

    this.raw = function () {
      return _this.storyStore.raw();
    };

    this.facade = new StoryStoreFacade();
    this.addons = {};
    this.storyStore = storyStore;
    singleton = this;
  }

  _createClass(ClientApi, [{
    key: "importFn",
    value: function importFn(path) {
      return this.facade.importFn(path);
    }
  }, {
    key: "getStoryIndex",
    value: function getStoryIndex() {
      if (!this.storyStore) {
        throw new Error('Cannot get story index before setting storyStore');
      }

      return this.facade.getStoryIndex(this.storyStore);
    }
  }, {
    key: "_storyStore",
    get: // @deprecated
    function get() {
      return this.storyStore;
    }
  }]);

  return ClientApi;
}();