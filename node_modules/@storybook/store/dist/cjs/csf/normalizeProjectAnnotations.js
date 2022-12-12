"use strict";

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeProjectAnnotations = normalizeProjectAnnotations;

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.array.concat.js");

var _inferArgTypes = require("../inferArgTypes");

var _inferControls = require("../inferControls");

var _normalizeInputTypes = require("./normalizeInputTypes");

var _excluded = ["argTypes", "globalTypes", "argTypesEnhancers"];

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

function normalizeProjectAnnotations(_ref) {
  var argTypes = _ref.argTypes,
      globalTypes = _ref.globalTypes,
      argTypesEnhancers = _ref.argTypesEnhancers,
      annotations = _objectWithoutProperties(_ref, _excluded);

  return Object.assign({}, argTypes && {
    argTypes: (0, _normalizeInputTypes.normalizeInputTypes)(argTypes)
  }, globalTypes && {
    globalTypes: (0, _normalizeInputTypes.normalizeInputTypes)(globalTypes)
  }, {
    argTypesEnhancers: [].concat(_toConsumableArray(argTypesEnhancers || []), [_inferArgTypes.inferArgTypes, // inferControls technically should only run if the user is using the controls addon,
    // and so should be added by a preset there. However, as it seems some code relies on controls
    // annotations (in particular the angular implementation's `cleanArgsDecorator`), for backwards
    // compatibility reasons, we will leave this in the store until 7.0
    _inferControls.inferControls])
  }, annotations);
}