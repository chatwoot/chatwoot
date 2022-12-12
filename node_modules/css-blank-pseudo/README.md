# CSS Blank Pseudo [<img src="http://jonathantneal.github.io/js-logo.svg" alt="" width="90" height="90" align="right">][CSS Blank Pseudo]

[![NPM Version][npm-img]][npm-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[CSS Blank Pseudo] lets you style form elements when they are empty, following
the [Selectors Level 4] specification.

```css
input {
  /* style an input */
}

input:blank {
  /* style an input without a value */
}
```

## Usage

From the command line, transform CSS files that use `:blank` selectors:

```bash
npx css-blank-pseudo SOURCE.css TRANSFORMED.css
```

Next, use your transformed CSS with this script:

```html
<link rel="stylesheet" href="TRANSFORMED.css">
<script src="https://unpkg.com/css-blank-pseudo/browser"></script>
<script>cssBlankPseudo(document)</script>
```

That’s it. The script is 509 bytes and works in all browsers.

---

If you support Internet Explorer 11, use the **browser legacy** script, which
is 671 bytes:

```html
<link rel="stylesheet" href="TRANSFORMED.css">
<script src="https://unpkg.com/css-blank-pseudo/browser-legacy"></script>
<script>cssBlankPseudo(document)</script>
```

## How it works

The [PostCSS plugin](README-POSTCSS.md) clones rules containing `:blank`,
replacing them with an alternative `[blank]` selector.

```css
input:blank {
  background-color: yellow;
}

/* becomes */

input[blank] {
  background-color: yellow;
}

input:blank {
  background-color: yellow;
}
```

Next, the [JavaScript library](README-BROWSER.md) adds a `blank` attribute to
elements otherwise matching `:blank` natively.

```html
<input value="" blank>
<input value="This element has a value">
```

[cli-img]: https://img.shields.io/travis/csstools/css-blank-pseudo/master.svg
[cli-url]: https://travis-ci.org/csstools/css-blank-pseudo
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/css-blank-pseudo.svg
[npm-url]: https://www.npmjs.com/package/css-blank-pseudo

[CSS Blank Pseudo]: https://github.com/csstools/css-blank-pseudo
[PostCSS Preset Env]: https://preset-env.cssdb.org/
[Selectors Level 4]: https://drafts.csswg.org/selectors-4/#blank
