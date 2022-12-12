# PostCSS Lab Function [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Lab Function] lets you use `lab`, `lch`, and `gray` color functions in
CSS, following the [CSS Color] specification.

```pcss
:root {
  --firebrick: lab(40 56.6 39);
  --firebrick-a50: lch(40 68.8 34.5 / 50%);
  --gray-40: gray(40);
  --gray-40a50: gray(40 / .5);
}

/* becomes */

:root {
  --firebrick: rgb(178, 34, 34);
  --firebrick-a50: rgba(178, 34, 34, .5);
  --gray-40: rgb(94,94,94);
  --gray-40a50: rgba(94,94,94, .5);
}
```

## Usage

Add [PostCSS Lab Function] to your project:

```bash
npm install postcss-lab-function --save-dev
```

Use [PostCSS Lab Function] to process your CSS:

```js
const postcssLabFunction = require('postcss-lab-function');

postcssLabFunction.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssLabFunction = require('postcss-lab-function');

postcss([
  postcssLabFunction(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Lab Function] runs in all Node environments, with special
instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether the original functional color notation
is preserved. By default, it is not preserved.

```js
postcssLabFunction({ preserve: true })
```

```pcss
:root {
  --firebrick: lab(40 56.6 39);
  --firebrick-a50: lch(40 68.8 34.5 / 50%);
}

/* becomes */

:root {
  --firebrick: rgb(178, 34, 34);
  --firebrick: lab(40 56.6 39);
  --firebrick-a50: rgba(178, 34, 34, .5);
  --firebrick-a50: lch(40 68.8 34.5 / 50%);
}
```

[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-lab-function.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-lab-function
[css-img]: https://cssdb.org/badge/lab-function.svg
[css-url]: https://cssdb.org/#lab-function
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-lab-function.svg
[npm-url]: https://www.npmjs.com/package/postcss-lab-function

[CSS Color]: https://drafts.csswg.org/css-color/#specifying-lab-lch
[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Loader]: https://github.com/postcss/postcss-loader
[PostCSS Lab Function]: https://github.com/jonathantneal/postcss-lab-function
