# postcss-selector-not [![CSS Standard Status](https://cssdb.org/badge/not-pseudo-class.svg)](https://cssdb.org/#not-pseudo-class) [![Build Status](https://travis-ci.org/postcss/postcss-selector-not.svg?branch=master)](https://travis-ci.org/postcss/postcss-selector-not)

> PostCSS plugin to transform `:not()` W3C CSS level 4 pseudo class to :not() CSS level 3 selectors

http://dev.w3.org/csswg/selectors-4/#negation

[!['Can I use' table](https://caniuse.bitsofco.de/image/css-not-sel-list.png)](https://caniuse.com/#feat=css-not-sel-list)

## Installation

```console
$ npm install postcss-selector-not
```

## Usage

```js
var postcss = require("postcss")

var output = postcss()
  .use(require("postcss-selector-not"))
  .process(require("fs").readFileSync("input.css", "utf8"))
  .css
```

Using this `input.css`:

```css
p:not(:first-child, .special) {
  color: red;
}
```

you will get:

```css
p:not(:first-child):not(.special) {
  color: red;
}
```

---

## [Changelog](CHANGELOG.md)

## [License](LICENSE)
