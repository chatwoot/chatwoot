import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs' // Convert CommonJS modules to ES6
import buble from '@rollup/plugin-buble' // Transpile/polyfill with reasonable browser support
import vue from 'rollup-plugin-vue' // Handle .vue SFC files
import internal from 'rollup-plugin-internal'
import { terser } from 'rollup-plugin-terser'

export default {
  input: 'src/Formulate.js', // Path relative to package.json
  output: {
    name: 'VueFormulate',
    exports: 'default',
    format: 'iife',
    globals: {
      'is-plain-object': 'isPlainObject',
      'nanoid/non-secure': 'nanoid',
      'is-url': 'isUrl',
      '@braid/vue-formulate-i18n': 'VueFormulateI18n'
    }
  },
  plugins: [
    resolve({
      browser: true,
      preferBuiltins: false
    }),
    commonjs(),
    internal(['is-plain-object', 'nanoid/non-secure', 'is-url', '@braid/vue-formulate-i18n']),
    vue({
      css: true, // Dynamically inject css as a <style> tag
      compileTemplate: true // Explicitly convert template to render function
    }),
    buble({
      objectAssign: 'Object.assign'
    }), // Transpile to ES5,
    terser()
  ]
}
