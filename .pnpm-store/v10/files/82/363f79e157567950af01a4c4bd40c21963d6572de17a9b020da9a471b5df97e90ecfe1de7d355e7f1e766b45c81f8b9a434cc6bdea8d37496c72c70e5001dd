import json from 'rollup-plugin-json'
import { terser } from 'rollup-plugin-terser'

export default [
  {
    input: 'min/index.js',
    plugins: [
      json(),
      terser()
    ],
    output: {
      format: 'umd',
      name: 'libphonenumber',
      file: 'bundle/libphonenumber-min.js',
      sourcemap: true
    }
  },
  {
    input: 'mobile/index.js',
    plugins: [
      json(),
      terser()
    ],
    output: {
      format: 'umd',
      name: 'libphonenumber',
      file: 'bundle/libphonenumber-mobile.js',
      sourcemap: true
    }
  },
  {
    input: 'max/index.js',
    plugins: [
      json(),
      terser()
    ],
    output: {
      format: 'umd',
      name: 'libphonenumber',
      file: 'bundle/libphonenumber-max.js',
      sourcemap: true
    }
  },
  {
    input: 'index.es6',
    plugins: [
      json(),
      terser()
    ],
    output: {
      format: 'umd',
      name: 'libphonenumber',
      file: 'bundle/libphonenumber-js.min.js',
      sourcemap: true
    }
  }
]