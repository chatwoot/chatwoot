# remark-external-links

[![Build][build-badge]][build]
[![Coverage][coverage-badge]][coverage]
[![Downloads][downloads-badge]][downloads]
[![Size][size-badge]][size]
[![Sponsors][sponsors-badge]][collective]
[![Backers][backers-badge]][collective]
[![Chat][chat-badge]][chat]

[**remark**][remark] plugin to automatically add `target` and `rel` attributes
to external links.

## Note!

This plugin is ready for the new parser in remark
([`remarkjs/remark#536`](https://github.com/remarkjs/remark/pull/536)).
The current and previous versions of the plugin work with the current and
previous versions of remark.

## Install

[npm][]:

```sh
npm install remark-external-links
```

## Use

Say we have the following file, `example.js`:

```js
var remark = require('remark')
var html = require('remark-html')
var externalLinks = require('remark-external-links')

remark()
  .use(externalLinks, {target: false, rel: ['nofollow']})
  .use(html)
  .process('[remark](https://github.com/remarkjs/remark)', function(err, file) {
    if (err) throw err
    console.log(String(file))
  })
```

Now, running `node example` yields:

```html
<p><a href="https://github.com/remarkjs/remark" rel="nofollow">remark</a></p>
```

## API

### `remark().use(externalLinks[, options])`

Automatically add `target` and `rel` attributes to external links.

##### `options`

###### `options.target`

How to display referenced documents (`string?`: `_self`, `_blank`, `_parent`,
or `_top`, default: `_blank`).
Pass `false` to not set `target`s on links.

###### `options.rel`

[Link types][mdn-rel] to hint about the referenced documents (`Array.<string>`
or `string`, default: `['nofollow', 'noopener', 'noreferrer']`).
Pass `false` to not set `rel`s on links.

> When using a `target`, add [`noopener` and `noreferrer`][mdn-a] to avoid
> exploitation of the `window.opener` API.

###### `options.protocols`

Protocols to check, such as `mailto` or `tel` (`Array.<string>`, default:
`['http', 'https']`).

###### `options.content`

[**hast**][hast] content to insert at the end of external links
([**Node**][node] or [**Children**][children]).
Will be inserted in a `<span>` element.

Useful for improving accessibility by [giving users advanced warning when
opening a new window][g201].

###### `options.contentProperties`

[`Properties`][properties] to add to the `span` wrapping `content`, when
given.

## Security

`options.content` is used and injected into the tree when it’s given.
This could open you up to a [cross-site scripting (XSS)][xss] attack if you pass
user provided content in.

This may become a problem if the Markdown later transformed to
[**rehype**][rehype] ([**hast**][hast]) or opened in an unsafe Markdown viewer.

Most likely though, this plugin will instead protect you from exploitation of
the `window.opener` API.

## Contribute

See [`contributing.md`][contributing] in [`remarkjs/.github`][health] for ways
to get started.
See [`support.md`][support] for ways to get help.

This project has a [code of conduct][coc].
By interacting with this repository, organization, or community you agree to
abide by its terms.

## License

[MIT][license] © [Cédric Delpoux][author]

<!-- Definitions -->

[build-badge]: https://img.shields.io/travis/remarkjs/remark-external-links/main.svg

[build]: https://travis-ci.org/remarkjs/remark-external-links

[coverage-badge]: https://img.shields.io/codecov/c/github/remarkjs/remark-external-links.svg

[coverage]: https://codecov.io/github/remarkjs/remark-external-links

[downloads-badge]: https://img.shields.io/npm/dm/remark-external-links.svg

[downloads]: https://www.npmjs.com/package/remark-external-links

[size-badge]: https://img.shields.io/bundlephobia/minzip/remark-external-links.svg

[size]: https://bundlephobia.com/result?p=remark-external-links

[sponsors-badge]: https://opencollective.com/unified/sponsors/badge.svg

[backers-badge]: https://opencollective.com/unified/backers/badge.svg

[collective]: https://opencollective.com/unified

[chat-badge]: https://img.shields.io/badge/chat-discussions-success.svg

[chat]: https://github.com/remarkjs/remark/discussions

[npm]: https://docs.npmjs.com/cli/install

[health]: https://github.com/remarkjs/.github

[contributing]: https://github.com/remarkjs/.github/blob/HEAD/contributing.md

[support]: https://github.com/remarkjs/.github/blob/HEAD/support.md

[coc]: https://github.com/remarkjs/.github/blob/HEAD/code-of-conduct.md

[license]: license

[author]: https://xuopled.netlify.com

[remark]: https://github.com/remarkjs/remark

[mdn-rel]: https://developer.mozilla.org/en-US/docs/Web/HTML/Link_types

[mdn-a]: https://developer.mozilla.org/en/docs/Web/HTML/Element/a

[hast]: https://github.com/syntax-tree/hast

[properties]: https://github.com/syntax-tree/hast#properties

[node]: https://github.com/syntax-tree/hast#nodes

[children]: https://github.com/syntax-tree/unist#child

[g201]: https://www.w3.org/WAI/WCAG21/Techniques/general/G201

[xss]: https://en.wikipedia.org/wiki/Cross-site_scripting

[rehype]: https://github.com/rehypejs/rehype
