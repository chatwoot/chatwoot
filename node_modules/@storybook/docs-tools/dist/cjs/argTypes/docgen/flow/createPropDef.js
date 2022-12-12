"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createFlowPropDef = void 0;

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

var _createType = require("./createType");

var _createDefaultValue = require("./createDefaultValue");

var createFlowPropDef = function createFlowPropDef(propName, docgenInfo) {
  var flowType = docgenInfo.flowType,
      description = docgenInfo.description,
      required = docgenInfo.required,
      defaultValue = docgenInfo.defaultValue;
  return {
    name: propName,
    type: (0, _createType.createType)(flowType),
    required: required,
    description: description,
    defaultValue: (0, _createDefaultValue.createDefaultValue)(defaultValue, flowType)
  };
};

exports.createFlowPropDef = createFlowPropDef;