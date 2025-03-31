import path from 'path'
import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import { babel, getBabelOutputPlugin } from '@rollup/plugin-babel';
import { terser } from 'rollup-plugin-terser'
import postcss from 'rollup-plugin-postcss'
import vue from 'rollup-plugin-vue'
import packageInfo from './package.json'
import typescript from 'rollup-plugin-typescript2';
import pluginCSS from 'rollup-plugin-css-only';


function baseConfig(css, ssr, umd, min) {
  let res = {
    input: 'src/FileUpload.vue',
    output: {
      format: umd ? 'umd' : 'esm',
      // format: 'iife',
      sourcemap: true,
      banner: umd ? `/*!\n Name: ${ packageInfo.name } \nComponent URI: ${ packageInfo.homepage } \nVersion: ${ packageInfo.version } \nAuthor: ${ packageInfo.author } \nLicense: ${ packageInfo.license } \nDescription: ${ packageInfo.description } \n */` : '',
      globals: {
        vue: 'Vue',
      },
      name: "VueUploadComponent",
    },
    external: ['vue'],
    plugins: [
      resolve({
        jsnext: true,
        main: true,
        browser: true,
      }),
      css && pluginCSS(),
      vue({
        preprocessStyles: true,
        css: css,
        target: ssr ? 'node' : 'browser',
      }),
      typescript({
        declaration: true,
        check: true,
        tsconfig: path.resolve(__dirname, 'tsconfig.json'),
        cacheRoot: path.resolve(__dirname, 'node_modules/.rts2_cache'),
      }),
      postcss(),
      ssr || umd ? false : babel({
        exclude: 'node_modules/**'
      }),
      ssr || umd ? false : getBabelOutputPlugin({
        "presets": [
          ["@babel/preset-env", { "modules": false, "useBuiltIns": false, "targets": "ie >= 9", "exclude": ["transform-async-to-generator", "proposal-async-generator-functions", "transform-regenerator"] }]
        ],
        "sourceType": "unambiguous",
        "plugins": [
          ["@babel/plugin-transform-runtime", { "helpers": false, "corejs": false, "regenerator": false, "useESModules": false, "absoluteRuntime": false }]
        ],
      }),
      min ? terser({
        output: {
          comments: /^!/,
        }
      }) : false,
      commonjs({
        extensions: [
          '.js',
          '.ts',
          '.vue'
        ],
      }),
    ],
  }

  return res
}

let config = baseConfig(false, false)
config.output.file = 'dist/vue-upload-component.js'

let configPart = baseConfig(true, false)
configPart.output.file = 'dist/vue-upload-component.part.js'

let configSSR = baseConfig(false, true, true)
configSSR.output.file = 'dist/vue-upload-component.ssr.js'

let configUmd = baseConfig(false, false, true)
configUmd.input = config.output.file
configUmd.output.file = config.output.file

let configPartUmd = baseConfig(false, false, true)
configPartUmd.input = configPart.output.file
configPartUmd.output.file = configPart.output.file


let configMin = baseConfig(false, false, true, true)
configMin.input = config.output.file
configMin.output.file = 'dist/vue-upload-component.min.js'









let configEsm = baseConfig(false, false, false)
configEsm.output.file = 'dist/vue-upload-component.esm.js'

let configEsmPart = baseConfig(true, false, false)
configEsmPart.output.file = 'dist/vue-upload-component.esm.part.js'

let configEsmSSR = baseConfig(false, true, false)
configEsmSSR.output.file = 'dist/vue-upload-component.esm.ssr.js'

let configEsmUmd = baseConfig(false, false, false)
configEsmUmd.input = configEsm.output.file
configEsmUmd.output.file = configEsm.output.file

let configEsmPartUmd = baseConfig(false, false, false)
configEsmPartUmd.input = configEsmPart.output.file
configEsmPartUmd.output.file = configEsmPart.output.file


let configEsmMin = baseConfig(false, false, false, true)
configEsmMin.input = configEsm.output.file
configEsmMin.output.file = 'dist/vue-upload-component.esm.min.js'



module.exports = [
  config,
  configPart,
  configSSR,
  configUmd,
  configPartUmd,
  configMin,

  configEsm,
  configEsmPart,
  configEsmSSR,
  configEsmUmd,
  configEsmPartUmd,
  configEsmMin,
]