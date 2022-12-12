function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); Object.defineProperty(subClass, "prototype", { writable: false }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _createSuper(Derived) { var hasNativeReflectConstruct = _isNativeReflectConstruct(); return function _createSuperInternal() { var Super = _getPrototypeOf(Derived), result; if (hasNativeReflectConstruct) { var NewTarget = _getPrototypeOf(this).constructor; result = Reflect.construct(Super, arguments, NewTarget); } else { result = Super.apply(this, arguments); } return _possibleConstructorReturn(this, result); }; }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } else if (call !== void 0) { throw new TypeError("Derived constructors may only return object or undefined"); } return _assertThisInitialized(self); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _isNativeReflectConstruct() { if (typeof Reflect === "undefined" || !Reflect.construct) return false; if (Reflect.construct.sham) return false; if (typeof Proxy === "function") return true; try { Boolean.prototype.valueOf.call(Reflect.construct(Boolean, [], function () {})); return true; } catch (e) { return false; } }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

import "core-js/modules/es.array.concat.js";
import "core-js/modules/es.object.to-string.js";
import "core-js/modules/web.dom-collections.for-each.js";
import "core-js/modules/es.object.assign.js";
import "core-js/modules/es.array.map.js";
import "core-js/modules/es.array.filter.js";
import "core-js/modules/es.object.entries.js";
import "core-js/modules/es.object.get-prototype-of.js";
import "core-js/modules/es.reflect.construct.js";
import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import "core-js/modules/es.symbol.iterator.js";
import "core-js/modules/es.array.iterator.js";
import "core-js/modules/es.string.iterator.js";
import "core-js/modules/web.dom-collections.iterator.js";
import "core-js/modules/es.array.from.js";
import "core-js/modules/es.array.slice.js";
import "core-js/modules/es.function.name.js";
import "core-js/modules/es.regexp.exec.js";
import React, { Component, Fragment, useCallback, useContext, useEffect, useMemo, useRef } from 'react';
import mergeWith from 'lodash/mergeWith';
import { STORY_CHANGED, SHARED_STATE_CHANGED, SHARED_STATE_SET, SET_STORIES } from '@storybook/core-events';
import { createContext } from './context';
import Store from './store';
import getInitialState from './initial-state';
import { isGroup, isRoot, isStory } from './lib/stories';
import * as provider from './modules/provider';
import * as addons from './modules/addons';
import * as channel from './modules/channel';
import * as notifications from './modules/notifications';
import * as settings from './modules/settings';
import * as releaseNotes from './modules/release-notes';
import * as stories from './modules/stories';
import * as refs from './modules/refs';
import * as layout from './modules/layout';
import * as shortcuts from './modules/shortcuts';
import * as url from './modules/url';
import * as version from './modules/versions';
import * as globals from './modules/globals';
var ActiveTabs = layout.ActiveTabs;
export { default as merge } from './lib/merge';
export { ActiveTabs };
var ManagerContext = createContext({
  api: undefined,
  state: getInitialState({})
});
// This is duplicated from @storybook/client-api for the reasons mentioned in lib-addons/types.js
export var combineParameters = function combineParameters() {
  for (var _len = arguments.length, parameterSets = new Array(_len), _key = 0; _key < _len; _key++) {
    parameterSets[_key] = arguments[_key];
  }

  return mergeWith.apply(void 0, [{}].concat(parameterSets, [function (objValue, srcValue) {
    // Treat arrays as scalars:
    if (Array.isArray(srcValue)) return srcValue;
    return undefined;
  }]));
};

