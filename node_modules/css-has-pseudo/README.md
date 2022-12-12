# CSS Has Pseudo [<img src="http://jonathantneal.github.io/js-logo.svg" alt="" width="90" height="90" align="right">][CSS Has Pseudo]

[![NPM Version][npm-img]][npm-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[CSS Has Pseudo] lets you style elements relative to other elements in CSS,
following the [Selectors Level 4] specification.

```css
a:has(> img) {
  /* style links that contain an image */
}

h1:has(+ p) {
  /* style level 1 headings that are followed by a paragraph */
}

section:not(:has(h1, h2, h3, h4, h5, h6)) {
  /* style sections that don’t contain any heading elements */
}

body:has(:focus) {
  /* style the body if it contains a focused element */
}
```

## Usage

From the command line, transform CSS files that use `:has` selectors:

```bash
npx css-has-pseudo SOURCE.css TRANSFORMED.css
```

Next, use your transformed CSS with this script:

```html
<link rel="stylesheet" href="TRANSFORMED.css">
<script src="https://unpkg.com/css-has-pseudo/browser"></script>
<script>cssHasPseudo(document)</script>
```

That’s it. The script is 765 bytes and works in all browsers, including
Internet Explorer 11. With a [Mutation Observer polyfill], the script will work
down to Internet Explorer 9.

## How it works

The [PostCSS plugin](README-POSTCSS.md) clones rules containing `:has`,
replacing them with an alternative `[:has]` selector.

```css
body:has(:focus) {
  background-color: yellow;
}

section:not(:has(h1, h2, h3, h4, h5, h6)) {
  background-color: gray;
}

/* becomes */

body[\:has\(\:focus\)] {
  background-color: yellow;
}

body:has(:focus) {
  background-color: yellow;
}

section[\:not-has\(h1\,\%20h2\,\%20h3\,\%20h4\,\%20h5\,\%20h6\)] {
  background-color: gray;
}

section:not(:has(h1, h2, h3, h4, h5, h6)) {
  background-color: gray;
}
```

Next, the [JavaScript library](README-BROWSER.md) adds a `[:has]` attribute to
elements otherwise matching `:has` natively.

```html
<body :has(:focus)>
  <input value="This element is focused">
</body>
```

[cli-img]: https://img.shields.io/travis/csstools/css-has-pseudo/master.svg
[cli-url]: https://travis-ci.org/csstools/css-has-pseudo
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/css-has-pseudo.svg
[npm-url]: https://www.npmjs.com/package/css-has-pseudo

[CSS Has Pseudo]: https://github.com/csstools/css-has-pseudo
[Mutation Observer polyfill]: https://github.com/webmodules/mutation-observer
[Selectors Level 4]: https://drafts.csswg.org/selectors-4/#has-pseudo
