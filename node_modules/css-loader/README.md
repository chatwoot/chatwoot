<div align="center">
  <img width="180" height="180" vspace="20"
    src="https://cdn.worldvectorlogo.com/logos/css-3.svg">
  <a href="https://github.com/webpack/webpack">
    <img width="200" height="200"
      src="https://webpack.js.org/assets/icon-square-big.svg">
  </a>
</div>

[![npm][npm]][npm-url]
[![node][node]][node-url]
[![deps][deps]][deps-url]
[![tests][tests]][tests-url]
[![coverage][cover]][cover-url]
[![chat][chat]][chat-url]
[![size][size]][size-url]

# css-loader

The `css-loader` interprets `@import` and `url()` like `import/require()` and will resolve them.

## Getting Started

To begin, you'll need to install `css-loader`:

```console
npm install --save-dev css-loader
```

Then add the plugin to your `webpack` config. For example:

**file.js**

```js
import css from 'file.css';
```

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },
};
```

Good loaders for requiring your assets are the [file-loader](https://github.com/webpack/file-loader) and the [url-loader](https://github.com/webpack/url-loader) which you should specify in your config (see [below](https://github.com/webpack-contrib/css-loader#assets)).

And run `webpack` via your preferred method.

### `toString`

You can also use the css-loader results directly as a string, such as in Angular's component style.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: ['to-string-loader', 'css-loader'],
      },
    ],
  },
};
```

or

```js
const css = require('./test.css').toString();

console.log(css); // {String}
```

If there are SourceMaps, they will also be included in the result string.

If, for one reason or another, you need to extract CSS as a
plain string resource (i.e. not wrapped in a JS module) you
might want to check out the [extract-loader](https://github.com/peerigon/extract-loader).
It's useful when you, for instance, need to post process the CSS as a string.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: [
          'handlebars-loader', // handlebars loader expects raw resource string
          'extract-loader',
          'css-loader',
        ],
      },
    ],
  },
};
```

## Options

|                    Name                     |            Type             | Default  | Description                                                            |
| :-----------------------------------------: | :-------------------------: | :------: | :--------------------------------------------------------------------- |
|              **[`url`](#url)**              |    `{Boolean\|Function}`    |  `true`  | Enables/Disables `url`/`image-set` functions handling                  |
|           **[`import`](#import)**           |    `{Boolean\|Function}`    |  `true`  | Enables/Disables `@import` at-rules handling                           |
|          **[`modules`](#modules)**          | `{Boolean\|String\|Object}` | `false`  | Enables/Disables CSS Modules and their configuration                   |
|        **[`sourceMap`](#sourcemap)**        |         `{Boolean}`         | `false`  | Enables/Disables generation of source maps                             |
|    **[`importLoaders`](#importloaders)**    |         `{Number}`          |   `0`    | Enables/Disables or setups number of loaders applied before CSS loader |
| **[`localsConvention`](#localsconvention)** |         `{String}`          | `'asIs'` | Style of exported classnames                                           |
|       **[`onlyLocals`](#onlylocals)**       |         `{Boolean}`         | `false`  | Export only locals                                                     |
|         **[`esModule`](#esmodule)**         |         `{Boolean}`         | `false`  | Use ES modules syntax                                                  |

### `url`

Type: `Boolean|Function`
Default: `true`

Enables/Disables `url`/`image-set` functions handling.
Control `url()` resolving. Absolute URLs and root-relative URLs are not resolving.

Examples resolutions:

```
url(image.png) => require('./image.png')
url('image.png') => require('./image.png')
url(./image.png) => require('./image.png')
url('./image.png') => require('./image.png')
url('http://dontwritehorriblecode.com/2112.png') => require('http://dontwritehorriblecode.com/2112.png')
image-set(url('image2x.png') 1x, url('image1x.png') 2x) => require('./image1x.png') and require('./image2x.png')
```

To import assets from a `node_modules` path (include `resolve.modules`) and for `alias`, prefix it with a `~`:

```
url(~module/image.png) => require('module/image.png')
url('~module/image.png') => require('module/image.png')
url(~aliasDirectory/image.png) => require('otherDirectory/image.png')
```

#### `Boolean`

Enable/disable `url()` resolving.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          url: true,
        },
      },
    ],
  },
};
```

