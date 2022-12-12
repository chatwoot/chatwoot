import { sanitize } from '@storybook/csf';
import { normalizeInputTypes } from './normalizeInputTypes';
export function normalizeComponentAnnotations(defaultExport, title = defaultExport.title, importPath) {
  const {
    id,
    argTypes
  } = defaultExport;
  return Object.assign({
    id: sanitize(id || title)
  }, defaultExport, {
    title
  }, argTypes && {
    argTypes: normalizeInputTypes(argTypes)
  }, {
    parameters: Object.assign({
      fileName: importPath
    }, defaultExport.parameters)
  });
}