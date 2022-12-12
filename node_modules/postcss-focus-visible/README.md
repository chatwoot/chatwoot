# PostCSS Focus Visible [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Focus Visible] lets you use the `:focus-visible` pseudo-class in
CSS, following the [Selectors Level 4 specification].

It is the companion to the [focus-visible polyfill].

```css
:focus:not(:focus-visible) {
  outline: none;
}

/* becomes */

:focus:not(.focus-visible) {
  outline: none;
}

:focus:not(:focus-visible) {
  outline: none;
}
```

[PostCSS Focus Visible] duplicates rules using the `:focus-visible` pseudo-class
with a `.focus-visible` class selector, the same selector used by the
[focus-visible polyfill]. This replacement selector can be changed using the
`replaceWith` option. Also, the preservation of the original `:focus-visible`
rule can be disabled using the `preserve` option.

## Usage

Add [PostCSS Focus Visible] to your project:

```bash
npm install postcss-focus-visible --save-dev
```

Use [PostCSS Focus Visible] to process your CSS:

```js
const postcssFocusVisible = require('postcss-focus-visible');

postcssFocusVisible.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssFocusVisible = require('postcss-focus-visible');

postcss([
  postcssFocusVisible(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Focus Visible] runs in all Node environments, with special
instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option defines whether the original selector should remain. By
default, the original selector is preserved.

```js
focusVisible({ preserve: false });
```

```css
:focus:not(:focus-visible) {
  outline: none;
}

/* becomes */

:focus:not(.focus-visible) {
  outline: none;
}
```

### replaceWith

The `replaceWith` option defines the selector to replace `:focus-visible`. By
default, the replacement selector is `.focus-visible`.

```js
focusVisible({ replaceWith: '[focus-visible]' });
```

```css
:focus:not(:focus-visible) {
  outline: none;
}

/* becomes */

:focus:not([focus-visible]) {
  outline: none;
}

:focus:not(:focus-visible) {
  outline: none;
}
```

[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-focus-visible.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-focus-visible
[css-img]: https://cssdb.org/badge/focus-within-pseudo-class.svg
[css-url]: https://cssdb.org/#focus-visible-pseudo-class
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-focus-visible.svg
[npm-url]: https://www.npmjs.com/package/postcss-focus-visible

[focus-visible polyfill]: https://github.com/WICG/focus-visible
[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Focus Visible]: https://github.com/jonathantneal/postcss-focus-visible
[PostCSS Loader]: https://github.com/postcss/postcss-loader
[Selectors Level 4 specification]: https://www.w3.org/TR/selectors-4/#the-focus-visible-pseudo
