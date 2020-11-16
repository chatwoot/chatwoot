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
  plugins: [babel({ babelHelpers: 'bundled' })],
};
