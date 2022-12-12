import mdx from '@mdx-js/mdx';
import { createCompiler } from './sb-mdx-plugin';
export const compile = async (code, options) => mdx(code, {
  compilers: [createCompiler(options)]
});
export const compileSync = (code, options) => mdx.sync(code, {
  compilers: [createCompiler(options)]
});
export * from './sb-mdx-plugin';