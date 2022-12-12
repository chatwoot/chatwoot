"use strict";

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.symbol.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.normalizeInputTypes = exports.normalizeInputType = void 0;

require("core-js/modules/es.object.assign.js");

var _mapValues = _interopRequireDefault(require("lodash/mapValues"));

var _excluded = ["type", "control"];

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(source, excluded) { if (source == null) return {}; var target = _objectWithoutPropertiesLoose(source, excluded); var key, i; if (Object.getOwnPropertySymbols) { var sourceSymbolKeys = Object.getOwnPropertySymbols(source); for (i = 0; i < sourceSymbolKeys.length; i++) { key = sourceSymbolKeys[i]; if (excluded.indexOf(key) >= 0) continue; if (!Object.prototype.propertyIsEnumerable.call(source, key)) continue; target[key] = source[key]; } } return target; }

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

var normalizeType = function normalizeType(type) {
  return typeof type === 'string' ? {
    name: type
  } : type;
};

var normalizeControl = function normalizeControl(control) {
  return typeof control === 'string' ? {
    type: control
  } : control;
};

var normalizeInputType = function normalizeInputType(inputType, key) {
  var type = inputType.type,
      control = inputType.control,
      rest = _objectWithoutProperties(inputType, _excluded);

  var normalized = Object.assign({
    name: key
  }, rest);
  if (type) normalized.type = normalizeType(type);

  if (control) {
    normalized.control = normalizeControl(control);
  } else if (control === false) {
    normalized.control = {
      disable: true
    };
  }

  return normalized;
};

exports.normalizeInputType = normalizeInputType;

var normalizeInputTypes = function normalizeInputTypes(inputTypes) {
  return (0, _mapValues.default)(inputTypes, normalizeInputType);
};

exports.normalizeInputTypes = normalizeInputTypes;