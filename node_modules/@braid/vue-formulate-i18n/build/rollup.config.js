import buble from '@rollup/plugin-buble' // Transpile/polyfill with reasonable browser support
import { terser } from 'rollup-plugin-terser'

export default {
  input: 'src/locales.js', // Path relative to package.json
  output: [
    {
      name: 'VueFormulateI18n',
      exports: 'named'
    }
  ],
  plugins: [
    buble({
      objectAssign: 'Object.assign'
    }), // Transpile to ES5,
    terser()
  ]
}
