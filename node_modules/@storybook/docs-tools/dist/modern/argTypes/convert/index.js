import { convert as tsConvert } from './typescript';
import { convert as flowConvert } from './flow';
import { convert as propTypesConvert } from './proptypes';
export const convert = docgenInfo => {
  const {
    type,
    tsType,
    flowType
  } = docgenInfo;
  if (type != null) return propTypesConvert(type);
  if (tsType != null) return tsConvert(tsType);
  if (flowType != null) return flowConvert(flowType);
  return null;
};