"use strict";

require("core-js/modules/es.object.assign.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ToolbarManager = void 0;

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.array.map.js");

var _react = _interopRequireDefault(require("react"));

var _api = require("@storybook/api");

var _components = require("@storybook/components");

var _ToolbarMenuList = require("./ToolbarMenuList");

var _normalizeToolbarArgType = require("../utils/normalize-toolbar-arg-type");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _extends() { _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; }; return _extends.apply(this, arguments); }

/**
 * A smart component for handling manager-preview interactions.
 */
var ToolbarManager = function ToolbarManager() {
  var globalTypes = (0, _api.useGlobalTypes)();
  var globalIds = Object.keys(globalTypes).filter(function (id) {
    return !!globalTypes[id].toolbar;
  });

  if (!globalIds.length) {
    return null;
  }

  return /*#__PURE__*/_react.default.createElement(_react.default.Fragment, null, /*#__PURE__*/_react.default.createElement(_components.Separator, null), globalIds.map(function (id) {
    var normalizedArgType = (0, _normalizeToolbarArgType.normalizeArgType)(id, globalTypes[id]);
    return /*#__PURE__*/_react.default.createElement(_ToolbarMenuList.ToolbarMenuList, _extends({
      key: id,
      id: id
    }, normalizedArgType));
  }));
};

exports.ToolbarManager = ToolbarManager;