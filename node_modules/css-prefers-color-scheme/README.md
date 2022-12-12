# Prefers Color Scheme [<img src="https://jonathantneal.github.io/js-logo.svg" alt="" width="90" height="90" align="right">][Prefers Color Scheme]

[![NPM Version][npm-img]][npm-url]
[![Build Status][cli-img]][cli-url]
[![Support Chat][git-img]][git-url]

[Prefers Color Scheme] lets you use light and dark color schemes in all
browsers, following the [Media Queries] specification.

## Usage

From the command line, transform CSS files that use `prefers-color-scheme`
media queries:

```bash
npx css-prefers-color-scheme SOURCE.css TRANSFORMED.css
```

Next, use that transformed CSS with this script:

```html
<link rel="stylesheet" href="TRANSFORMED.css">
<script src="https://unpkg.com/css-prefers-color-scheme/browser.min"></script>
<script>
colorScheme = initPrefersColorScheme('dark') // apply "dark" queries (you can change it afterward, too)
</script>
```

Dependencies got you down? Don’t worry, this script is only 537 bytes.

## Usage

- First, transform `prefers-color-scheme` queries using this
  [PostCSS plugin](README-POSTCSS.md).
- Next, apply light and dark color schemes everywhere using this
  [browser script](README-BROWSER.md).

---

## How does it work?

[Prefers Color Scheme] uses a [PostCSS plugin](README-POSTCSS.md) to transform
`prefers-color-scheme` queries into `color-index` queries. This changes
`prefers-color-scheme: dark` into `(color-index: 48)`,
`prefers-color-scheme: light` into `(color-index: 70)`, and
`prefers-color-scheme: no-preference` into `(color-index: 22)`.

The frontend receives these `color-index` queries, which are understood in all
major browsers going back to Internet Explorer 9. However, since browsers only
apply `color-index` queries of `0`, our color scheme values are ignored.

[Prefers Color Scheme] uses a [browser script](README-BROWSER.md) to change
`(color-index: 48)` queries into `not all and (color-index: 48)` in order to
activate “dark mode” specific CSS, and it changes `(color-index: 70)` queries
into `not all and (color-index: 48)` to activate “light mode” specific CSS.

```css
@media (color-index: 70) { /* prefers-color-scheme: light */
  body {
    background-color: white;
    color: black;
  }
}
```

Since these media queries are accessible to `document.styleSheet`, no CSS
parsing is required.

## Why does the fallback work this way?

The value of `48` is chosen for dark mode because it is the keycode for `0`,
the hexidecimal value of black. Likewise, `70` is chosen for light mode because
it is the keycode for `f`, the hexidecimal value of white.

[cli-img]: https://img.shields.io/travis/csstools/css-prefers-color-scheme.svg
[cli-url]: https://travis-ci.org/csstools/css-prefers-color-scheme
[git-img]: https://img.shields.io/badge/support-chat-blue.svg
[git-url]: https://gitter.im/postcss/postcss
[npm-img]: https://img.shields.io/npm/v/css-prefers-color-scheme.svg
[npm-url]: https://www.npmjs.com/package/css-prefers-color-scheme

[PostCSS]: https://github.com/postcss/postcss
[Prefers Color Scheme]: https://github.com/csstools/css-prefers-color-scheme
[Media Queries]: https://drafts.csswg.org/mediaqueries-5/#descdef-media-prefers-color-scheme
