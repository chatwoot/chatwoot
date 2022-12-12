# PostCSS Pseudo Class Any Link [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Pseudo Class Any Link] lets you `:any-link` pseudo-class in CSS,
following the [Selectors] specification.

```pcss
nav :any-link > span {
  background-color: yellow;
}

/* becomes */

nav :link > span, nav :visited > span {
  background-color: yellow;
}

nav :any-link > span {
  background-color: yellow;
}
```

From the [proposal][Selectors]:

> The `:any-link` pseudo-class represents an element that acts as the source
  anchor of a hyperlink. It matches an element if the element would match
  `:link` or `:visited`.

## Usage

Add [PostCSS Pseudo Class Any Link] to your project:

```bash
npm install postcss-pseudo-class-any-link --save-dev
```

Use [PostCSS Pseudo Class Any Link] to process your CSS:

```js
const postcssPseudoClassAnyLink = require('postcss-pseudo-class-any-link');

postcssPseudoClassAnyLink.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssPseudoClassAnyLink = require('postcss-pseudo-class-any-link');

postcss([
  postcssPseudoClassAnyLink(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Pseudo Class Any Link] runs in all Node environments, with special
instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether the original `:any-link` rule is
preserved. By default, it is preserved.

```js
postcssPseudoClassAnyLink({ preserve: false })
```

```pcss
nav :any-link > span {
  background-color: yellow;
}

/* becomes */

nav :link > span, nav :visited > span {
  background-color: yellow;
}
```

[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-pseudo-class-any-link.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-pseudo-class-any-link
[css-img]: https://cssdb.org/badge/any-link-pseudo-class.svg
[css-url]: https://cssdb.org/#any-link-pseudo-class
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-pseudo-class-any-link.svg
[npm-url]: https://www.npmjs.com/package/postcss-pseudo-class-any-link

[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Loader]: https://github.com/postcss/postcss-loader
[PostCSS Pseudo Class Any Link]: https://github.com/jonathantneal/postcss-pseudo-class-any-link
[Selectors]: https://www.w3.org/TR/selectors-4/#the-any-link-pseudo
