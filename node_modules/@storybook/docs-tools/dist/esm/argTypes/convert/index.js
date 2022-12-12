import { convert as tsConvert } from './typescript';
import { convert as flowConvert } from './flow';
import { convert as propTypesConvert } from './proptypes';
export var convert = function convert(docgenInfo) {
  var type = docgenInfo.type,
      tsType = docgenInfo.tsType,
      flowType = docgenInfo.flowType;
  if (type != null) return propTypesConvert(type);
  if (tsType != null) return tsConvert(tsType);
  if (flowType != null) return flowConvert(flowType);
  return null;
};