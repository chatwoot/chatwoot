# PostCSS Color Hex Alpha [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Color Hex Alpha] lets you use 4 & 8 character hex color notation in
CSS, following the [CSS Color Module] specification.

```pcss
body {
  background: #9d9c;
}

/* becomes */

body {
  background: rgba(153, 221, 153, 0.8);
}
```

## Usage

Add [PostCSS Color Hex Alpha] to your project:

```bash
npm install postcss-color-hex-alpha --save-dev
```

Use [PostCSS Color Hex Alpha] to process your CSS:

```js
const postcssColorHexAlpha = require('postcss-color-hex-alpha');

postcssColorHexAlpha.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssColorHexAlpha = require('postcss-color-hex-alpha');

postcss([
  postcssColorHexAlpha(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Color Hex Alpha] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether 4 & 8 character hex color notation
should be preserved in their original form. By default, these are not preserved.

```js
postcssColorHexAlpha({
  preserve: true
});
```

```pcss
body {
  background: #9d9c;
}

/* becomes */

body {
  background: rgba(153, 221, 153, 0.8);
  background: #9d9c;
}
```

[cli-img]: https://img.shields.io/travis/postcss/postcss-color-hex-alpha.svg
[cli-url]: https://travis-ci.org/postcss/postcss-color-hex-alpha
[css-img]: https://cssdb.org/badge/hexadecimal-alpha-notation.svg
[css-url]: https://cssdb.org/#hexadecimal-alpha-notation
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-color-hex-alpha.svg
[npm-url]: https://www.npmjs.com/package/postcss-color-hex-alpha

[PostCSS]: https://github.com/postcss/postcss
[PostCSS Color Hex Alpha]: https://github.com/postcss/postcss-color-hex-alpha
[CSS Color Module]: https://www.w3.org/TR/css-color-4/#hex-notation
