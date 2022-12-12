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

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.inferActionsFromArgTypesRegex = exports.addActionsFromArgTypes = void 0;

require("core-js/modules/es.regexp.constructor.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.regexp.to-string.js");

require("core-js/modules/es.array.filter.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.object.entries.js");

var _index = require("../index");

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

// interface ActionsParameter {
//   disable?: boolean;
//   argTypesRegex?: RegExp;
// }
var isInInitialArgs = function isInInitialArgs(name, initialArgs) {
  return typeof initialArgs[name] === 'undefined' && !(name in initialArgs);
};
/**
 * Automatically add action args for argTypes whose name
 * matches a regex, such as `^on.*` for react-style `onClick` etc.
 */


var inferActionsFromArgTypesRegex = function inferActionsFromArgTypesRegex(context) {
  var initialArgs = context.initialArgs,
      argTypes = context.argTypes,
      actions = context.parameters.actions;

  if (!actions || actions.disable || !actions.argTypesRegex || !argTypes) {
    return {};
  }

  var argTypesRegex = new RegExp(actions.argTypesRegex);
  var argTypesMatchingRegex = Object.entries(argTypes).filter(function (_ref) {
    var _ref2 = _slicedToArray(_ref, 1),
        name = _ref2[0];

    return !!argTypesRegex.test(name);
  });
  return argTypesMatchingRegex.reduce(function (acc, _ref3) {
    var _ref4 = _slicedToArray(_ref3, 2),
        name = _ref4[0],
        argType = _ref4[1];

    if (isInInitialArgs(name, initialArgs)) {
      acc[name] = (0, _index.action)(name);
    }

    return acc;
  }, {});
};
/**
 * Add action args for list of strings.
 */


exports.inferActionsFromArgTypesRegex = inferActionsFromArgTypesRegex;

var addActionsFromArgTypes = function addActionsFromArgTypes(context) {
  var initialArgs = context.initialArgs,
      argTypes = context.argTypes,
      actions = context.parameters.actions;

  if (actions !== null && actions !== void 0 && actions.disable || !argTypes) {
    return {};
  }

  var argTypesWithAction = Object.entries(argTypes).filter(function (_ref5) {
    var _ref6 = _slicedToArray(_ref5, 2),
        name = _ref6[0],
        argType = _ref6[1];

    return !!argType.action;
  });
  return argTypesWithAction.reduce(function (acc, _ref7) {
    var _ref8 = _slicedToArray(_ref7, 2),
        name = _ref8[0],
        argType = _ref8[1];

    if (isInInitialArgs(name, initialArgs)) {
      acc[name] = (0, _index.action)(typeof argType.action === 'string' ? argType.action : name);
    }

    return acc;
  }, {});
};

exports.addActionsFromArgTypes = addActionsFromArgTypes;