# <img src="https://raw.githubusercontent.com/webpack/media/master/logo/icon-square-small.png" height="40" align="right" /> [Plug'n'Play](https://github.com/yarnpkg/rfcs/pull/101) resolver for Webpack

[![npm version](https://img.shields.io/npm/v/pnp-webpack-plugin.svg)](https://www.npmjs.com/package/pnp-webpack-plugin)
[![node version](https://img.shields.io/node/v/pnp-webpack-plugin.svg)](https://www.npmjs.com/package/pnp-webpack-plugin)

*This plugin is also available for Jest ([jest-pnp-resolver](https://github.com/arcanis/jest-pnp-resolver)), Rollup ([rollup-plugin-pnp-resolve](https://github.com/arcanis/rollup-plugin-pnp-resolve)), and TypeScript ([ts-pnp](https://github.com/arcanis/ts-pnp))*

## Installation

```
yarn add -D pnp-webpack-plugin
```

## Usage

Simply add the plugin to both the `resolver` and `resolveLoader`:

```js
const PnpWebpackPlugin = require(`pnp-webpack-plugin`);

module.exports = {
  resolve: {
    plugins: [
      PnpWebpackPlugin,
    ],
  },
  resolveLoader: {
    plugins: [
      PnpWebpackPlugin.moduleLoader(module),
    ],
  },
};
```

The `resolve` entry will take care of correctly resolving the dependencies required by your program, and the `resolveLoader` entry will help Webpack find the location of the loaders on the disk. Note that in this case, all loaders will be resolved relative to the package containing your configuration.

In case part of your configuration comes from third-party packages that use their own loaders, make sure they use `require.resolve` - this will ensure that the resolution process is portable accross environments (including when Plug'n'Play isn't enabled), and prevent it from relying on undefined behaviors:

```js
module.exports = {
  module: {
    rules: [{
      test: /\.js$/,
      loader: require.resolve('babel-loader'),
    }]
  },
};
```

## License (MIT)

> **Copyright © 2016 Maël Nison**
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
