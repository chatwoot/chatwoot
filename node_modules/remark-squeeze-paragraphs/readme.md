# remark-squeeze-paragraphs

[![Build][build-badge]][build]
[![Coverage][coverage-badge]][coverage]
[![Downloads][downloads-badge]][downloads]
[![Size][size-badge]][size]
[![Sponsors][sponsors-badge]][collective]
[![Backers][backers-badge]][collective]
[![Chat][chat-badge]][chat]

[**remark**][remark] plugin to remove empty (or whitespace only) paragraphs.

## Install

[npm][]:

```sh
npm install remark-squeeze-paragraphs
```

## Use

```js
var remark = require('remark')
var stripBadges = require('remark-strip-badges')
var squeezeParagraphs = require('remark-squeeze-paragraphs')

remark()
  .use(stripBadges)
  .processSync('![](https://img.shields.io/)\n\ntext')
  .toString()
// => "\n\ntext\n"

remark()
  .use(stripBadges)
  .use(squeezeParagraphs)
  .processSync('![](https://img.shields.io/)\n\ntext')
  .toString()
// => "text\n"
```

## API

### `remark().use(squeezeParagraphs)`

Remove empty (or white-space only) paragraphs.

## Security

Use of `remark-squeeze-paragraphs` does not involve [**rehype**][rehype]
([**hast**][hast]) or user content so there are no openings for
[cross-site scripting (XSS)][xss] attacks.

## Related

*   [`mdast-squeeze-paragraphs`][mdast-squeeze-paragraphs]
    — [**mdast**][mdast] utility that is in the core of this plugin

## Contribute

See [`contributing.md`][contributing] in [`remarkjs/.github`][health] for ways
to get started.
See [`support.md`][support] for ways to get help.

This project has a [code of conduct][coc].
By interacting with this repository, organization, or community you agree to
abide by its terms.

## License

[MIT][license] © Eugene Sharygin

[build-badge]: https://img.shields.io/travis/remarkjs/remark-squeeze-paragraphs/master.svg

[build]: https://travis-ci.org/remarkjs/remark-squeeze-paragraphs

[coverage-badge]: https://img.shields.io/codecov/c/github/remarkjs/remark-squeeze-paragraphs.svg

[coverage]: https://codecov.io/github/remarkjs/remark-squeeze-paragraphs

[downloads-badge]: https://img.shields.io/npm/dm/remark-squeeze-paragraphs.svg

[downloads]: https://www.npmjs.com/package/remark-squeeze-paragraphs

[size-badge]: https://img.shields.io/bundlephobia/minzip/remark-squeeze-paragraphs.svg

[size]: https://bundlephobia.com/result?p=remark-squeeze-paragraphs

[sponsors-badge]: https://opencollective.com/unified/sponsors/badge.svg

[backers-badge]: https://opencollective.com/unified/backers/badge.svg

[collective]: https://opencollective.com/unified

[chat-badge]: https://img.shields.io/badge/chat-spectrum-7b16ff.svg

[chat]: https://spectrum.chat/unified/remark

[npm]: https://docs.npmjs.com/cli/install

[health]: https://github.com/remarkjs/.github

[contributing]: https://github.com/remarkjs/.github/blob/master/contributing.md

[support]: https://github.com/remarkjs/.github/blob/master/support.md

[coc]: https://github.com/remarkjs/.github/blob/master/code-of-conduct.md

[license]: license

[remark]: https://github.com/remarkjs/remark

[mdast]: https://github.com/syntax-tree/mdast

[mdast-squeeze-paragraphs]: https://github.com/syntax-tree/mdast-squeeze-paragraphs

[xss]: https://en.wikipedia.org/wiki/Cross-site_scripting

[rehype]: https://github.com/rehypejs/rehype

[hast]: https://github.com/syntax-tree/hast
