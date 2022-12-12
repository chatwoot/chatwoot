import commonjs from '@rollup/plugin-commonjs' // Convert CommonJS modules to ES6
import buble from '@rollup/plugin-buble' // Transpile/polyfill with reasonable browser support
import autoExternal from 'rollup-plugin-auto-external'
import vue from 'rollup-plugin-vue' // Handle .vue SFC files
import { terser } from 'rollup-plugin-terser'

export default {
  input: 'src/Formulate.js', // Path relative to package.json
  output: [
    {
      name: 'Formulate',
      exports: 'default',
      globals: {
        'is-plain-object': 'isPlainObject',
        'nanoid/non-secure': 'nanoid',
        'is-url': 'isUrl',
        '@braid/vue-formulate-i18n': 'VueFormulateI18n'
      },
      sourcemap: false
    }
  ],
  external: ['nanoid/non-secure'],
  plugins: [
    commonjs(),
    autoExternal(),
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
