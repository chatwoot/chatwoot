# PostCSS Preset Env [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Preset Env] lets you convert modern CSS into something most browsers
can understand, determining the polyfills you need based on your targeted
browsers or runtime environments.

```bash
npm install postcss-preset-env
```

```pcss
@custom-media --viewport-medium (width <= 50rem);
@custom-selector :--heading h1, h2, h3, h4, h5, h6;

:root {
  --mainColor: #12345678;
}

body {
  color: var(--mainColor);
  font-family: system-ui;
  overflow-wrap: break-word;
}

:--heading {
  background-image: image-set(url(img/heading.png) 1x, url(img/heading@2x.png) 2x);

  @media (--viewport-medium) {
    margin-block: 0;
  }
}

a {
  color: rgb(0 0 100% / 90%);

  &:hover {
    color: rebeccapurple;
  }
}

/* becomes */

:root {
  --mainColor: rgba(18, 52, 86, 0.47059);
}

body {
  color: rgba(18, 52, 86, 0.47059);
  color: var(--mainColor);
  font-family: system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Droid Sans, Helvetica Neue;
  word-wrap: break-word;
}

h1, h2, h3, h4, h5, h6 {
  background-image: url(img/heading.png);
}

@media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
  h1, h2, h3, h4, h5, h6 {
    background-image: url(img/heading@2x.png)
  }
}

@media (max-width: 50rem) {
  h1, h2, h3, h4, h5, h6 {
    margin-top: 0;
    margin-bottom: 0;
  }
}

a {
  color: rgba(0, 0, 255, 0.9)
}

a:hover {
  color: #639;
}
```

Without any configuration options, [PostCSS Preset Env] enables **Stage 2**
features and supports **all** browsers.

[![Transform with Preset Env][readme-transform-with-preset-env-img]][readme-transform-with-preset-env-url]
[![Style with Preset Env][readme-style-with-preset-env-img]][readme-style-with-preset-env-url]

## Usage

Add [PostCSS Preset Env] to your project:

```bash
npm install postcss-preset-env --save-dev
```

Use [PostCSS Preset Env] to process your CSS:

```js
const postcssPresetEnv = require('postcss-preset-env');

postcssPresetEnv.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssPresetEnv = require('postcss-preset-env');

postcss([
  postcssPresetEnv(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Preset Env] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### stage

The `stage` option determines which CSS features to polyfill, based upon their
stability in the process of becoming implemented web standards.

```js
postcssPresetEnv({ stage: 0 })
```

The `stage` can be `0` (experimental) through `4` (stable), or `false`. Setting
`stage` to `false` will disable every polyfill. Doing this would only be useful
if you intended to exclusively use the [`features`](#features) option.

Without any configuration options, [PostCSS Preset Env] enables **Stage 2**
features.

### features

The `features` option enables or disables specific polyfills by ID. Passing
`true` to a specific feature ID will enable its polyfill, while passing `false`
will disable it.

```js
postcssPresetEnv({
  /* use stage 3 features + css nesting rules */
  stage: 3,
  features: {
    'nesting-rules': true
  }
})
```

Passing an object to a specific feature ID will both enable and configure it.

```js
postcssPresetEnv({
  /* use stage 3 features + css color-mod (warning on unresolved) */
  stage: 3,
  features: {
    'color-mod-function': { unresolved: 'warn' }
  }
})
```

Any polyfills not explicitly enabled or disabled through `features` are
determined by the [`stage`](#stage) option.

### browsers

The `browsers` option determines which polyfills are required based upon the
browsers you are supporting.

[PostCSS Preset Env] supports any standard [browserslist] configuration, which
can be a `.browserslistrc` file, a `browserslist` key in `package.json`, or
`browserslist` environment variables.

The `browsers` option should only be used when a standard browserslist
configuration is not available.

```js
postcssPresetEnv({ browsers: 'last 2 versions' })
```

If not valid browserslist configuration is specified, the
[default browserslist query](https://github.com/browserslist/browserslist#queries)
will be used.

### insertBefore / insertAfter

The `insertBefore` and `insertAfter` keys allow you to insert other PostCSS
plugins into the chain. This is only useful if you are also using sugary
PostCSS plugins that must execute before or after certain polyfills.
Both `insertBefore` and `insertAfter` support chaining one or multiple plugins.

```js
import postcssSimpleVars from 'postcss-simple-vars';

