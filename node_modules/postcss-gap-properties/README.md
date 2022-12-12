# PostCSS Gap Properties [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS Gap Properties] lets you use the `gap`, `column-gap`, and `row-gap`
shorthand properties in CSS, following the [CSS Grid Layout] specification.

```pcss
.standard-grid {
	gap: 20px;
}

.spaced-grid {
	column-gap: 40px;
	row-gap: 20px;
}

/* becomes */

.standard-grid {
	grid-gap: 20px;
	gap: 20px;
}

.spaced-grid {
	grid-column-gap: 40px;
	column-gap: 40px;
	grid-row-gap: 20px;
	row-gap: 20px;
}
```

## Usage

Add [PostCSS Gap Properties] to your project:

```bash
npm install postcss-gap-properties --save-dev
```

Use [PostCSS Gap Properties] to process your CSS:

```js
import postcssGapProperties from 'postcss-gap-properties';

postcssGapProperties.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
import postcss from 'postcss';
import postcssGapProperties from 'postcss-gap-properties';

postcss([
  postcssGapProperties(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS Gap Properties] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- |

## Options

### preserve

The `preserve` option determines whether the original `gap` declaration should
remain in the CSS. By default, the original declaration is preserved.

[css-img]: https://cssdb.org/badge/gap-properties.svg
[css-url]: https://cssdb.org/#gap-properties
[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-gap-properties.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-gap-properties
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-gap-properties.svg
[npm-url]: https://www.npmjs.com/package/postcss-gap-properties

[CSS Grid Layout]: https://www.w3.org/TR/css-grid-1/#gutters
[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS Loader]: https://github.com/postcss/postcss-loader
[PostCSS Gap Properties]: https://github.com/jonathantneal/postcss-gap-properties
