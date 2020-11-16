import commonjs from '@rollup/plugin-commonjs';
import { nodeResolve } from '@rollup/plugin-node-resolve';
import babel from '@rollup/plugin-babel';

export default {
  input: 'app/javascript/packs/sdk.js',
  output: [
    {
      exports: 'named',
      file: 'dist/index.js',
      format: 'cjs',
    },
  ],
  plugins: [commonjs(), nodeResolve(), babel({ babelHelpers: 'bundled' })],
};
