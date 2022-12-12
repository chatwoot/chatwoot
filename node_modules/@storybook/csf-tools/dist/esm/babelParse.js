import { parse } from '@babel/parser';
export var babelParse = function babelParse(code) {
  return parse(code, {
    sourceType: 'module',
    // FIXME: we should get this from the project config somehow?
    plugins: ['jsx', 'typescript', ['decorators', {
      decoratorsBeforeExport: true
    }], 'classProperties'],
    tokens: true
  });
};