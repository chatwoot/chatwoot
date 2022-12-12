"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.Wrapper = exports.ActionLogger = void 0;

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.function.name.js");

var _react = _interopRequireWildcard(require("react"));

var _theming = require("@storybook/theming");

var _reactInspector = _interopRequireDefault(require("react-inspector"));

var _components = require("@storybook/components");

var _style = require("./style");

var _excluded = ["theme"];

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

var Wrapper = (0, _theming.styled)(function (_ref) {
  var children = _ref.children,
      className = _ref.className;
  return /*#__PURE__*/_react.default.createElement(_components.ScrollArea, {
    horizontal: true,
    vertical: true,
    className: className
  }, children);
})({
  margin: 0,
  padding: '10px 5px 20px'
});
exports.Wrapper = Wrapper;
var ThemedInspector = (0, _theming.withTheme)(function (_ref2) {
  var theme = _ref2.theme,
      props = _objectWithoutProperties(_ref2, _excluded);

  return /*#__PURE__*/_react.default.createElement(_reactInspector.default, _extends({
    theme: theme.addonActionsTheme || 'chromeLight'
  }, props));
});

var ActionLogger = function ActionLogger(_ref3) {
  var actions = _ref3.actions,
      onClear = _ref3.onClear;
  return /*#__PURE__*/_react.default.createElement(_react.Fragment, null, /*#__PURE__*/_react.default.createElement(Wrapper, {
    title: "actionslogger"
  }, actions.map(function (action) {
    return /*#__PURE__*/_react.default.createElement(_style.Action, {
      key: action.id
    }, action.count > 1 && /*#__PURE__*/_react.default.createElement(_style.Counter, null, action.count), /*#__PURE__*/_react.default.createElement(_style.InspectorContainer, null, /*#__PURE__*/_react.default.createElement(ThemedInspector, {
      sortObjectKeys: true,
      showNonenumerable: false,
      name: action.data.name,
      data: action.data.args || action.data
    })));
  })), /*#__PURE__*/_react.default.createElement(_components.ActionBar, {
    actionItems: [{
      title: 'Clear',
      onClick: onClear
    }]
  }));
};

exports.ActionLogger = ActionLogger;