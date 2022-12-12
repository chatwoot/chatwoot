"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ViewportTool = void 0;

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.string.bold.js");

require("core-js/modules/es.array.find.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

var _react = _interopRequireWildcard(require("react"));

var _memoizerific = _interopRequireDefault(require("memoizerific"));

var _theming = require("@storybook/theming");

var _components = require("@storybook/components");

var _api = require("@storybook/api");

var _shortcuts = require("./shortcuts");

var _constants = require("./constants");

var _defaults = require("./defaults");

var _excluded = ["name"],
    _excluded2 = ["width", "height"];

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

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

var toList = (0, _memoizerific.default)(50)(function (items) {
  return [].concat(baseViewports, _toConsumableArray(Object.entries(items).map(function (_ref2) {
    var _ref3 = _slicedToArray(_ref2, 2),
        id = _ref3[0],
        _ref = _ref3[1];

    var name = _ref.name,
        rest = _objectWithoutProperties(_ref, _excluded);

    return Object.assign({}, rest, {
      id: id,
      title: name
    });
  })));
});
var responsiveViewport = {
  id: 'reset',
  title: 'Reset viewport',
  styles: null,
  type: 'other'
};
var baseViewports = [responsiveViewport];
var toLinks = (0, _memoizerific.default)(50)(function (list, active, set, state, close) {
  return list.map(function (i) {
    switch (i.id) {
      case responsiveViewport.id:
        {
          if (active.id === i.id) {
            return null;
          }
        }

      default:
        {
          return Object.assign({}, i, {
            onClick: function onClick() {
              set(Object.assign({}, state, {
                selected: i.id
              }));
              close();
            }
          });
        }
    }
  }).filter(Boolean);
});
var iframeId = 'storybook-preview-iframe';
var wrapperId = 'storybook-preview-wrapper';

var flip = function flip(_ref4) {
  var width = _ref4.width,
      height = _ref4.height,
      styles = _objectWithoutProperties(_ref4, _excluded2);

  return Object.assign({}, styles, {
    height: width,
    width: height
  });
};

var ActiveViewportSize = _theming.styled.div(function () {
  return {
    display: 'inline-flex'
  };
});

var ActiveViewportLabel = _theming.styled.div(function (_ref5) {
  var theme = _ref5.theme;
  return {
    display: 'inline-block',
    textDecoration: 'none',
    padding: 10,
    fontWeight: theme.typography.weight.bold,
    fontSize: theme.typography.size.s2 - 1,
    lineHeight: '1',
    height: 40,
    border: 'none',
    borderTop: '3px solid transparent',
    borderBottom: '3px solid transparent',
    background: 'transparent'
  };
});

var IconButtonWithLabel = (0, _theming.styled)(_components.IconButton)(function () {
  return {
    display: 'inline-flex',
    alignItems: 'center'
  };
});

var IconButtonLabel = _theming.styled.div(function (_ref6) {
  var theme = _ref6.theme;
  return {
    fontSize: theme.typography.size.s2 - 1,
    marginLeft: 10
  };
});

var getStyles = function getStyles(prevStyles, styles, isRotated) {
  if (styles === null) {
    return null;
  }

  var result = typeof styles === 'function' ? styles(prevStyles) : styles;
  return isRotated ? flip(result) : result;
};

var ViewportTool = /*#__PURE__*/(0, _react.memo)((0, _theming.withTheme)(function (_ref7) {
  var _ref9;

  var theme = _ref7.theme;

  var _useParameter = (0, _api.useParameter)(_constants.PARAM_KEY, {}),
      _useParameter$viewpor = _useParameter.viewports,
      viewports = _useParameter$viewpor === void 0 ? _defaults.MINIMAL_VIEWPORTS : _useParameter$viewpor,
      _useParameter$default = _useParameter.defaultViewport,
      defaultViewport = _useParameter$default === void 0 ? responsiveViewport.id : _useParameter$default,
      disable = _useParameter.disable;

  var _useAddonState = (0, _api.useAddonState)(_constants.ADDON_ID, {
    selected: defaultViewport,
    isRotated: false
  }),
      _useAddonState2 = _slicedToArray(_useAddonState, 2),
      state = _useAddonState2[0],
      setState = _useAddonState2[1];

  var list = toList(viewports);
  var api = (0, _api.useStorybookApi)();

  if (!list.find(function (i) {
    return i.id === defaultViewport;
  })) {
    // eslint-disable-next-line no-console
    console.warn("Cannot find \"defaultViewport\" of \"".concat(defaultViewport, "\" in addon-viewport configs, please check the \"viewports\" setting in the configuration."));
  }

  (0, _react.useEffect)(function () {
    (0, _shortcuts.registerShortcuts)(api, setState, Object.keys(viewports));
  }, [viewports]);
  (0, _react.useEffect)(function () {
    setState({
      selected: defaultViewport || (viewports[state.selected] ? state.selected : responsiveViewport.id),
      isRotated: state.isRotated
    });
  }, [defaultViewport]);
  var selected = state.selected,
      isRotated = state.isRotated;
  var item = list.find(function (i) {
    return i.id === selected;
  }) || list.find(function (i) {
    return i.id === defaultViewport;
  }) || list.find(function (i) {
    return i.default;
  }) || responsiveViewport;
  var ref = (0, _react.useRef)();
  var styles = getStyles(ref.current, item.styles, isRotated);
  (0, _react.useEffect)(function () {
    ref.current = styles;
  }, [item]);

  if (disable || Object.entries(viewports).length === 0) {
    return null;
  }

  return /*#__PURE__*/_react.default.createElement(_react.Fragment, null, /*#__PURE__*/_react.default.createElement(_components.WithTooltip, {
    placement: "top",
    trigger: "click",
    tooltip: function tooltip(_ref8) {
      var onHide = _ref8.onHide;
      return /*#__PURE__*/_react.default.createElement(_components.TooltipLinkList, {
        links: toLinks(list, item, setState, state, onHide)
      });
    },
    closeOnClick: true
  }, /*#__PURE__*/_react.default.createElement(IconButtonWithLabel, {
    key: "viewport",
    title: "Change the size of the preview",
    active: !!styles,
    onDoubleClick: function onDoubleClick() {
      setState(Object.assign({}, state, {
        selected: responsiveViewport.id
      }));
    }
  }, /*#__PURE__*/_react.default.createElement(_components.Icons, {
    icon: "grow"
  }), styles ? /*#__PURE__*/_react.default.createElement(IconButtonLabel, null, isRotated ? "".concat(item.title, " (L)") : "".concat(item.title, " (P)")) : null)), styles ? /*#__PURE__*/_react.default.createElement(ActiveViewportSize, null, /*#__PURE__*/_react.default.createElement(_theming.Global, {
    styles: (_ref9 = {}, _defineProperty(_ref9, "#".concat(iframeId), Object.assign({
      margin: "auto",
      transition: 'width .3s, height .3s',
      position: 'relative',
      border: "1px solid black",
      boxShadow: '0 0 100px 100vw rgba(0,0,0,0.5)'
    }, styles)), _defineProperty(_ref9, "#".concat(wrapperId), {
      padding: theme.layoutMargin,
      alignContent: 'center',
      alignItems: 'center',
      justifyContent: 'center',
      justifyItems: 'center',
      overflow: 'auto',
      display: 'grid',
      gridTemplateColumns: '100%',
      gridTemplateRows: '100%'
    }), _ref9)
  }), /*#__PURE__*/_react.default.createElement(ActiveViewportLabel, {
    title: "Viewport width"
  }, styles.width.replace('px', '')), /*#__PURE__*/_react.default.createElement(_components.IconButton, {
    key: "viewport-rotate",
    title: "Rotate viewport",
    onClick: function onClick() {
      setState(Object.assign({}, state, {
        isRotated: !isRotated
      }));
    }
  }, /*#__PURE__*/_react.default.createElement(_components.Icons, {
    icon: "transfer"
  })), /*#__PURE__*/_react.default.createElement(ActiveViewportLabel, {
    title: "Viewport height"
  }, styles.height.replace('px', ''))) : null);
}));
exports.ViewportTool = ViewportTool;