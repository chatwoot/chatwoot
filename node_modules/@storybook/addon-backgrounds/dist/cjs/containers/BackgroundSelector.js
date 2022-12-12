"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.BackgroundSelector = void 0;

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.object.assign.js");

var _react = _interopRequireWildcard(require("react"));

var _memoizerific = _interopRequireDefault(require("memoizerific"));

var _api = require("@storybook/api");

var _clientLogger = require("@storybook/client-logger");

var _components = require("@storybook/components");

var _constants = require("../constants");

var _ColorIcon = require("../components/ColorIcon");

var _helpers = require("../helpers");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

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

var createBackgroundSelectorItem = (0, _memoizerific.default)(1000)(function (id, name, value, hasSwatch, change, active) {
  return {
    id: id || name,
    title: name,
    onClick: function onClick() {
      change({
        selected: value,
        name: name
      });
    },
    value: value,
    right: hasSwatch ? /*#__PURE__*/_react.default.createElement(_ColorIcon.ColorIcon, {
      background: value
    }) : undefined,
    active: active
  };
});
var getDisplayedItems = (0, _memoizerific.default)(10)(function (backgrounds, selectedBackgroundColor, change) {
  var backgroundSelectorItems = backgrounds.map(function (_ref) {
    var name = _ref.name,
        value = _ref.value;
    return createBackgroundSelectorItem(null, name, value, true, change, value === selectedBackgroundColor);
  });

  if (selectedBackgroundColor !== 'transparent') {
    return [createBackgroundSelectorItem('reset', 'Clear background', 'transparent', null, change, false)].concat(_toConsumableArray(backgroundSelectorItems));
  }

  return backgroundSelectorItems;
});
var DEFAULT_BACKGROUNDS_CONFIG = {
  default: null,
  disable: true,
  values: []
};
var BackgroundSelector = /*#__PURE__*/(0, _react.memo)(function () {
  var _globals$BACKGROUNDS_;

  var backgroundsConfig = (0, _api.useParameter)(_constants.PARAM_KEY, DEFAULT_BACKGROUNDS_CONFIG);

  var _useGlobals = (0, _api.useGlobals)(),
      _useGlobals2 = _slicedToArray(_useGlobals, 2),
      globals = _useGlobals2[0],
      updateGlobals = _useGlobals2[1];

  var globalsBackgroundColor = (_globals$BACKGROUNDS_ = globals[_constants.PARAM_KEY]) === null || _globals$BACKGROUNDS_ === void 0 ? void 0 : _globals$BACKGROUNDS_.value;
  var selectedBackgroundColor = (0, _react.useMemo)(function () {
    return (0, _helpers.getBackgroundColorByName)(globalsBackgroundColor, backgroundsConfig.values, backgroundsConfig.default);
  }, [backgroundsConfig, globalsBackgroundColor]);

  if (Array.isArray(backgroundsConfig)) {
    _clientLogger.logger.warn('Addon Backgrounds api has changed in Storybook 6.0. Please refer to the migration guide: https://github.com/storybookjs/storybook/blob/next/MIGRATION.md');
  }

  var onBackgroundChange = (0, _react.useCallback)(function (value) {
    updateGlobals(_defineProperty({}, _constants.PARAM_KEY, Object.assign({}, globals[_constants.PARAM_KEY], {
      value: value
    })));
  }, [backgroundsConfig, globals, updateGlobals]);

  if (backgroundsConfig.disable) {
    return null;
  }

  return /*#__PURE__*/_react.default.createElement(_react.Fragment, null, /*#__PURE__*/_react.default.createElement(_components.WithTooltip, {
    placement: "top",
    trigger: "click",
    closeOnClick: true,
    tooltip: function tooltip(_ref2) {
      var onHide = _ref2.onHide;
      return /*#__PURE__*/_react.default.createElement(_components.TooltipLinkList, {
        links: getDisplayedItems(backgroundsConfig.values, selectedBackgroundColor, function (_ref3) {
          var selected = _ref3.selected;

          if (selectedBackgroundColor !== selected) {
            onBackgroundChange(selected);
          }

          onHide();
        })
      });
    }
  }, /*#__PURE__*/_react.default.createElement(_components.IconButton, {
    key: "background",
    title: "Change the background of the preview",
    active: selectedBackgroundColor !== 'transparent'
  }, /*#__PURE__*/_react.default.createElement(_components.Icons, {
    icon: "photo"
  }))));
});
exports.BackgroundSelector = BackgroundSelector;