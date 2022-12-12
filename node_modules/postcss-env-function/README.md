# PostCSS Environment Variables [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Environment Variables] lets you use `env()` variables in CSS,
following the [CSS Environment Variables] specification.

```pcss
@media (max-width: env(--branding-small)) {
  body {
    padding: env(--branding-padding);
  }
}

/* becomes */

@media (min-width: 600px) {
  body {
    padding: 20px;
  }
}

/* when the `importFrom` option is: {
  "environmentVariables": {
    "--branding-small": "600px",
    "--branding-padding": "20px"
  }
} */
```

## Usage

Add [PostCSS Environment Variables] to your project:

```bash
npm install postcss-env-function --save-dev
```

Use [PostCSS Environment Variables] to process your CSS:

```js
const postcssEnvFunction = require('postcss-env-function');

postcssEnvFunction.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssEnvFunction = require('postcss-env-function');

postcss([
  postcssEnvFunction(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Environment Variables] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### importFrom

The `importFrom` option specifies sources where Environment Variables can be
imported from, which might be JS and JSON files, functions, and directly passed
objects.

```js
postcssCustomProperties({
  importFrom: 'path/to/file.js' /* module.exports = {
      environmentVariables: {
        '--branding-padding': '20px',
        '--branding-small': '600px'
      }
    } */
});
```

```pcss
@media (max-width: env(--branding-small)) {
  body {
    padding: env(--branding-padding);
  }
}

/* becomes */

@media (min-width: 600px) {
  body {
    padding: 20px;
  }
}
```

Multiple sources can be passed into this option, and they will be parsed in the
order they are received. JavaScript files, JSON files, functions, and objects
will need to namespace Custom Properties using the `environmentVariables` or
`variables-variables` key.

```js
postcssCustomProperties({
  importFrom: [
    'path/to/file.js', // module.exports = { environmentVariables: { '--branding-padding': '20px' } }
    'and/then/this.json', // { "environment-variables": { "--branding-padding": "20px" } }
    {
      environmentVariables: { '--branding-padding': '20px' }
    },
    () => {
      const environmentVariables = { '--branding-padding': '20px' };

      return { environmentVariables };
    }
  ]
});
```

See example imports written in [JS](test/import-variables.js) and
[JSON](test/import-variables.json).

[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-env-function.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-env-function
[css-img]: https://cssdb.org/badge/environment-variables.svg
[css-url]: https://cssdb.org/#environment-variables
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-env-function.svg
[npm-url]: https://www.npmjs.com/package/postcss-env-function

[CSS Environment Variables]: https://drafts.csswg.org/css-env-1/
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Environment Variables]: https://github.com/jonathantneal/postcss-env-function