postcssPresetEnv({
  insertBefore: {
    'all-property': postcssSimpleVars
  }
})
```

### autoprefixer

[PostCSS Preset Env] includes [autoprefixer] and [`browsers`](#browsers) option
will be passed to it automatically.

Specifying the `autoprefixer` option enables passing
[additional options](https://github.com/postcss/autoprefixer#options)
into [autoprefixer].

```js
postcssPresetEnv({
  autoprefixer: { grid: true }
})
```

Passing `autoprefixer: false` disables autoprefixer.

### preserve

The `preserve` option determines whether all plugins should receive a
`preserve` option, which may preserve or remove otherwise-polyfilled CSS. By
default, this option is not configured.

```js
postcssPresetEnv({
  preserve: false // instruct all plugins to omit pre-polyfilled CSS
});
```

### importFrom

The `importFrom` option specifies sources where variables like Custom Media,
Custom Properties, Custom Selectors, and Environment Variables can be imported
from, which might be CSS, JS, and JSON files, functions, and directly passed
objects.

```js
postcssPresetEnv({
  /*
    @custom-media --small-viewport (max-width: 30em);
    @custom-selector :--heading h1, h2, h3;
    :root { --color: red; }
  */
  importFrom: 'path/to/file.css'
});
```

Multiple sources can be passed into this option, and they will be parsed in the
order they are received. JavaScript files, JSON files, functions, and objects
will use different namespaces to import different kinds of variables.

```js
postcssPresetEnv({
  importFrom: [
    /*
      @custom-media --small-viewport (max-width: 30em);
      @custom-selector :--heading h1, h2, h3;
      :root { --color: red; }
    */
    'path/to/file.css',

    /* module.exports = {
      customMedia: { '--small-viewport': '(max-width: 30em)' },
      customProperties: { '--color': 'red' },
      customSelectors: { ':--heading': 'h1, h2, h3' },
      environmentVariables: { '--branding-padding': '20px' }
    } */
    'and/then/this.js',

    /* {
      "custom-media": { "--small-viewport": "(max-width: 30em)" }
      "custom-properties": { "--color": "red" },
      "custom-selectors": { ":--heading": "h1, h2, h3" },
      "environment-variables": { "--branding-padding": "20px" }
    } */
    'and/then/that.json',

    {
      customMedia: { '--small-viewport': '(max-width: 30em)' },
      customProperties: { '--color': 'red' },
      customSelectors: { ':--heading': 'h1, h2, h3' },
      environmentVariables: { '--branding-padding': '20px' }
    },
    () => {
      const customMedia = { '--small-viewport': '(max-width: 30em)' };
      const customProperties = { '--color': 'red' };
      const customSelectors = { ':--heading': 'h1, h2, h3' };
      const environmentVariables = { '--branding-padding': '20px' };

      return { customMedia, customProperties, customSelectors, environmentVariables };
    }
  ]
});
```

### exportTo

The `exportTo` option specifies destinations where variables like Custom Media,
Custom Properties, Custom Selectors, and Environment Variables can be exported
to, which might be CSS, JS, and JSON files, functions, and directly passed
objects.

```js
postcssPresetEnv({
  /*
    @custom-media --small-viewport (max-width: 30em);
    @custom-selector :--heading h1, h2, h3;
    :root { --color: red; }
  */
  exportTo: 'path/to/file.css'
});
```

Multiple destinations can be passed into this option as well, and they will be
parsed in the order they are received. JavaScript files, JSON files, and
objects will use different namespaces to import different kinds of variables.

```js
const cachedObject = {};

postcssPresetEnv({
  exportTo: [
    /*
      @custom-media --small-viewport (max-width: 30em);
      @custom-selector :--heading h1, h2, h3;
      :root { --color: red; }
    */
    'path/to/file.css',

    /* module.exports = {
      customMedia: { '--small-viewport': '(max-width: 30em)' },
      customProperties: { '--color': 'red' },
      customSelectors: { ':--heading': 'h1, h2, h3' },
      environmentVariables: { '--branding-padding': '20px' }
    } */
    'and/then/this.js',

    /* {
      "custom-media": { "--small-viewport": "(max-width: 30em)" }
      "custom-properties": { "--color": "red" },
      "custom-selectors": { ":--heading": "h1, h2, h3" },
      "environment-variables": { "--branding-padding": "20px" }
    } */
    'and/then/that.json',

    cachedObject,
    variables => {
      if ('customProperties' in variables) {
        // do something special with customProperties
      }

      Object.assign(cachedObject, variables);
    }
  ]
});
```

[cli-img]: https://img.shields.io/travis/csstools/postcss-preset-env/master.svg
[cli-url]: https://travis-ci.org/csstools/postcss-preset-env
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-preset-env.svg
[npm-url]: https://www.npmjs.com/package/postcss-preset-env

[autoprefixer]: https://github.com/postcss/autoprefixer
[browserslist]: https://github.com/browserslist/browserslist#readme
[caniuse]: https://caniuse.com/
[cssdb]: https://cssdb.org/
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Preset Env]: https://github.com/csstools/postcss-preset-env
[readme-style-with-preset-env-img]: https://csstools.github.io/postcss-preset-env/readme-style-with-preset-env.svg
[readme-style-with-preset-env-url]: https://codepen.io/pen?template=OZRovK
[readme-transform-with-preset-env-img]: https://csstools.github.io/postcss-preset-env/readme-transform-with-preset-env.svg
[readme-transform-with-preset-env-url]: https://csstools.github.io/postcss-preset-env/