#### `Function`

Allow to filter `url()`. All filtered `url()` will not be resolved (left in the code as they were written).

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          url: (url, resourcePath) => {
            // resourcePath - path to css file

            // Don't handle `img.png` urls
            if (url.includes('img.png')) {
              return false;
            }

            return true;
          },
        },
      },
    ],
  },
};
```

### `import`

Type: `Boolean|Function`
Default: `true`

Enables/Disables `@import` at-rules handling.
Control `@import` resolving. Absolute urls in `@import` will be moved in runtime code.

Examples resolutions:

```
@import 'style.css' => require('./style.css')
@import url(style.css) => require('./style.css')
@import url('style.css') => require('./style.css')
@import './style.css' => require('./style.css')
@import url(./style.css) => require('./style.css')
@import url('./style.css') => require('./style.css')
@import url('http://dontwritehorriblecode.com/style.css') => @import url('http://dontwritehorriblecode.com/style.css') in runtime
```

To import styles from a `node_modules` path (include `resolve.modules`) and for `alias`, prefix it with a `~`:

```
@import url(~module/style.css) => require('module/style.css')
@import url('~module/style.css') => require('module/style.css')
@import url(~aliasDirectory/style.css) => require('otherDirectory/style.css')
```

#### `Boolean`

Enable/disable `@import` resolving.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          import: true,
        },
      },
    ],
  },
};
```

#### `Function`

Allow to filter `@import`. All filtered `@import` will not be resolved (left in the code as they were written).

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          import: (parsedImport, resourcePath) => {
            // parsedImport.url - url of `@import`
            // parsedImport.media - media query of `@import`
            // resourcePath - path to css file

            // Don't handle `style.css` import
            if (parsedImport.url.includes('style.css')) {
              return false;
            }

            return true;
          },
        },
      },
    ],
  },
};
```

### `modules`

Type: `Boolean|String|Object`
Default: `false`

Enables/Disables CSS Modules and their configuration.

The `modules` option enables/disables the **[CSS Modules](https://github.com/css-modules/css-modules)** specification and setup basic behaviour.

Using `false` value increase performance because we avoid parsing **CSS Modules** features, it will be useful for developers who use vanilla css or use other technologies.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: true,
        },
      },
    ],
  },
};
```

#### `Features`

##### `Scope`

Using `local` value requires you to specify `:global` classes.
Using `global` value requires you to specify `:local` classes.
Using `pure` value requires selectors must contain at least one local class or id.

