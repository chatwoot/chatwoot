"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ToolbarMenuButton = void 0;

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

var _react = _interopRequireDefault(require("react"));

var _components = require("@storybook/components");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ToolbarMenuButton = function ToolbarMenuButton(_ref) {
  var active = _ref.active,
      title = _ref.title,
      icon = _ref.icon,
      description = _ref.description,
      onClick = _ref.onClick;
  return /*#__PURE__*/_react.default.createElement(_components.IconButton, {
    active: active,
    title: description,
    onClick: onClick
  }, icon && /*#__PURE__*/_react.default.createElement(_components.Icons, {
    icon: icon
  }), title ? "\xA0".concat(title) : null);
};

exports.ToolbarMenuButton = ToolbarMenuButton;