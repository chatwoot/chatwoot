# postcss-values-parser  [![Build Status](https://travis-ci.org/shellscape/postcss-values-parser.svg?branch=master)](https://travis-ci.org/shellscape/postcss-values-parser)

<img align="right" width="95" height="95"
     title="Philosopher’s stone, logo of PostCSS"
     src="http://postcss.github.io/postcss/logo.svg">

A CSS property value parser for use with [PostCSS](https://github.com/postcss/postcss),
following the same node, container, and traversal patterns as PostCSS.

## &nbsp;
<p align="center">
  <b>:rocket: &nbsp; Are you ready to tackle ES6 and hone your JavaScript Skills?</b> &nbsp; :rocket:<br/>
  Check out these outstanding <a href="https://es6.io/">ES6 courses</a> by <a href="https://github.com/wesbos">@wesbos</a>
</p>

---

As with PostCSS and postcss-selector-parser, this parser generates an
[Abstract Syntax Tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree),
(aka "AST") which allows for ease of traversal and granular inspection of each
part of a property's value.

## postcss-values-parser vs. postcss-value-parser

Yeah, it's a tad confusing. The [Lesshint](https://github.com/lesshint/lesshint)
project needed a parser that would allow detailed inspection of property values
to the same degree that PostCSS and [postcss-selector-parser](https://github.com/postcss/postcss-selector-parser)
provided. This was especailly important for the Lesshint project, as it provides
for very granular rules for linting LESS.

[postcss-value-parser](https://github.com/TrySound/postcss-value-parser)
makes a lot of assumption about how values should be parsed and how the resulting
AST should be organized. It was also fairly out of sync with the tokenzing and
traversal patterns and convenience methods found in PostCSS and
postcss-selector-parser.

So we needed an alternative, and drew upon all three projects to put together a
value parser that met and exceeded our needs. The improvements include:

- Written using ES6
- Uses the same Gulp toolchain as PostCSS
- Doesn't strip characters; eg. parenthesis
- Full AST traversal
- AST traversal based on node type
- Simple methods to derive strings from the parsed result
- Follows PostCSS patterns for whitespace between Nodes
- Provides convenience properties for number units, colors, etc.

## Usage

Please see the [API Documentation](API.md) for full usage information.

As with any NPM module, start with the install:

```
npm install postcss-values-parser
```

Using this parser is straightforward and doesn't require callbacks:

```js
const parser = require('postcss-values-parser');
const ast = parser('#fff').parse();

let color = ast       // the Root node
              .first  // the Value node
              .first; // a Word node, containing the color value.
```

## Loose Mode

Loose mode was introduced to support adherence to the W3C CSS Specification as
well as the ability to parse noncompliant CSS for variants like LESS, SCSS, and
CSSNext. If you're working with a noncompliant or CSS-like variant, then loose
mode is for you.

For example, the parser
will throw an error by default if `calc` parameters [don't adhere to the spec](https://www.w3.org/TR/css-values/#calc-syntax).
However, with loose mode enabled, the parse will ignore spec rules and succeed.

In-draft features, or CSS features in modules not yet finalized, often cause parser
errors. eg. `url(var(--somevar))`. Loose mode supports parsing of these features.

Loose Mode is enabled by passing an option of `loose: true` to the `parser` method.

```js
const less = 'calc(2+2)'; // not valid per spec, but valid in LESS
const cssnext = 'url(var(--somevar))'; // not valid per spec, but in spec draft

const parser = require('postcss-values-parser');
const ast = parser(less, { loose: true }).parse();

// parse will succeed
```

## Acknowledgements

This project was heavily influenced by [postcss-selector-parser](https://github.com/postcss/postcss-selector-parser)
and utilized many patterns and logical constructs from the project.

Tests and some tokenizing techniques found in [postcss-value-parser](https://github.com/TrySound/postcss-value-parser)
were used.

## Contributing

- `git fork/clone`
- `npm i`
- Before PR'ing, make sure `npm test` still pass. Add test if you're adding features.

When you tweak [API.md](API.md), please run `npm run toc` before PR'ing.
