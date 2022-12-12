"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createTsPropDef = void 0;

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

var _createType = require("./createType");

var _createDefaultValue = require("./createDefaultValue");

var createTsPropDef = function createTsPropDef(propName, docgenInfo) {
  var description = docgenInfo.description,
      required = docgenInfo.required;
  return {
    name: propName,
    type: (0, _createType.createType)(docgenInfo),
    required: required,
    description: description,
    defaultValue: (0, _createDefaultValue.createDefaultValue)(docgenInfo)
  };
};

exports.createTsPropDef = createTsPropDef;