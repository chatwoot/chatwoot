# PostCSS Focus Within [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Gitter Chat][git-img]][git-url]

[PostCSS Focus Within] lets you use the `:focus-within` pseudo-class in CSS,
following the [Selectors Level 4 specification].

It is the companion to the [focus-within polyfill].

```css
.my-form-field:focus-within label {
  background-color: yellow;
}

/* becomes */

.my-form-field[focus-within] label {
  background-color: yellow;
}

.my-form-field:focus-within label {
  background-color: yellow;
}
```

[PostCSS Focus Within] duplicates rules using the `:focus-within` pseudo-class
with a `[focus-within]` attribute selector, the same selector used by the
[focus-within polyfill]. This replacement selector can be changed using the
`replaceWith` option. Also, the preservation of the original `:focus-within`
rule can be disabled using the `preserve` option.

## Usage

Add [PostCSS Focus Within] to your project:

```bash
npm install postcss-focus-within --save-dev
```

Use [PostCSS Focus Within] to process your CSS:

```js
const postcssFocusWithin = require('postcss-focus-within');

postcssFocusWithin.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssFocusWithin = require('postcss-focus-within');

postcss([
  postcssFocusWithin(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Focus Within] runs in all Node environments, with special
instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option defines whether the original selector should remain. By
default, the original selector is preserved.

```js
focusWithin({ preserve: false });
```

```css
.my-form-field:focus-within label {
  background-color: yellow;
}

/* becomes */

.my-form-field[focus-within] label {
  background-color: yellow;
}
```

### replaceWith

The `replaceWith` option defines the selector to replace `:focus-within`. By
default, the replacement selector is `[focus-within]`.

```js
focusWithin({ replaceWith: '.focus-within' });
```

```css
.my-form-field:focus-within label {
  background-color: yellow;
}

/* becomes */

.my-form-field.focus-within label {
  background-color: yellow;
}

.my-form-field:focus-within label {
  background-color: yellow;
}
```

[css-img]: https://cssdb.org/badge/focus-within-pseudo-class.svg
[css-url]: https://cssdb.org/#focus-within-pseudo-class
[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-focus-within.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-focus-within
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-focus-within.svg
[npm-url]: https://www.npmjs.com/package/postcss-focus-within

[focus-within polyfill]: https://github.com/jonathantneal/focus-within
[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Focus Within]: https://github.com/jonathantneal/postcss-focus-within
[PostCSS Loader]: https://github.com/postcss/postcss-loader
[Selectors Level 4 specification]: https://www.w3.org/TR/selectors-4/#the-focus-within-pseudo
