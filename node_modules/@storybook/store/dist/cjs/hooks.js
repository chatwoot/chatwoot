"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
Object.defineProperty(exports, "HooksContext", {
  enumerable: true,
  get: function get() {
    return _addons.HooksContext;
  }
});
Object.defineProperty(exports, "applyHooks", {
  enumerable: true,
  get: function get() {
    return _addons.applyHooks;
  }
});
exports.useAddonState = useAddonState;
Object.defineProperty(exports, "useArgs", {
  enumerable: true,
  get: function get() {
    return _addons.useArgs;
  }
});
Object.defineProperty(exports, "useCallback", {
  enumerable: true,
  get: function get() {
    return _addons.useCallback;
  }
});
Object.defineProperty(exports, "useChannel", {
  enumerable: true,
  get: function get() {
    return _addons.useChannel;
  }
});
Object.defineProperty(exports, "useEffect", {
  enumerable: true,
  get: function get() {
    return _addons.useEffect;
  }
});
Object.defineProperty(exports, "useGlobals", {
  enumerable: true,
  get: function get() {
    return _addons.useGlobals;
  }
});
Object.defineProperty(exports, "useMemo", {
  enumerable: true,
  get: function get() {
    return _addons.useMemo;
  }
});
Object.defineProperty(exports, "useParameter", {
  enumerable: true,
  get: function get() {
    return _addons.useParameter;
  }
});
Object.defineProperty(exports, "useReducer", {
  enumerable: true,
  get: function get() {
    return _addons.useReducer;
  }
});
Object.defineProperty(exports, "useRef", {
  enumerable: true,
  get: function get() {
    return _addons.useRef;
  }
});
exports.useSharedState = useSharedState;
Object.defineProperty(exports, "useState", {
  enumerable: true,
  get: function get() {
    return _addons.useState;
  }
});
Object.defineProperty(exports, "useStoryContext", {
  enumerable: true,
  get: function get() {
    return _addons.useStoryContext;
  }
});

require("core-js/modules/es.array.concat.js");

var _coreEvents = require("@storybook/core-events");

var _addons = require("@storybook/addons");

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function useSharedState(sharedId, defaultState) {
  var channel = _addons.addons.getChannel();

  var _ref = channel.last("".concat(_coreEvents.SHARED_STATE_CHANGED, "-manager-").concat(sharedId)) || channel.last("".concat(_coreEvents.SHARED_STATE_SET, "-manager-").concat(sharedId)) || [],
      _ref2 = _slicedToArray(_ref, 1),
      lastValue = _ref2[0];

  var _useState = (0, _addons.useState)(lastValue || defaultState),
      _useState2 = _slicedToArray(_useState, 2),
      state = _useState2[0],
      setState = _useState2[1];

  var allListeners = (0, _addons.useMemo)(function () {
    var _ref3;

    return _ref3 = {}, _defineProperty(_ref3, "".concat(_coreEvents.SHARED_STATE_CHANGED, "-manager-").concat(sharedId), function manager(s) {
      return setState(s);
    }), _defineProperty(_ref3, "".concat(_coreEvents.SHARED_STATE_SET, "-manager-").concat(sharedId), function manager(s) {
      return setState(s);
    }), _ref3;
  }, [sharedId]);
  var emit = (0, _addons.useChannel)(allListeners, [sharedId]);
  (0, _addons.useEffect)(function () {
    // init
    if (defaultState !== undefined && !lastValue) {
      emit("".concat(_coreEvents.SHARED_STATE_SET, "-client-").concat(sharedId), defaultState);
    }
  }, [sharedId]);
  return [state, function (s) {
    setState(s);
    emit("".concat(_coreEvents.SHARED_STATE_CHANGED, "-client-").concat(sharedId), s);
  }];
}

function useAddonState(addonId, defaultState) {
  return useSharedState(addonId, defaultState);
}