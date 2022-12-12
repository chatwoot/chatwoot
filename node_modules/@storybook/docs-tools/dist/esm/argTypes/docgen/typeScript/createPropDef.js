import "core-js/modules/es.symbol.js";
import "core-js/modules/es.symbol.description.js";
import { createType } from './createType';
import { createDefaultValue } from './createDefaultValue';
export var createTsPropDef = function createTsPropDef(propName, docgenInfo) {
  var description = docgenInfo.description,
      required = docgenInfo.required;
  return {
    name: propName,
    type: createType(docgenInfo),
    required: required,
    description: description,
    defaultValue: createDefaultValue(docgenInfo)
  };
};