var ManagerProvider = /*#__PURE__*/function (_Component) {
  _inherits(ManagerProvider, _Component);

  var _super = _createSuper(ManagerProvider);

  function ManagerProvider(props) {
    var _this;

    _classCallCheck(this, ManagerProvider);

    _this = _super.call(this, props);
    _this.api = {};
    _this.modules = void 0;

    _this.initModules = function () {
      // Now every module has had a chance to set its API, call init on each module which gives it
      // a chance to do things that call other modules' APIs.
      _this.modules.forEach(function (_ref) {
        var init = _ref.init;

        if (init) {
          init();
        }
      });
    };

    var location = props.location,
        path = props.path,
        refId = props.refId,
        _props$viewMode = props.viewMode,
        viewMode = _props$viewMode === void 0 ? props.docsMode ? 'docs' : 'story' : _props$viewMode,
        singleStory = props.singleStory,
        storyId = props.storyId,
        docsMode = props.docsMode,
        navigate = props.navigate;
    var store = new Store({
      getState: function getState() {
        return _this.state;
      },
      setState: function setState(stateChange, callback) {
        return _this.setState(stateChange, callback);
      }
    });
    var routeData = {
      location: location,
      path: path,
      viewMode: viewMode,
      singleStory: singleStory,
      storyId: storyId,
      refId: refId
    }; // Initialize the state to be the initial (persisted) state of the store.
    // This gives the modules the chance to read the persisted state, apply their defaults
    // and override if necessary

    var docsModeState = {
      layout: {
        showToolbar: false,
        showPanel: false
      },
      ui: {
        docsMode: true
      }
    };
    _this.state = store.getInitialState(getInitialState(Object.assign({}, routeData, docsMode ? docsModeState : null)));
    var apiData = {
      navigate: navigate,
      store: store,
      provider: props.provider
    };
    _this.modules = [provider, channel, addons, layout, notifications, settings, releaseNotes, shortcuts, stories, refs, globals, url, version].map(function (m) {
      return m.init(Object.assign({}, routeData, apiData, {
        state: _this.state,
        fullAPI: _this.api
      }));
    }); // Create our initial state by combining the initial state of all modules, then overlaying any saved state

    var state = getInitialState.apply(void 0, [_this.state].concat(_toConsumableArray(_this.modules.map(function (m) {
      return m.state;
    })))); // Get our API by combining the APIs exported by each module

    var api = Object.assign.apply(Object, [_this.api, {
      navigate: navigate
    }].concat(_toConsumableArray(_this.modules.map(function (m) {
      return m.api;
    }))));
    _this.state = state;
    _this.api = api;
    return _this;
  }

  _createClass(ManagerProvider, [{
    key: "shouldComponentUpdate",
    value: function shouldComponentUpdate(nextProps, nextState) {
      var prevState = this.state;
      var prevProps = this.props;

      if (prevState !== nextState) {
        return true;
      }

      if (prevProps.path !== nextProps.path) {
        return true;
      }

      return false;
    }
  }, {
    key: "render",
    value: function render() {
      var children = this.props.children;
      var value = {
        state: this.state,
        api: this.api
      };
      return /*#__PURE__*/React.createElement(EffectOnMount, {
        effect: this.initModules
      }, /*#__PURE__*/React.createElement(ManagerContext.Provider, {
        value: value
      }, /*#__PURE__*/React.createElement(ManagerConsumer, null, children)));
    }
  }], [{
    key: "getDerivedStateFromProps",
    value: function getDerivedStateFromProps(props, state) {
      if (state.path !== props.path) {
        return Object.assign({}, state, {
          location: props.location,
          path: props.path,
          refId: props.refId,
          // if its a docsOnly page, even the 'story' view mode is considered 'docs'
          viewMode: (props.docsMode && props.viewMode) === 'story' ? 'docs' : props.viewMode,
          storyId: props.storyId
        });
      }

      return null;
    }
  }]);

  return ManagerProvider;
}(Component);

ManagerProvider.displayName = "ManagerProvider";
ManagerProvider.displayName = 'Manager';

// EffectOnMount exists to work around a bug in Reach Router where calling
// navigate inside of componentDidMount (as could happen when we call init on any
// of our modules) does not cause Reach Router's LocationProvider to update with
// the correct path. Calling navigate inside on an effect does not have the
// same problem. See https://github.com/reach/router/issues/404
var EffectOnMount = function EffectOnMount(_ref2) {
  var children = _ref2.children,
      effect = _ref2.effect;
  React.useEffect(effect, []);
  return children;
};

var defaultFilter = function defaultFilter(c) {
  return c;
};

function ManagerConsumer(_ref3) {
  var _ref3$filter = _ref3.filter,
      filter = _ref3$filter === void 0 ? defaultFilter : _ref3$filter,
      children = _ref3.children;
  var c = useContext(ManagerContext);
  var renderer = useRef(children);
  var filterer = useRef(filter);

  if (typeof renderer.current !== 'function') {
    return /*#__PURE__*/React.createElement(Fragment, null, renderer.current);
  }

  var data = filterer.current(c);
  var l = useMemo(function () {
    return _toConsumableArray(Object.entries(data).reduce(function (acc, keyval) {
      return acc.concat(keyval);
    }, []));
  }, [c.state]);
  return useMemo(function () {
    var Child = renderer.current;
    return /*#__PURE__*/React.createElement(Child, data);
  }, l);
}

export function useStorybookState() {
  var _useContext = useContext(ManagerContext),
      state = _useContext.state;

  return state;
}
export function useStorybookApi() {
  var _useContext2 = useContext(ManagerContext),
      api = _useContext2.api;

  return api;
}
export { ManagerConsumer as Consumer, ManagerProvider as Provider, isGroup, isRoot, isStory };

function orDefault(fromStore, defaultState) {
  if (typeof fromStore === 'undefined') {
    return defaultState;
  }

  return fromStore;
}

