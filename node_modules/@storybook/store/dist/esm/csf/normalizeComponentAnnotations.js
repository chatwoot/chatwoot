import "core-js/modules/es.object.assign.js";
import { sanitize } from '@storybook/csf';
import { normalizeInputTypes } from './normalizeInputTypes';
export function normalizeComponentAnnotations(defaultExport) {
  var title = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : defaultExport.title;
  var importPath = arguments.length > 2 ? arguments[2] : undefined;
  var id = defaultExport.id,
      argTypes = defaultExport.argTypes;
  return Object.assign({
    id: sanitize(id || title)
  }, defaultExport, {
    title: title
  }, argTypes && {
    argTypes: normalizeInputTypes(argTypes)
  }, {
    parameters: Object.assign({
      fileName: importPath
    }, defaultExport.parameters)
  });
}