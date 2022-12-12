# webpack-filter-warnings-plugin
[![npm][npm]][npm-url]
[![node][node]][node-url]
[![deps][deps]][deps-url]
[![tests][tests]][tests-url]
[![coverage][cover]][cover-url]

> Allows you to hide certain warnings from webpack compilations

## Install
```bash
npm i -D webpack-filter-warnings-plugin
```

## Usage
```js
// webpack.config.js
const FilterWarningsPlugin = require('webpack-filter-warnings-plugin');

module.exports = {
  // ... rest of webpack config
  plugins: [
    new FilterWarningsPlugin({ 
      exclude: /any-warnings-matching-this-will-be-hidden/ 
    })
  ]
}
```

### Why not use the built in stats.warningsFilter option?
Currently karma-webpack does not respect the stats.warningsFilter option. Also when excluding all warnings, webpack still says `Compiled with warnings.` when all warnings are filtere. Hopefully this plugin will no longer need to exist one day.

## Licence
MIT

[npm]: https://img.shields.io/npm/v/webpack-filter-warnings-plugin.svg
[npm-url]: https://npmjs.com/package/webpack-filter-warnings-plugin

[node]: https://img.shields.io/node/v/webpack-filter-warnings-plugin.svg
[node-url]: https://nodejs.org

[deps]: https://david-dm.org/mattlewis92/webpack-filter-warnings-plugin.svg
[deps-url]: https://david-dm.org/mattlewis92/webpack-filter-warnings-plugin

[tests]: http://img.shields.io/travis/mattlewis92/webpack-filter-warnings-plugin.svg
[tests-url]: https://travis-ci.org/mattlewis92/webpack-filter-warnings-plugin

[cover]: https://codecov.io/gh/mattlewis92/webpack-filter-warnings-plugin/branch/master/graph/badge.svg
[cover-url]: https://codecov.io/gh/mattlewis92/webpack-filter-warnings-plugin
