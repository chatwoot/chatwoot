

Explanation of Build Files
---

| UMD | Size | CommonJS | Size | ES Module | Size |
| ---- | ---- | ---- | ---- | ---- | ---- |
| hotkeys.js | 8.37kb | hotkeys.common.js | 8.13kb | hotkeys.esm.js | 8.12kb |
| hotkeys.min.js | 3.62kb (gzipped: 1.73kb) | hotkeys.common.min.js | (gzipped: 1.84kb) | - | - |

- [UMD](https://github.com/umdjs/umd): UMD builds can be used directly in the browser via a `<script>` tag. 
- [CommonJS](http://wiki.commonjs.org/wiki/Modules/1.1): CommonJS builds are intended for use with older bundlers like [browserify](http://browserify.org/) or [webpack 1](https://webpack.github.io/). 
- [ES Module](http://exploringjs.com/es6/ch_modules.html): ES module builds are intended for use with modern bundlers like [webpack 2](https://webpack.js.org/) or [rollup](http://rollupjs.org/). 
