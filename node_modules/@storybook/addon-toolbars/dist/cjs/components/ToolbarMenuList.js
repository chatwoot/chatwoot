"use strict";

function _typeof(obj) { "@babel/helpers - typeof"; return _typeof = "function" == typeof Symbol && "symbol" == typeof Symbol.iterator ? function (obj) { return typeof obj; } : function (obj) { return obj && "function" == typeof Symbol && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }, _typeof(obj); }

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.weak-map.js");

require("core-js/modules/es.object.get-own-property-descriptor.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.ToolbarMenuList = void 0;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.assign.js");

var _react = _interopRequireWildcard(require("react"));

var _api = require("@storybook/api");

var _components = require("@storybook/components");

var _ToolbarMenuButton = require("./ToolbarMenuButton");

var _withKeyboardCycle = require("../hoc/withKeyboardCycle");

var _getSelected = require("../utils/get-selected");

var _ToolbarMenuListItem = require("./ToolbarMenuListItem");

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function _getRequireWildcardCache(nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || _typeof(obj) !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var ToolbarMenuList = (0, _withKeyboardCycle.withKeyboardCycle)(function (_ref) {
  var id = _ref.id,
      name = _ref.name,
      description = _ref.description,
      _ref$toolbar = _ref.toolbar,
      _icon = _ref$toolbar.icon,
      items = _ref$toolbar.items,
      _title = _ref$toolbar.title,
      showName = _ref$toolbar.showName,
      preventDynamicIcon = _ref$toolbar.preventDynamicIcon,
      dynamicTitle = _ref$toolbar.dynamicTitle;

  var _useGlobals = (0, _api.useGlobals)(),
      _useGlobals2 = _slicedToArray(_useGlobals, 2),
      globals = _useGlobals2[0],
      updateGlobals = _useGlobals2[1];

  var currentValue = globals[id];
  var hasGlobalValue = !!currentValue;
  var icon = _icon;
  var title = _title;

  if (!preventDynamicIcon) {
    icon = (0, _getSelected.getSelectedIcon)({
      currentValue: currentValue,
      items: items
    }) || icon;
  } // Deprecation support for old "name of global arg used as title"


  if (showName && !title) {
    title = name;
  }

  if (dynamicTitle) {
    title = (0, _getSelected.getSelectedTitle)({
      currentValue: currentValue,
      items: items
    }) || title;
  }

  var handleItemClick = (0, _react.useCallback)(function (value) {
    updateGlobals(_defineProperty({}, id, value));
  }, [currentValue, updateGlobals]);
  return /*#__PURE__*/_react.default.createElement(_components.WithTooltip, {
    placement: "top",
    trigger: "click",
    tooltip: function tooltip(_ref2) {
      var onHide = _ref2.onHide;
      var links = items // Special case handling for various "type" variants
      .filter(function (_ref3) {
        var type = _ref3.type;
        var shouldReturn = true;

        if (type === 'reset' && !currentValue) {
          shouldReturn = false;
        }

        return shouldReturn;
      }).map(function (item) {
        var listItem = (0, _ToolbarMenuListItem.ToolbarMenuListItem)(Object.assign({}, item, {
          currentValue: currentValue,
          onClick: function onClick() {
            handleItemClick(item.value);
            onHide();
          }
        }));
        return listItem;
      });
      return /*#__PURE__*/_react.default.createElement(_components.TooltipLinkList, {
        links: links
      });
    },
    closeOnClick: true
  }, /*#__PURE__*/_react.default.createElement(_ToolbarMenuButton.ToolbarMenuButton, {
    active: hasGlobalValue,
    description: description,
    icon: icon,
    title: title
  }));
});
exports.ToolbarMenuList = ToolbarMenuList;