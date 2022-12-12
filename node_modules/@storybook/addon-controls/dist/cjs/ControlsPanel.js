"use strict";

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

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
exports.ControlsPanel = void 0;

require("core-js/modules/es.array.sort.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.values.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/es.object.assign.js");

var _react = _interopRequireDefault(require("react"));

var _api = require("@storybook/api");

var _components = require("@storybook/components");

var _constants = require("./constants");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

var ControlsPanel = function ControlsPanel() {
  var _useArgs = (0, _api.useArgs)(),
      _useArgs2 = _slicedToArray(_useArgs, 3),
      args = _useArgs2[0],
      updateArgs = _useArgs2[1],
      resetArgs = _useArgs2[2];

  var _useGlobals = (0, _api.useGlobals)(),
      _useGlobals2 = _slicedToArray(_useGlobals, 1),
      globals = _useGlobals2[0];

  var rows = (0, _api.useArgTypes)();
  var isArgsStory = (0, _api.useParameter)('__isArgsStory', false);

  var _useParameter = (0, _api.useParameter)(_constants.PARAM_KEY, {}),
      expanded = _useParameter.expanded,
      sort = _useParameter.sort,
      presetColors = _useParameter.presetColors,
      _useParameter$hideNoC = _useParameter.hideNoControlsWarning,
      hideNoControlsWarning = _useParameter$hideNoC === void 0 ? false : _useParameter$hideNoC;

  var _useStorybookState = (0, _api.useStorybookState)(),
      path = _useStorybookState.path;

  var hasControls = Object.values(rows).some(function (arg) {
    return arg === null || arg === void 0 ? void 0 : arg.control;
  });
  var showWarning = !(hasControls && isArgsStory) && !hideNoControlsWarning;
  var withPresetColors = Object.entries(rows).reduce(function (acc, _ref) {
    var _arg$control, _arg$control2;

    var _ref2 = _slicedToArray(_ref, 2),
        key = _ref2[0],
        arg = _ref2[1];

    if ((arg === null || arg === void 0 ? void 0 : (_arg$control = arg.control) === null || _arg$control === void 0 ? void 0 : _arg$control.type) !== 'color' || arg !== null && arg !== void 0 && (_arg$control2 = arg.control) !== null && _arg$control2 !== void 0 && _arg$control2.presetColors) acc[key] = arg;else acc[key] = Object.assign({}, arg, {
      control: Object.assign({}, arg.control, {
        presetColors: presetColors
      })
    });
    return acc;
  }, {});
  return /*#__PURE__*/_react.default.createElement(_react.default.Fragment, null, showWarning && /*#__PURE__*/_react.default.createElement(_components.NoControlsWarning, null), /*#__PURE__*/_react.default.createElement(_components.ArgsTable, {
    key: path,
    // resets state when switching stories
    compact: !expanded && hasControls,
    rows: withPresetColors,
    args: args,
    globals: globals,
    updateArgs: updateArgs,
    resetArgs: resetArgs,
    inAddonPanel: true,
    sort: sort
  }));
};

exports.ControlsPanel = ControlsPanel;