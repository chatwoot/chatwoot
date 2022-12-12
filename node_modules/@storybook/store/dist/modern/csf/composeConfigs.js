import "core-js/modules/es.array.reduce.js";
import { combineParameters } from '../parameters';
export function getField(moduleExportList, field) {
  return moduleExportList.map(xs => xs[field]).filter(Boolean);
}
export function getArrayField(moduleExportList, field) {
  return getField(moduleExportList, field).reduce((a, b) => [...a, ...b], []);
}
export function getObjectField(moduleExportList, field) {
  return Object.assign({}, ...getField(moduleExportList, field));
}
export function getSingletonField(moduleExportList, field) {
  return getField(moduleExportList, field).pop();
}
export function composeConfigs(moduleExportList) {
  const allArgTypeEnhancers = getArrayField(moduleExportList, 'argTypesEnhancers');
  return {
    parameters: combineParameters(...getField(moduleExportList, 'parameters')),
    decorators: getArrayField(moduleExportList, 'decorators'),
    args: getObjectField(moduleExportList, 'args'),
    argsEnhancers: getArrayField(moduleExportList, 'argsEnhancers'),
    argTypes: getObjectField(moduleExportList, 'argTypes'),
    argTypesEnhancers: [...allArgTypeEnhancers.filter(e => !e.secondPass), ...allArgTypeEnhancers.filter(e => e.secondPass)],
    globals: getObjectField(moduleExportList, 'globals'),
    globalTypes: getObjectField(moduleExportList, 'globalTypes'),
    loaders: getArrayField(moduleExportList, 'loaders'),
    render: getSingletonField(moduleExportList, 'render'),
    renderToDOM: getSingletonField(moduleExportList, 'renderToDOM'),
    applyDecorators: getSingletonField(moduleExportList, 'applyDecorators')
  };
}