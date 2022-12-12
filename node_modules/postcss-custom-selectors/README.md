# PostCSS Custom Selectors [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Custom Selectors] lets you use Custom Selectors in CSS, following the
[CSS Extensions] specification.

```pcss
@custom-selector :--heading h1, h2, h3;

article :--heading + p {
  margin-top: 0;
}

/* becomes */

article h1 + p, article h2 + p, article h3 + p {}
```

## Usage

Add [PostCSS Custom Selectors] to your project:

```bash
npm install postcss-custom-selectors --save-dev
```

Use [PostCSS Custom Selectors] to process your CSS:

```js
const postcssCustomSelectors = require('postcss-custom-selectors');

postcssCustomSelectors.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssCustomSelectors = require('postcss-custom-selectors');

postcss([
  postcssCustomSelectors(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Custom Selectors] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether custom selectors and rules using
custom selectors should be preserved in their original form.

```pcss
@custom-selector :--heading h1, h2, h3;

article :--heading + p {
  margin-top: 0;
}

/* becomes */

article h1 + p, article h2 + p, article h3 + p {}

article :--heading + p {}
```

### importFrom

The `importFrom` option specifies sources where custom selectors can be
imported from, which might be CSS, JS, and JSON files, functions, and directly
passed objects.

```js
postcssCustomSelectors({
  importFrom: 'path/to/file.css' // => @custom-selector :--heading h1, h2, h3;
});
```

```pcss
article :--heading + p {
  margin-top: 0;
}

/* becomes */

article h1 + p, article h2 + p, article h3 + p {}
```

Multiple sources can be passed into this option, and they will be parsed in the
order they are received. JavaScript files, JSON files, functions, and objects
will need to namespace custom selectors using the `customProperties` or
`custom-properties` key.

```js
postcssCustomSelectors({
  importFrom: [
    'path/to/file.css',
    'and/then/this.js',
    'and/then/that.json',
    {
      customSelectors: { ':--heading': 'h1, h2, h3' }
    },
    () => {
      const customProperties = { ':--heading': 'h1, h2, h3' };

      return { customProperties };
    }
  ]
});
```

### exportTo

The `exportTo` option specifies destinations where custom selectors can be
exported to, which might be CSS, JS, and JSON files, functions, and directly
passed objects.

```js
postcssCustomSelectors({
  exportTo: 'path/to/file.css' // @custom-selector :--heading h1, h2, h3;
});
```

Multiple destinations can be passed into this option, and they will be parsed
in the order they are received. JavaScript files, JSON files, and objects will
need to namespace custom selectors using the `customProperties` or
`custom-properties` key.

```js
const cachedObject = { customSelectors: {} };

postcssCustomSelectors({
  exportTo: [
    'path/to/file.css',   // @custom-selector :--heading h1, h2, h3;
    'and/then/this.js',   // module.exports = { customSelectors: { ':--heading': 'h1, h2, h3' } }
    'and/then/this.mjs',  // export const customSelectors = { ':--heading': 'h1, h2, h3' } }
    'and/then/that.json', // { "custom-selectors": { ":--heading": "h1, h2, h3" } }
    cachedObject,
    customProperties => {
      customProperties    // { ':--heading': 'h1, h2, h3' }
    }
  ]
});
```

[cli-img]: https://img.shields.io/travis/postcss/postcss-custom-selectors.svg
[cli-url]: https://travis-ci.org/postcss/postcss-custom-selectors
[css-img]: https://cssdb.org/badge/custom-selectors.svg
[css-url]: https://cssdb.org/#custom-selectors
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-custom-selectors.svg
[npm-url]: https://www.npmjs.com/package/postcss-custom-selectors

[CSS Extensions]: https://drafts.csswg.org/css-extensions/#custom-selectors
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Custom Selectors]: https://github.com/postcss/postcss-custom-selectors
