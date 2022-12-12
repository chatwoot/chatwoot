"use strict";

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.init = void 0;

require("core-js/modules/es.array.includes.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.sort.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.object.assign.js");

var _clientLogger = require("@storybook/client-logger");

var _coreEvents = require("@storybook/core-events");

var _router = require("@storybook/router");

var _csf = require("@storybook/csf");

var _fastDeepEqual = _interopRequireDefault(require("fast-deep-equal"));

var _global = _interopRequireDefault(require("global"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _stories = require("../lib/stories");

var _templateObject, _templateObject2, _templateObject3, _templateObject4;

var _excluded = ["full", "panel", "nav", "shortcuts", "addonPanel", "tabs", "addons", "panelRight", "stories", "selectedKind", "selectedStory", "path"],
    _excluded2 = ["store", "navigate", "state", "provider", "fullAPI"];

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

var globalWindow = _global.default.window;

var parseBoolean = function parseBoolean(value) {
  if (value === 'true' || value === '1') return true;
  if (value === 'false' || value === '0') return false;
  return undefined;
}; // Initialize the state based on the URL.
// NOTE:
//   Although we don't change the URL when you change the state, we do support setting initial state
//   via the following URL parameters:
//     - full: 0/1 -- show fullscreen
//     - panel: bottom/right/0 -- set addons panel position (or hide)
//     - nav: 0/1 -- show or hide the story list
//
//   We also support legacy URLs from storybook <5


var prevParams;

var initialUrlSupport = function initialUrlSupport(_ref) {
  var _ref$state = _ref.state,
      location = _ref$state.location,
      path = _ref$state.path,
      viewMode = _ref$state.viewMode,
      storyIdFromUrl = _ref$state.storyId,
      singleStory = _ref.singleStory;

  var _queryFromLocation = (0, _router.queryFromLocation)(location),
      full = _queryFromLocation.full,
      panel = _queryFromLocation.panel,
      nav = _queryFromLocation.nav,
      shortcuts = _queryFromLocation.shortcuts,
      addonPanel = _queryFromLocation.addonPanel,
      tabs = _queryFromLocation.tabs,
      addons = _queryFromLocation.addons,
      panelRight = _queryFromLocation.panelRight,
      stories = _queryFromLocation.stories,
      selectedKind = _queryFromLocation.selectedKind,
      selectedStory = _queryFromLocation.selectedStory,
      queryPath = _queryFromLocation.path,
      otherParams = _objectWithoutProperties(_queryFromLocation, _excluded);

  var layout = {
    isFullscreen: parseBoolean(full),
    showNav: !singleStory && parseBoolean(nav),
    showPanel: parseBoolean(panel),
    panelPosition: ['right', 'bottom'].includes(panel) ? panel : undefined,
    showTabs: parseBoolean(tabs)
  };
  var ui = {
    enableShortcuts: parseBoolean(shortcuts)
  };
  var selectedPanel = addonPanel || undefined; // @deprecated Superceded by `panel=false`, to be removed in 7.0

  if (addons === '0') {
    _clientLogger.once.warn((0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n      The 'addons' query param is deprecated and will be removed in Storybook 7.0. Use 'panel=false' instead.\n\n      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params\n    "]))));

    layout.showPanel = false;
  } // @deprecated Superceded by `panel=right`, to be removed in 7.0


  if (panelRight === '1') {
    _clientLogger.once.warn((0, _tsDedent.default)(_templateObject2 || (_templateObject2 = _taggedTemplateLiteral(["\n      The 'panelRight' query param is deprecated and will be removed in Storybook 7.0. Use 'panel=right' instead.\n\n      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params\n    "]))));

    layout.panelPosition = 'right';
  } // @deprecated Superceded by `nav=false`, to be removed in 7.0


  if (stories === '0') {
    _clientLogger.once.warn((0, _tsDedent.default)(_templateObject3 || (_templateObject3 = _taggedTemplateLiteral(["\n      The 'stories' query param is deprecated and will be removed in Storybook 7.0. Use 'nav=false' instead.\n\n      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params\n    "]))));

    layout.showNav = false;
  } // @deprecated To be removed in 7.0
  // If the user hasn't set the storyId on the URL, we support legacy URLs (selectedKind/selectedStory)
  // NOTE: this "storyId" can just be a prefix of a storyId, really it is a storyIdSpecifier.


  var storyId = storyIdFromUrl;

  if (!storyId && selectedKind) {
    _clientLogger.once.warn((0, _tsDedent.default)(_templateObject4 || (_templateObject4 = _taggedTemplateLiteral(["\n      The 'selectedKind' and 'selectedStory' query params are deprecated and will be removed in Storybook 7.0. Use 'path' instead.\n\n      More info: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md#deprecated-layout-url-params\n    "]))));

    storyId = selectedStory ? (0, _csf.toId)(selectedKind, selectedStory) : (0, _csf.sanitize)(selectedKind);
  } // Avoid returning a new object each time if no params actually changed.


  var customQueryParams = (0, _fastDeepEqual.default)(prevParams, otherParams) ? prevParams : otherParams;
  prevParams = customQueryParams;
  return {
    viewMode: viewMode,
    layout: layout,
    ui: ui,
    selectedPanel: selectedPanel,
    location: location,
    path: path,
    customQueryParams: customQueryParams,
    storyId: storyId
  };
};

var init = function init(_ref2) {
  var store = _ref2.store,
      navigate = _ref2.navigate,
      state = _ref2.state,
      provider = _ref2.provider,
      fullAPI = _ref2.fullAPI,
      rest = _objectWithoutProperties(_ref2, _excluded2);

  var navigateTo = function navigateTo(path) {
    var queryParams = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};
    var options = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : {};
    var params = Object.entries(queryParams).filter(function (_ref3) {
      var _ref4 = _slicedToArray(_ref3, 2),
          v = _ref4[1];

      return v;
    }).sort(function (_ref5, _ref6) {
      var _ref7 = _slicedToArray(_ref5, 1),
          a = _ref7[0];

      var _ref8 = _slicedToArray(_ref6, 1),
          b = _ref8[0];

      return a < b ? -1 : 1;
    }).map(function (_ref9) {
      var _ref10 = _slicedToArray(_ref9, 2),
          k = _ref10[0],
          v = _ref10[1];

      return "".concat(k, "=").concat(v);
    });
    var to = [path].concat(_toConsumableArray(params)).join('&');
    return navigate(to, options);
  };

  var api = {
    getQueryParam: function getQueryParam(key) {
      var _store$getState = store.getState(),
          customQueryParams = _store$getState.customQueryParams;

      return customQueryParams ? customQueryParams[key] : undefined;
    },
    getUrlState: function getUrlState() {
      var _store$getState2 = store.getState(),
          path = _store$getState2.path,
          customQueryParams = _store$getState2.customQueryParams,
          storyId = _store$getState2.storyId,
          url = _store$getState2.url,
          viewMode = _store$getState2.viewMode;

      return {
        path: path,
        queryParams: customQueryParams,
        storyId: storyId,
        url: url,
        viewMode: viewMode
      };
    },
    setQueryParams: function setQueryParams(input) {
      var _store$getState3 = store.getState(),
          customQueryParams = _store$getState3.customQueryParams;

      var queryParams = {};
      var update = Object.assign({}, customQueryParams, Object.entries(input).reduce(function (acc, _ref11) {
        var _ref12 = _slicedToArray(_ref11, 2),
            key = _ref12[0],
            value = _ref12[1];

        if (value !== null) {
          acc[key] = value;
        }

        return acc;
      }, queryParams));

      if (!(0, _fastDeepEqual.default)(customQueryParams, update)) {
        store.setState({
          customQueryParams: update
        });
        fullAPI.emit(_coreEvents.UPDATE_QUERY_PARAMS, update);
      }
    },
    navigateUrl: function navigateUrl(url, options) {
      navigate(url, Object.assign({}, options, {
        plain: true
      }));
    }
  };

  var initModule = function initModule() {
    // Sets `args` parameter in URL, omitting any args that have their initial value or cannot be unserialized safely.
    var updateArgsParam = function updateArgsParam() {
      var _fullAPI$getUrlState = fullAPI.getUrlState(),
          path = _fullAPI$getUrlState.path,
          queryParams = _fullAPI$getUrlState.queryParams,
          viewMode = _fullAPI$getUrlState.viewMode;

      if (viewMode !== 'story') return;
      var currentStory = fullAPI.getCurrentStoryData();
      if (!(0, _stories.isStory)(currentStory)) return;
      var args = currentStory.args,
          initialArgs = currentStory.initialArgs;
      var argsString = (0, _router.buildArgsParam)(initialArgs, args);
      navigateTo(path, Object.assign({}, queryParams, {
        args: argsString
      }), {
        replace: true
      });
      api.setQueryParams({
        args: argsString
      });
    };

    fullAPI.on(_coreEvents.SET_CURRENT_STORY, function () {
      return updateArgsParam();
    });
    var handleOrId;
    fullAPI.on(_coreEvents.STORY_ARGS_UPDATED, function () {
      if ('requestIdleCallback' in globalWindow) {
        if (handleOrId) globalWindow.cancelIdleCallback(handleOrId);
        handleOrId = globalWindow.requestIdleCallback(updateArgsParam, {
          timeout: 1000
        });
      } else {
        if (handleOrId) clearTimeout(handleOrId);
        setTimeout(updateArgsParam, 100);
      }
    });
    fullAPI.on(_coreEvents.GLOBALS_UPDATED, function (_ref13) {
      var globals = _ref13.globals,
          initialGlobals = _ref13.initialGlobals;

      var _fullAPI$getUrlState2 = fullAPI.getUrlState(),
          path = _fullAPI$getUrlState2.path,
          queryParams = _fullAPI$getUrlState2.queryParams;

      var globalsString = (0, _router.buildArgsParam)(initialGlobals, globals);
      navigateTo(path, Object.assign({}, queryParams, {
        globals: globalsString
      }), {
        replace: true
      });
      api.setQueryParams({
        globals: globalsString
      });
    });
    fullAPI.on(_coreEvents.NAVIGATE_URL, function (url, options) {
      fullAPI.navigateUrl(url, options);
    });

    if (fullAPI.showReleaseNotesOnLaunch()) {
      navigate('/settings/release-notes');
    }
  };

  return {
    api: api,
    state: initialUrlSupport(Object.assign({
      store: store,
      navigate: navigate,
      state: state,
      provider: provider,
      fullAPI: fullAPI
    }, rest)),
    init: initModule
  };
};

exports.init = init;