You can find more information [here](https://github.com/css-modules/css-modules).

Styles can be locally scoped to avoid globally scoping styles.

The syntax `:local(.className)` can be used to declare `className` in the local scope. The local identifiers are exported by the module.

With `:local` (without brackets) local mode can be switched on for this selector.
The `:global(.className)` notation can be used to declare an explicit global selector.
With `:global` (without brackets) global mode can be switched on for this selector.

The loader replaces local selectors with unique identifiers. The chosen unique identifiers are exported by the module.

```css
:local(.className) {
  background: red;
}
:local .className {
  color: green;
}
:local(.className .subClass) {
  color: green;
}
:local .className .subClass :global(.global-class-name) {
  color: blue;
}
```

```css
._23_aKvs-b8bW2Vg3fwHozO {
  background: red;
}
._23_aKvs-b8bW2Vg3fwHozO {
  color: green;
}
._23_aKvs-b8bW2Vg3fwHozO ._13LGdX8RMStbBE9w-t0gZ1 {
  color: green;
}
._23_aKvs-b8bW2Vg3fwHozO ._13LGdX8RMStbBE9w-t0gZ1 .global-class-name {
  color: blue;
}
```

> ℹ️ Identifiers are exported

```js
exports.locals = {
  className: '_23_aKvs-b8bW2Vg3fwHozO',
  subClass: '_13LGdX8RMStbBE9w-t0gZ1',
};
```

CamelCase is recommended for local selectors. They are easier to use within the imported JS module.

You can use `:local(#someId)`, but this is not recommended. Use classes instead of ids.

##### `Composing`

When declaring a local classname you can compose a local class from another local classname.

```css
:local(.className) {
  background: red;
  color: yellow;
}

:local(.subClass) {
  composes: className;
  background: blue;
}
```

This doesn't result in any change to the CSS itself but exports multiple classnames.

```js
exports.locals = {
  className: '_23_aKvs-b8bW2Vg3fwHozO',
  subClass: '_13LGdX8RMStbBE9w-t0gZ1 _23_aKvs-b8bW2Vg3fwHozO',
};
```

```css
._23_aKvs-b8bW2Vg3fwHozO {
  background: red;
  color: yellow;
}

._13LGdX8RMStbBE9w-t0gZ1 {
  background: blue;
}
```

##### `Importing`

To import a local classname from another module.

```css
:local(.continueButton) {
  composes: button from 'library/button.css';
  background: red;
}
```

```css
:local(.nameEdit) {
  composes: edit highlight from './edit.css';
  background: red;
}
```

To import from multiple modules use multiple `composes:` rules.

```css
:local(.className) {
  composes: edit hightlight from './edit.css';
  composes: button from 'module/button.css';
  composes: classFromThisModule;
  background: red;
}
```

##### `Values`

You can use `@value` to specific values to be reused throughout a document.

We recommend use prefix `v-` for values, `s-` for selectors and `m-` for media at-rules.

```css
@value v-primary: #BF4040;
@value s-black: black-selector;
@value m-large: (min-width: 960px);

.header {
  color: v-primary;
  padding: 0 10px;
}

.s-black {
  color: black;
}

@media m-large {
  .header {
    padding: 0 20px;
  }
}
```

#### `Boolean`

Enable **CSS Modules** features.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: true,
        },
      },
    ],
  },
};
```

#### `String`

Enable **CSS Modules** features and setup `mode`.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          // Using `local` value has same effect like using `modules: true`
          modules: 'global',
        },
      },
    ],
  },
};
```

#### `Object`

Enable **CSS Modules** features and setup options for them.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            mode: 'local',
            exportGlobals: true,
            localIdentName: '[path][name]__[local]--[hash:base64:5]',
            context: path.resolve(__dirname, 'src'),
            hashPrefix: 'my-custom-hash',
          },
        },
      },
    ],
  },
};
```

##### `auto`

Type: `Boolean|RegExp|Function`
Default: `'undefined'`

Allows auto enable css modules based on filename.

###### `Boolean`

Possible values:

- `true` - enable css modules for all files for which `/\.module\.\w+$/i.test(filename)` return true
- `false` - disable css modules

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            auto: true,
          },
        },
      },
    ],
  },
};
```

###### `RegExp`

Enable css modules for files based on the filename satisfying your regex check.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            auto: /\.custom-module\.\w+$/i,
          },
        },
      },
    ],
  },
};
```

###### `Function`

Enable css modules for files based on the filename satisfying your filter function check.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            auto: (resourcePath) => resourcePath.endsWith('.custom-module.css'),
          },
        },
      },
    ],
  },
};
```

##### `mode`

Type: `String|Function`
Default: `'local'`

Setup `mode` option. You can omit the value when you want `local` mode.

###### `String`

Possible values - `local`, `global`, and `pure`.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            mode: 'global',
          },
        },
      },
    ],
  },
};
```

###### `Function`

Allows set different values for the `mode` option based on a filename

Possible return values - `local`, `global`, and `pure`.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            // Callback must return "local", "global", or "pure" values
            mode: (resourcePath) => {
              if (/pure.css$/i.test(resourcePath)) {
                return 'pure';
              }

              if (/global.css$/i.test(resourcePath)) {
                return 'global';
              }

              return 'local';
            },
          },
        },
      },
    ],
  },
};
```

##### `exportGlobals`

Type: `Boolean`
Default: `false`