export var useChannel = function useChannel(eventMap) {
  var deps = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : [];
  var api = useStorybookApi();
  useEffect(function () {
    Object.entries(eventMap).forEach(function (_ref4) {
      var _ref5 = _slicedToArray(_ref4, 2),
          type = _ref5[0],
          listener = _ref5[1];

      return api.on(type, listener);
    });
    return function () {
      Object.entries(eventMap).forEach(function (_ref6) {
        var _ref7 = _slicedToArray(_ref6, 2),
            type = _ref7[0],
            listener = _ref7[1];

        return api.off(type, listener);
      });
    };
  }, deps);
  return api.emit;
};
export function useStoryPrepared(storyId) {
  var api = useStorybookApi();
  return api.isPrepared(storyId);
}
export function useParameter(parameterKey, defaultValue) {
  var api = useStorybookApi();
  var result = api.getCurrentParameter(parameterKey);
  return orDefault(result, defaultValue);
}
// cache for taking care of HMR
var addonStateCache = {}; // shared state

export function useSharedState(stateId, defaultState) {
  var api = useStorybookApi();
  var existingState = api.getAddonState(stateId);
  var state = orDefault(existingState, addonStateCache[stateId] ? addonStateCache[stateId] : defaultState);

  var setState = function setState(s, options) {
    // set only after the stories are loaded
    if (addonStateCache[stateId]) {
      addonStateCache[stateId] = s;
    }

    api.setAddonState(stateId, s, options);
  };

  var allListeners = useMemo(function () {
    var _stateChangeHandlers, _stateInitializationH;

    var stateChangeHandlers = (_stateChangeHandlers = {}, _defineProperty(_stateChangeHandlers, "".concat(SHARED_STATE_CHANGED, "-client-").concat(stateId), function client(s) {
      return setState(s);
    }), _defineProperty(_stateChangeHandlers, "".concat(SHARED_STATE_SET, "-client-").concat(stateId), function client(s) {
      return setState(s);
    }), _stateChangeHandlers);
    var stateInitializationHandlers = (_stateInitializationH = {}, _defineProperty(_stateInitializationH, SET_STORIES, function () {
      var currentState = api.getAddonState(stateId);

      if (currentState) {
        addonStateCache[stateId] = currentState;
        api.emit("".concat(SHARED_STATE_SET, "-manager-").concat(stateId), currentState);
      } else if (addonStateCache[stateId]) {
        // this happens when HMR
        setState(addonStateCache[stateId]);
        api.emit("".concat(SHARED_STATE_SET, "-manager-").concat(stateId), addonStateCache[stateId]);
      } else if (defaultState !== undefined) {
        // if not HMR, yet the defaults are from the manager
        setState(defaultState); // initialize addonStateCache after first load, so its available for subsequent HMR

        addonStateCache[stateId] = defaultState;
        api.emit("".concat(SHARED_STATE_SET, "-manager-").concat(stateId), defaultState);
      }
    }), _defineProperty(_stateInitializationH, STORY_CHANGED, function () {
      var currentState = api.getAddonState(stateId);

      if (currentState !== undefined) {
        api.emit("".concat(SHARED_STATE_SET, "-manager-").concat(stateId), currentState);
      }
    }), _stateInitializationH);
    return Object.assign({}, stateChangeHandlers, stateInitializationHandlers);
  }, [stateId]);
  var emit = useChannel(allListeners);
  return [state, function (newStateOrMerger, options) {
    setState(newStateOrMerger, options);
    emit("".concat(SHARED_STATE_CHANGED, "-manager-").concat(stateId), newStateOrMerger);
  }];
}
export function useAddonState(addonId, defaultState) {
  return useSharedState(addonId, defaultState);
}
export function useArgs() {
  var _useStorybookApi = useStorybookApi(),
      getCurrentStoryData = _useStorybookApi.getCurrentStoryData,
      updateStoryArgs = _useStorybookApi.updateStoryArgs,
      resetStoryArgs = _useStorybookApi.resetStoryArgs;

  var data = getCurrentStoryData();
  var args = isStory(data) ? data.args : {};
  var updateArgs = useCallback(function (newArgs) {
    return updateStoryArgs(data, newArgs);
  }, [data, updateStoryArgs]);
  var resetArgs = useCallback(function (argNames) {
    return resetStoryArgs(data, argNames);
  }, [data, resetStoryArgs]);
  return [args, updateArgs, resetArgs];
}
export function useGlobals() {
  var api = useStorybookApi();
  return [api.getGlobals(), api.updateGlobals];
}
export function useGlobalTypes() {
  return useStorybookApi().getGlobalTypes();
}

function useCurrentStory() {
  var _useStorybookApi2 = useStorybookApi(),
      getCurrentStoryData = _useStorybookApi2.getCurrentStoryData;

  return getCurrentStoryData();
}

export function useArgTypes() {
  var _useCurrentStory;

  return ((_useCurrentStory = useCurrentStory()) === null || _useCurrentStory === void 0 ? void 0 : _useCurrentStory.argTypes) || {};
}