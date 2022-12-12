# PostCSS Overflow Shorthand [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Overflow Shorthand] lets you use the `overflow` shorthand in CSS,
following the [CSS Overflow] specification.

```pcss
html {
  overflow: hidden auto;
}

/* becomes */

html {
  overflow-x: hidden;
  overflow-y: auto;
  overflow: hidden auto;
}
```

## Usage

Add [PostCSS Overflow Shorthand] to your project:

```bash
npm install postcss-overflow-shorthand --save-dev
```

Use [PostCSS Overflow Shorthand] to process your CSS:

```js
const postcssOverflowShorthand = require('postcss-overflow-shorthand');

postcssOverflowShorthand.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssOverflowShorthand = require('postcss-overflow-shorthand');

postcss([
  postcssOverflowShorthand(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Overflow Shorthand] runs in all Node environments, with special
instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether the original `overflow` declaration is
preserved. By default, it is preserved.

```js
postcssOverflowShorthand({ preserve: false })
```

```pcss
html {
  overflow: hidden auto;
}

/* becomes */

html {
  overflow-x: hidden;
  overflow-y: auto;
}
```

[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-overflow-shorthand.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-overflow-shorthand
[css-img]: https://cssdb.org/badge/overflow-property.svg
[css-url]: https://cssdb.org/#overflow-property
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-overflow-shorthand.svg
[npm-url]: https://www.npmjs.com/package/postcss-overflow-shorthand

[CSS Overflow]: https://drafts.csswg.org/css-overflow/#propdef-overflow
[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Loader]: https://github.com/postcss/postcss-loader
[PostCSS Overflow Shorthand]: https://github.com/jonathantneal/postcss-overflow-shorthand