Allow `css-loader` to export names from global class or id, so you can use that as local name.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            exportGlobals: true,
          },
        },
      },
    ],
  },
};
```

##### `localIdentName`

Type: `String`
Default: `'[hash:base64]'`

You can configure the generated ident with the `localIdentName` query parameter.
See [loader-utils's documentation](https://github.com/webpack/loader-utils#interpolatename) for more information on options.

Recommendations:

- use `'[path][name]__[local]'` for development
- use `'[hash:base64]'` for production

The `[local]` placeholder contains original class.

**Note:** all reserved (`<>:"/\|?*`) and control filesystem characters (excluding characters in the `[local]` placeholder) will be converted to `-`.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            localIdentName: '[path][name]__[local]--[hash:base64:5]',
          },
        },
      },
    ],
  },
};
```

##### `context`

Type: `String`
Default: `undefined`

Allow to redefine basic loader context for local ident name.
By default we use `rootContext` of loader.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            context: path.resolve(__dirname, 'context'),
          },
        },
      },
    ],
  },
};
```

##### `hashPrefix`

Type: `String`
Default: `undefined`

Allow to add custom hash to generate more unique classes.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            hashPrefix: 'hash',
          },
        },
      },
    ],
  },
};
```

##### `getLocalIdent`

Type: `Function`
Default: `undefined`

You can also specify the absolute path to your custom `getLocalIdent` function to generate classname based on a different schema.
By default we use built-in function to generate a classname.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            getLocalIdent: (context, localIdentName, localName, options) => {
              return 'whatever_random_class_name';
            },
          },
        },
      },
    ],
  },
};
```

##### `localIdentRegExp`

Type: `String|RegExp`
Default: `undefined`

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          modules: {
            localIdentRegExp: /page-(.*)\.css/i,
          },
        },
      },
    ],
  },
};
```

### `sourceMap`

Type: `Boolean`
Default: `false`

Enables/Disables generation of source maps.

To include source maps set the `sourceMap` option.

They are not enabled by default because they expose a runtime overhead and increase in bundle size (JS source maps do not).

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          sourceMap: true,
        },
      },
    ],
  },
};
```

### `importLoaders`

Type: `Number`
Default: `0`

Enables/Disables or setups number of loaders applied before CSS loader.

The option `importLoaders` allows you to configure how many loaders before `css-loader` should be applied to `@import`ed resources.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: [
          'style-loader',
          {
            loader: 'css-loader',
            options: {
              importLoaders: 2,
              // 0 => no loaders (default);
              // 1 => postcss-loader;
              // 2 => postcss-loader, sass-loader
            },
          },
          'postcss-loader',
          'sass-loader',
        ],
      },
    ],
  },
};
```

This may change in the future when the module system (i. e. webpack) supports loader matching by origin.

### `localsConvention`

Type: `String`
Default: `'asIs'`

Style of exported classnames.

By default, the exported JSON keys mirror the class names (i.e `asIs` value).

|         Name          |    Type    | Description                                                                                      |
| :-------------------: | :--------: | :----------------------------------------------------------------------------------------------- |
|     **`'asIs'`**      | `{String}` | Class names will be exported as is.                                                              |
|   **`'camelCase'`**   | `{String}` | Class names will be camelized, the original class name will not to be removed from the locals    |
| **`'camelCaseOnly'`** | `{String}` | Class names will be camelized, the original class name will be removed from the locals           |
|    **`'dashes'`**     | `{String}` | Only dashes in class names will be camelized                                                     |
|  **`'dashesOnly'`**   | `{String}` | Dashes in class names will be camelized, the original class name will be removed from the locals |

**file.css**

```css
.class-name {
}
```

**file.js**

```js
import { className } from 'file.css';
```

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          localsConvention: 'camelCase',
        },
      },
    ],
  },
};
```

### `onlyLocals`

Type: `Boolean`
Default: `false`

Export only locals.

**Useful** when you use **css modules** for pre-rendering (for example SSR).
For pre-rendering with `mini-css-extract-plugin` you should use this option instead of `style-loader!css-loader` **in the pre-rendering bundle**.
It doesn't embed CSS but only exports the identifier mappings.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          onlyLocals: true,
        },
      },
    ],
  },
};
```

### `esModule`

Type: `Boolean`
Default: `false`

By default, `css-loader` generates JS modules that use the CommonJS modules syntax.
There are some cases in which using ES modules is beneficial, like in the case of [module concatenation](https://webpack.js.org/plugins/module-concatenation-plugin/) and [tree shaking](https://webpack.js.org/guides/tree-shaking/).

You can enable a ES module syntax using:

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        loader: 'css-loader',
        options: {
          esModule: true,
        },
      },
    ],
  },
};
```

