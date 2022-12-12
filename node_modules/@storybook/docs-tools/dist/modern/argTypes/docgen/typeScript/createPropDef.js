import { createType } from './createType';
import { createDefaultValue } from './createDefaultValue';
export const createTsPropDef = (propName, docgenInfo) => {
  const {
    description,
    required
  } = docgenInfo;
  return {
    name: propName,
    type: createType(docgenInfo),
    required,
    description,
    defaultValue: createDefaultValue(docgenInfo)
  };
};