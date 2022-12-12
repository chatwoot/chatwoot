import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import { createType } from './createType';
import { createDefaultValue } from './createDefaultValue';
export var createFlowPropDef = function createFlowPropDef(propName, docgenInfo) {
  var flowType = docgenInfo.flowType,
      description = docgenInfo.description,
      required = docgenInfo.required,
      defaultValue = docgenInfo.defaultValue;
  return {
    name: propName,
    type: createType(flowType),
    required: required,
    description: description,
    defaultValue: createDefaultValue(defaultValue, flowType)
  };
};