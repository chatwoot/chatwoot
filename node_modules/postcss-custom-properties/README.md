# PostCSS Custom Properties [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Custom Properties] lets you use Custom Properties in CSS, following
the [CSS Custom Properties] specification.

```pcss
:root {
  --color: red;
}

h1 {
  color: var(--color);
}

/* becomes */

:root {
  --color: red;
}

h1 {
  color: red;
  color: var(--color);
}
```

## Usage

Add [PostCSS Custom Properties] to your project:

```bash
npm install postcss-custom-properties --save-dev
```

Use [PostCSS Custom Properties] to process your CSS:

```js
const postcssCustomProperties = require('postcss-custom-properties');

postcssCustomProperties.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssCustomProperties = require('postcss-custom-properties');

postcss([
  postcssCustomProperties(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Custom Properties] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether Custom Properties and properties using
custom properties should be preserved in their original form. By default, both
of these are preserved.

```js
postcssCustomProperties({
  preserve: false
});
```

```pcss
:root {
  --color: red;
}

h1 {
  color: var(--color);
}

/* becomes */

h1 {
  color: red;
}
```

### importFrom

The `importFrom` option specifies sources where Custom Properties can be imported
from, which might be CSS, JS, and JSON files, functions, and directly passed
objects.

```js
postcssCustomProperties({
  importFrom: 'path/to/file.css' // => :root { --color: red }
});
```

```pcss
h1 {
  color: var(--color);
}

/* becomes */

h1 {
  color: red;
}
```

Multiple sources can be passed into this option, and they will be parsed in the
order they are received. JavaScript files, JSON files, functions, and objects
will need to namespace Custom Properties using the `customProperties` or
`custom-properties` key.

```js
postcssCustomProperties({
  importFrom: [
    'path/to/file.css',   // :root { --color: red; }
    'and/then/this.js',   // module.exports = { customProperties: { '--color': 'red' } }
    'and/then/that.json', // { "custom-properties": { "--color": "red" } }
    {
      customProperties: { '--color': 'red' }
    },
    () => {
      const customProperties = { '--color': 'red' };

      return { customProperties };
    }
  ]
});
```

See example imports written in [CSS](test/import-properties.css),
[JS](test/import-properties.js), and [JSON](test/import-properties.json).

### exportTo

The `exportTo` option specifies destinations where Custom Properties can be exported
to, which might be CSS, JS, and JSON files, functions, and directly passed
objects.

```js
postcssCustomProperties({
  exportTo: 'path/to/file.css' // :root { --color: red; }
});
```

Multiple destinations can be passed into this option, and they will be parsed
in the order they are received. JavaScript files, JSON files, and objects will
need to namespace Custom Properties using the `customProperties` or
`custom-properties` key.

```js
const cachedObject = { customProperties: {} };

postcssCustomProperties({
  exportTo: [
    'path/to/file.css',   // :root { --color: red; }
    'and/then/this.js',   // module.exports = { customProperties: { '--color': 'red' } }
    'and/then/this.mjs',  // export const customProperties = { '--color': 'red' } }
    'and/then/that.json', // { "custom-properties": { "--color": "red" } }
    cachedObject,
    customProperties => {
      customProperties    // { '--color': 'red' }
    }
  ]
});
```

See example exports written to [CSS](test/export-properties.css),
[JS](test/export-properties.js), [MJS](test/export-properties.mjs), and
[JSON](test/export-properties.json).

[cli-img]: https://img.shields.io/travis/postcss/postcss-custom-properties/master.svg
[cli-url]: https://travis-ci.org/postcss/postcss-custom-properties
[css-img]: https://cssdb.org/badge/custom-properties.svg
[css-url]: https://cssdb.org/#custom-properties
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-custom-properties.svg
[npm-url]: https://www.npmjs.com/package/postcss-custom-properties

[CSS Custom Properties]: https://www.w3.org/TR/css-variables-1/
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Custom Properties]: https://github.com/postcss/postcss-custom-properties
