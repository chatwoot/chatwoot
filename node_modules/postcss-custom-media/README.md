# PostCSS Custom Media [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Custom Media] lets you use Custom Media Queries in CSS, following the
[CSS Media Queries] specification.

```pcss
@custom-media --small-viewport (max-width: 30em);

@media (--small-viewport) {
  /* styles for small viewport */
}

/* becomes */

@media (max-width: 30em) {
  /* styles for small viewport */
}
```

## Usage

Add [PostCSS Custom Media] to your project:

```bash
npm install postcss-custom-media --save-dev
```

Use [PostCSS Custom Media] to process your CSS:

```js
const postcssCustomMedia = require('postcss-custom-media');

postcssCustomMedia.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssCustomMedia = require('postcss-custom-media');

postcss([
  postcssCustomMedia(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Custom Media] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether custom media and atrules using custom
media should be preserved in their original form.

```pcss
@custom-media --small-viewport (max-width: 30em);

@media (--small-viewport) {
  /* styles for small viewport */
}

/* becomes */

@custom-media --small-viewport (max-width: 30em);

@media (max-width: 30em) {
  /* styles for small viewport */
}

@media (--small-viewport) {
  /* styles for small viewport */
}
```

### importFrom

The `importFrom` option specifies sources where custom media can be imported
from, which might be CSS, JS, and JSON files, functions, and directly passed
objects.

```js
postcssCustomMedia({
  importFrom: 'path/to/file.css' // => @custom-selector --small-viewport (max-width: 30em);
});
```

```pcss
@media (max-width: 30em) {
  /* styles for small viewport */
}

@media (--small-viewport) {
  /* styles for small viewport */
}
```

Multiple sources can be passed into this option, and they will be parsed in the
order they are received. JavaScript files, JSON files, functions, and objects
will need to namespace custom media using the `customMedia` or
`custom-media` key.

```js
postcssCustomMedia({
  importFrom: [
    'path/to/file.css',
    'and/then/this.js',
    'and/then/that.json',
    {
      customMedia: { '--small-viewport': '(max-width: 30em)' }
    },
    () => {
      const customMedia = { '--small-viewport': '(max-width: 30em)' };

      return { customMedia };
    }
  ]
});
```

### exportTo

The `exportTo` option specifies destinations where custom media can be exported
to, which might be CSS, JS, and JSON files, functions, and directly passed
objects.

```js
postcssCustomMedia({
  exportTo: 'path/to/file.css' // @custom-media --small-viewport (max-width: 30em);
});
```

Multiple destinations can be passed into this option, and they will be parsed
in the order they are received. JavaScript files, JSON files, and objects will
need to namespace custom media using the `customMedia` or
`custom-media` key.

```js
const cachedObject = { customMedia: {} };

postcssCustomMedia({
  exportTo: [
    'path/to/file.css',   // @custom-media --small-viewport (max-width: 30em);
    'and/then/this.js',   // module.exports = { customMedia: { '--small-viewport': '(max-width: 30em)' } }
    'and/then/this.mjs',  // export const customMedia = { '--small-viewport': '(max-width: 30em)' } }
    'and/then/that.json', // { "custom-media": { "--small-viewport": "(max-width: 30em)" } }
    cachedObject,
    customMedia => {
      customMedia    // { '--small-viewport': '(max-width: 30em)' }
    }
  ]
});
```

See example exports written to [CSS](test/export-media.css),
[JS](test/export-media.js), [MJS](test/export-media.mjs), and
[JSON](test/export-media.json).

[cli-img]: https://img.shields.io/travis/postcss/postcss-custom-media/master.svg
[cli-url]: https://travis-ci.org/postcss/postcss-custom-media
[css-img]: https://cssdb.org/badge/custom-media-queries.svg
[css-url]: https://cssdb.org/#custom-media-queries
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-custom-media.svg
[npm-url]: https://www.npmjs.com/package/postcss-custom-media

[CSS Media Queries]: https://drafts.csswg.org/mediaqueries-5/#custom-mq
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Custom Media]: https://github.com/postcss/postcss-custom-media
