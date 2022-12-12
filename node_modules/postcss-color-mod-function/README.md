# PostCSS color-mod() Function [<img src="https://postcss.github.io/postcss/logo.svg" alt="PostCSS Logo" width="90" height="90" align="right">][postcss]

[![NPM Version][npm-img]][npm-url]
[![CSS Standard Status][css-img]][css-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[PostCSS color-mod() Function] lets you modify colors using the `color-mod()`
function in CSS, following the [CSS Color Module Level 4] specification.

**`color-mod()` has been removed from the Color Module Level 4 specification.**

```pcss
:root {
  --brand-red:      color-mod(yellow blend(red 50%));
  --brand-red-hsl:  color-mod(yellow blend(red 50% hsl));
  --brand-red-hwb:  color-mod(yellow blend(red 50% hwb));
  --brand-red-dark: color-mod(red blackness(20%));
}

/* becomes */

:root {
  --brand-red:      rgb(255, 127.5, 0);
  --brand-red-hsl:  rgb(255, 127.5, 255);
  --brand-red-hwb:  rgb(255, 127.5, 0);
  --brand-red-dark: rgb(204, 0, 0);
}

/* or, using stringifier(color) { return color.toString() } */

:root {
  --brand-red:      rgb(100% 50% 0% / 100%);
  --brand-red-hsl:  hsl(30 100% 50% / 100%);
  --brand-red-hwb:  hwb(30 0% 0% / 100%);
  --brand-red-dark: hwb(0 0% 20% / 100%);
}
```

### Supported Colors

The `color-mod()` function accepts `rgb()`, legacy comma-separated `rgb()`,
`rgba()`, `hsl()`, legacy comma-separated `hsl()`, `hsla()`, `hwb()`, and
`color-mod()` colors, as well as 3, 4, 6, and 8 digit hex colors, and named
colors without the need for additional plugins.

Implemention details are available in
[the specification](https://drafts.csswg.org/css-color/#funcdef-color-mod).

### Supported Color Adjusters

The `color-mod()` function accepts `red()`, `green()`, `blue()`, `a()` /
`alpha()`, `rgb()`, `h()` / `hue()`, `s()` / `saturation()`, `l()` /
`lightness()`, `w()` / `whiteness()`, `b()` / `blackness()`, `tint()`,
`shade()`, `blend()`, `blenda()`, and `contrast()` color adjusters.

Implemention details are available in
[the specification](https://drafts.csswg.org/css-color/#typedef-color-adjuster).

### Supported Variables

By default, `var()` variables will be used if their corresponding Custom
Properties are found in a `:root` rule, or if a fallback value is specified.

## Usage

Add [PostCSS color-mod() Function] to your project:

```bash
npm install postcss-color-mod-function --save-dev
```

Use [PostCSS color-mod() Function] to process your CSS:

```js
const postcssColorMod = require('postcss-color-mod-function');

postcssColorMod.process(YOUR_CSS /*, processOptions, pluginOptions */);
```

Or use it as a [PostCSS] plugin:

```js
const postcss = require('postcss');
const postcssColorMod = require('postcss-color-mod-function');

postcss([
  postcssColorMod(/* pluginOptions */)
]).process(YOUR_CSS /*, processOptions */);
```

[PostCSS color-mod() Function] runs in all Node environments, with special instructions for:

| [Node](INSTALL.md#node) | [PostCSS CLI](INSTALL.md#postcss-cli) | [Webpack](INSTALL.md#webpack) | [Create React App](INSTALL.md#create-react-app) | [Gulp](INSTALL.md#gulp) | [Grunt](INSTALL.md#grunt) |
| --- | --- | --- | --- | --- | --- |

## Options

### stringifier

The `stringifier` option defines how transformed colors will be produced in CSS.
By default, legacy `rbg()` and `rgba()` colors are produced, but this can be
easily updated to support [CSS Color Module Level 4 colors] colors.

```js
import postcssColorMod from 'postcss-color-mod-function';

postcssColorMod({
  stringifier(color) {
    return color.toString(); // use CSS Color Module Level 4 colors (rgb, hsl, hwb)
  }
});
```

Future major releases of [PostCSS color-mod() Function] may reverse this
functionality so that CSS Color Module Level 4 colors are produced by default.

### unresolved

The `unresolved` option defines how unresolved functions and arguments should
be handled. The available options are `throw`, `warn`, and `ignore`. The
default option is to `throw`.

If `ignore` is used, the `color-mod()` function will remain unchanged.

```js
import postcssColorMod from 'postcss-color-mod-function';

postcssColorMod({
  unresolved: 'ignore' // ignore unresolved color-mod() functions
});
```

### transformVars

The `transformVars` option defines whether `var()` variables used within
`color-mod()` should be transformed into their corresponding Custom Properties
available in `:root`, or their fallback value if it is specified. By default,
`var()` variables will be transformed.

However, because these transformations occur at build time, they cannot be
considered accurate. Accurately resolving cascading variables relies on
knowledge of the living DOM tree.

### importFrom

The `importFrom` option allows you to import variables from other sources,
which might be CSS, JS, and JSON files, and directly passed objects.

```js
postcssColorMod({
  importFrom: 'path/to/file.css' // :root { --brand-dark: blue; --brand-main: var(--brand-dark); }
});
```

```pcss
.brand-faded {
  color: color-mod(var(--brand-main) a(50%));
}

/* becomes */

.brand-faded {
  color: rgba(0, 0, 255, .5);
}
```

Multiple files can be passed into this option, and they will be parsed in the
order they were received. JavaScript files, JSON files, and objects will need
to namespace custom properties under a `customProperties` or
`custom-properties` key.

```js
postcssColorMod({
  importFrom: [
    'path/to/file.css',   // :root { --brand-dark: blue; --brand-main: var(--brand-dark); }
    'and/then/this.js',   // module.exports = { customProperties: { '--brand-dark': 'blue', '--brand-main': 'var(--brand-dark)' } }
    'and/then/that.json', // { "custom-properties": { "--brand-dark": "blue", "--brand-main": "var(--brand-dark)" } }
    {
      customProperties: {
        '--brand-dark': 'blue',
        '--brand-main': 'var(--brand-dark)'
      }
    }
  ]
});
```

Variables may reference other variables, and this plugin will attempt to
resolve them. If `transformVars` is set to `false` then `importFrom` will not
be used.

[cli-img]: https://img.shields.io/travis/jonathantneal/postcss-color-mod-function.svg
[cli-url]: https://travis-ci.org/jonathantneal/postcss-color-mod-function
[css-img]: https://cssdb.org/badge/color-mod-function.svg
[css-url]: https://preset-env.cssdb.org/features#color-mod-function
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/postcss-color-mod-function.svg
[npm-url]: https://www.npmjs.com/package/postcss-color-mod-function

[CSS Color Module Level 4]: https://www.w3.org/TR/css-color-4/#funcdef-color-mod
[Gulp PostCSS]: https://github.com/postcss/gulp-postcss
[Grunt PostCSS]: https://github.com/nDmitry/grunt-postcss
[PostCSS]: https://github.com/postcss/postcss
[PostCSS color-mod() Function]: https://github.com/jonathantneal/postcss-color-mod-function
