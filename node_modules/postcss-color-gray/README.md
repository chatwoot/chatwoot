# PostCSS Gray [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Gray] lets you use the `gray()` color function in CSS, following the
[CSSWG Specification].

```pcss
body {
  background-color: gray(100);
  color: gray(0 / 90%);
}

/* becomes */

body {
  background-color: rgb(255,255,255);
  color: rgba(0,0,0,.9);
}
```

## Usage

Add [PostCSS Gray] to your project:

```bash
npm install postcss-color-gray --save-dev
```

Use [PostCSS Gray] to process your CSS:

```js
import postcssGray from 'postcss-color-gray';

postcssGray.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
import postcss from 'postcss';
import postcssGray from 'postcss-color-gray';

postcss([
  postcssGray(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Gray] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether the original `gray()` function should
be preserved or replaced. By default, the `gray()` function is replaced.

By setting `preserve` to `true`, the original `gray()` function is preserved.

```js
postcssGray({ preserve: true });
```

```pcss
body {
  background-color: gray(100);
  color: gray(0 / 90%);
}

/* becomes */

body {
  background-color: gray(100);
  background-color: rgb(255,255,255);
  color: gray(0 / 90%);
  color: rgba(0,0,0,.9);
}
```

[cli-img]: https://img.shields.io/travis/postcss/postcss-color-gray.svg
[cli-url]: https://travis-ci.org/postcss/postcss-color-gray
[css-img]: https://cssdb.org/badge/gray-function.svg
[css-url]: https://cssdb.org/#gray-function
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-color-gray.svg
[npm-url]: https://www.npmjs.com/package/postcss-color-gray

[PostCSS]: https://github.com/postcss/postcss
[PostCSS Gray]: https://github.com/postcss/postcss-color-gray
[CSSWG Specification]: https://drafts.csswg.org/css-color/#grays
