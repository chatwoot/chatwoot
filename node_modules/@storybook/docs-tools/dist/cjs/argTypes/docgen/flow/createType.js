"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createType = createType;

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.array.join.js");

require("core-js/modules/es.array.map.js");

require("core-js/modules/es.regexp.exec.js");

require("core-js/modules/es.string.replace.js");

var _utils = require("../../utils");

var FlowTypesType;

(function (FlowTypesType) {
  FlowTypesType["UNION"] = "union";
  FlowTypesType["SIGNATURE"] = "signature";
})(FlowTypesType || (FlowTypesType = {}));

function generateUnionElement(_ref) {
  var name = _ref.name,
      value = _ref.value,
      elements = _ref.elements,
      raw = _ref.raw;

  if (value != null) {
    return value;
  }

  if (elements != null) {
    return elements.map(generateUnionElement).join(' | ');
  }

  if (raw != null) {
    return raw;
  }

  return name;
}

function generateUnion(_ref2) {
  var name = _ref2.name,
      raw = _ref2.raw,
      elements = _ref2.elements;

  if (elements != null) {
    return (0, _utils.createSummaryValue)(elements.map(generateUnionElement).join(' | '));
  }

  if (raw != null) {
    // Flow Unions can be defined with or without a leading `|` character, so try to remove it.
    return (0, _utils.createSummaryValue)(raw.replace(/^\|\s*/, ''));
  }

  return (0, _utils.createSummaryValue)(name);
}

function generateFuncSignature(_ref3) {
  var type = _ref3.type,
      raw = _ref3.raw;

  if (raw != null) {
    return (0, _utils.createSummaryValue)(raw);
  }

  return (0, _utils.createSummaryValue)(type);
}

function generateObjectSignature(_ref4) {
  var type = _ref4.type,
      raw = _ref4.raw;

  if (raw != null) {
    return !(0, _utils.isTooLongForTypeSummary)(raw) ? (0, _utils.createSummaryValue)(raw) : (0, _utils.createSummaryValue)(type, raw);
  }

  return (0, _utils.createSummaryValue)(type);
}

function generateSignature(flowType) {
  var type = flowType.type;
  return type === 'object' ? generateObjectSignature(flowType) : generateFuncSignature(flowType);
}

function generateDefault(_ref5) {
  var name = _ref5.name,
      raw = _ref5.raw;

  if (raw != null) {
    return !(0, _utils.isTooLongForTypeSummary)(raw) ? (0, _utils.createSummaryValue)(raw) : (0, _utils.createSummaryValue)(name, raw);
  }

  return (0, _utils.createSummaryValue)(name);
}

function createType(type) {
  // A type could be null if a defaultProp has been provided without a type definition.
  if (type == null) {
    return null;
  }

  switch (type.name) {
    case FlowTypesType.UNION:
      return generateUnion(type);

    case FlowTypesType.SIGNATURE:
      return generateSignature(type);

    default:
      return generateDefault(type);
  }
}