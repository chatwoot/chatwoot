import { parse } from '@babel/parser';
export const babelParse = code => parse(code, {
  sourceType: 'module',
  // FIXME: we should get this from the project config somehow?
  plugins: ['jsx', 'typescript', ['decorators', {
    decoratorsBeforeExport: true
  }], 'classProperties'],
  tokens: true
});