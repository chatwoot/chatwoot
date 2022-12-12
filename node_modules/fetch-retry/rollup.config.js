import commonjs from '@rollup/plugin-commonjs';
import pkg from './package.json';

export default {
  input: 'index.js',
  output: {
    name: 'fetchRetry',
    file: pkg.browser,
    format: 'umd'
  },
  plugins: [commonjs()]
};
