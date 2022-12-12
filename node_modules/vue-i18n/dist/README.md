## Explanation of Different Builds

- UMD: `vue-i18n.js`
- CommonJS: `vue-i18n.common.js`
- ES Module for bundlers: `vue-i18n.esm.js`
- ES Module for browsers: `vue-i18n.esm.browser.js`

### Terms

- **[UMD](https://github.com/umdjs/umd)**: UMD builds can be used directly in the browser via a `<script>` tag. The default file from Unpkg CDN at [https://unpkg.com/vue-i18n](https://unpkg.com/vue-i18n) is the UMD build (`vue-i18n.js`).

- **[CommonJS](http://wiki.commonjs.org/wiki/Modules/1.1)**: CommonJS builds are intended for use with older bundlers like [browserify](http://browserify.org/) or [webpack 1](https://webpack.github.io). The default file for these bundlers (`pkg.main`) is the Runtime only CommonJS build (`vue-i18n.common.js`).

- **[ES Module](http://exploringjs.com/es6/ch_modules.html)**: starting in 8.11 VueI18n provides two ES Modules (ESM) builds:
  - ESM for bundlers: intended for use with modern bundlers like [webpack 2](https://webpack.js.org) or [Rollup](https://rollupjs.org/). ESM format is designed to be statically analyzable so the bundlers can take advantage of that to perform "tree-shaking" and eliminate unused code from your final bundle. The default file for these bundlers (`pkg.module`) is the Runtime only ES Module build (`vue-i18n.esm.js`).
  - ESM for browsers (8.11+ only, `vue-i18n.esm.browser.js`): intended for direct imports in modern browsers via `<script type="module">`.
