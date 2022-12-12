# PostCSS Color Functional Notation [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Color Functional Notation] lets you use space and slash separated
color notation in CSS, following the [CSS Color] specification.

```pcss
:root {
  --firebrick: rgb(178 34 34);
  --firebrick-a50: rgb(70% 13.5% 13.5% / 50%);
  --firebrick-hsl: hsla(0 68% 42%);
  --firebrick-hsl-a50: hsl(0 68% 42% / 50%);
}

/* becomes */

:root {
  --firebrick: rgb(178, 34, 34);
  --firebrick-a50: rgba(178, 34, 34, .5);
  --firebrick-hsl: hsl(0, 68%, 42%);
  --firebrick-hsl-a50: hsla(0, 68%, 42%, .5);
}
```

## Usage

Add [PostCSS Color Functional Notation] to your project:

```bash
npm install postcss-color-functional-notation --save-dev
```

Use [PostCSS Color Functional Notation] to process your CSS:

```js
const postcssColorFunctionalNotation = require('postcss-color-functional-notation');

postcssColorFunctionalNotation.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssColorFunctionalNotation = require('postcss-color-functional-notation');

postcss([
  postcssColorFunctionalNotation(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Color Functional Notation] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether the original functional color notation
is preserved. By default, it is not preserved.

```js
postcssImageSetFunction({ preserve: true })
```

```pcss
:root {
  --firebrick: rgb(178 34 34);
  --firebrick-a50: rgb(70% 13.5% 13.5% / 50%);
  --firebrick-hsl: hsla(0 68% 42%);
  --firebrick-hsl-a50: hsl(0 68% 42% / 50%);
}

/* becomes */

:root {
  --firebrick: rgb(178, 34, 34);
  --firebrick: rgb(178 34 34);
  --firebrick-a50: rgba(178, 34, 34, .5);
  --firebrick-a50: rgb(70% 13.5% 13.5% / 50%);
  --firebrick-hsl: hsl(0, 68%, 42%);
  --firebrick-hsl: hsla(0 68% 42%);
  --firebrick-hsl-a50: hsla(0, 68%, 42%, .5);
  --firebrick-hsl-a50: hsl(0 68% 42% / 50%);
}
```

[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-color-functional-notation.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-color-functional-notation
[css-img]: https://cssdb.org/badge/color-functional-notation.svg
[css-url]: https://cssdb.org/#color-functional-notation
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-color-functional-notation.svg
[npm-url]: https://www.npmjs.com/package/postcss-color-functional-notation

[CSS Color]: https://drafts.csswg.org/css-color/#ref-for-funcdef-rgb%E2%91%A1%E2%91%A0
[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Loader]: https://github.com/postcss/postcss-loader
[PostCSS Color Functional Notation]: https://github.com/jonathantneal/postcss-color-functional-notation