## Examples

### Assets

The following `webpack.config.js` can load CSS files, embed small PNG/JPG/GIF/SVG images as well as fonts as [Data URLs](https://tools.ietf.org/html/rfc2397) and copy larger files to the output directory.

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: ['style-loader', 'css-loader'],
      },
      {
        test: /\.(png|jpe?g|gif|svg|eot|ttf|woff|woff2)$/i,
        loader: 'url-loader',
        options: {
          limit: 8192,
        },
      },
    ],
  },
};
```

### Extract

For production builds it's recommended to extract the CSS from your bundle being able to use parallel loading of CSS/JS resources later on.

- This can be achieved by using the [mini-css-extract-plugin](https://github.com/webpack-contrib/mini-css-extract-plugin) to extract the CSS when running in production mode.

- As an alternative, if seeking better development performance and css outputs that mimic production. [extract-css-chunks-webpack-plugin](https://github.com/faceyspacey/extract-css-chunks-webpack-plugin) offers a hot module reload friendly, extended version of mini-css-extract-plugin. HMR real CSS files in dev, works like mini-css in non-dev

### Pure CSS, CSS modules and PostCSS

When you have pure CSS (without CSS modules), CSS modules and PostCSS in your project you can use this setup:

**webpack.config.js**

```js
module.exports = {
  module: {
    rules: [
      {
        // For CSS modules
        // For pure CSS - /\.css$/i,
        // For Sass/SCSS - /\.((c|sa|sc)ss)$/i,
        // For Less - /\.((c|le)ss)$/i,
        test: /\.((c|sa|sc)ss)$/i,
        use: [
          'style-loader',
          {
            loader: 'css-loader',
            options: {
              // Run `postcss-loader` on each CSS `@import`, do not forget that `sass-loader` compile non CSS `@import`'s into a single file
              // If you need run `sass-loader` and `postcss-loader` on each CSS `@import` please set it to `2`
              importLoaders: 1,
              // Automatically enable css modules for files satisfying `/\.module\.\w+$/i` RegExp.
              modules: { auto: true },
            },
          },
          {
            loader: 'postcss-loader',
            options: { plugins: () => [postcssPresetEnv({ stage: 0 })] },
          },
          // Can be `less-loader`
          // The `test` property should be `\.less/i`
          {
            test: /\.s[ac]ss$/i,
            loader: 'sass-loader',
          },
        ],
      },
      {
        test: /\.(png|jpe?g|gif|svg|eot|ttf|woff|woff2)$/i,
        loader: 'url-loader',
        options: {
          limit: 8192,
        },
      },
    ],
  },
};
```

## Contributing

Please take a moment to read our contributing guidelines if you haven't yet done so.

[CONTRIBUTING](./.github/CONTRIBUTING.md)

## License

[MIT](./LICENSE)

[npm]: https://img.shields.io/npm/v/css-loader.svg
[npm-url]: https://npmjs.com/package/css-loader
[node]: https://img.shields.io/node/v/css-loader.svg
[node-url]: https://nodejs.org
[deps]: https://david-dm.org/webpack-contrib/css-loader.svg
[deps-url]: https://david-dm.org/webpack-contrib/css-loader
[tests]: https://github.com/webpack-contrib/css-loader/workflows/css-loader/badge.svg
[tests-url]: https://github.com/webpack-contrib/css-loader/actions
[cover]: https://codecov.io/gh/webpack-contrib/css-loader/branch/master/graph/badge.svg
[cover-url]: https://codecov.io/gh/webpack-contrib/css-loader
[chat]: https://badges.gitter.im/webpack/webpack.svg
[chat-url]: https://gitter.im/webpack/webpack
[size]: https://packagephobia.now.sh/badge?p=css-loader
[size-url]: https://packagephobia.now.sh/result?p=css-loader
