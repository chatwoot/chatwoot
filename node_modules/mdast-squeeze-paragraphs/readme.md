# mdast-squeeze-paragraphs

[![Build][build-badge]][build]
[![Coverage][coverage-badge]][coverage]
[![Downloads][downloads-badge]][downloads]
[![Size][size-badge]][size]
[![Sponsors][sponsors-badge]][collective]
[![Backers][backers-badge]][collective]
[![Chat][chat-badge]][chat]

[**mdast**][mdast] utility to remove empty paragraphs from a tree.

Paragraphs are considered empty if they do not contain non-whitespace
characters.

## Install

[npm][]:

```sh
npm install mdast-squeeze-paragraphs
```

## Use

```js
var u = require('unist-builder')
var squeezeParagraphs = require('mdast-squeeze-paragraphs')

var tree = u('root', [
  u('paragraph', []),
  u('paragraph', [u('text', 'Alpha')]),
  u('paragraph', [u('text', ' ')])
])

squeezeParagraphs(tree)

console.dir(tree, {depth: null})
```

Yields:

```js
{ type: 'root',
  children:
   [ { type: 'paragraph',
       children: [ { type: 'text', value: 'Alpha' } ] } ] }
```

## API

### `squeezeParagraphs(tree)`

Modifies [tree][] in-place.
Returns `tree`.

## Security

Use of `mdast-squeeze-paragraphs` does not involve [**hast**][hast] or user
content so there are no openings for [cross-site scripting (XSS)][xss] attacks.

## Related

*   [`remark-squeeze-paragraphs`][squeeze-paragraphs]
    — [**remark**][remark] plugin wrapper

## Contribute

See [`contributing.md` in `syntax-tree/.github`][contributing] for ways to get
started.
See [`support.md`][support] for ways to get help.

This project has a [code of conduct][coc].
By interacting with this repository, organization, or community you agree to
abide by its terms.

## License

[MIT][license] © Eugene Sharygin

<!-- Definitions -->

[build-badge]: https://img.shields.io/travis/syntax-tree/mdast-squeeze-paragraphs.svg

[build]: https://travis-ci.org/syntax-tree/mdast-squeeze-paragraphs

[coverage-badge]: https://img.shields.io/codecov/c/github/syntax-tree/mdast-squeeze-paragraphs.svg

[coverage]: https://codecov.io/github/syntax-tree/mdast-squeeze-paragraphs

[downloads-badge]: https://img.shields.io/npm/dm/mdast-squeeze-paragraphs.svg

[downloads]: https://www.npmjs.com/package/mdast-squeeze-paragraphs

[size-badge]: https://img.shields.io/bundlephobia/minzip/mdast-squeeze-paragraphs.svg

[size]: https://bundlephobia.com/result?p=mdast-squeeze-paragraphs

[sponsors-badge]: https://opencollective.com/unified/sponsors/badge.svg

[backers-badge]: https://opencollective.com/unified/backers/badge.svg

[collective]: https://opencollective.com/unified

[chat-badge]: https://img.shields.io/badge/chat-spectrum-7b16ff.svg

[chat]: https://spectrum.chat/unified/syntax-tree

[npm]: https://docs.npmjs.com/cli/install

[license]: license

[contributing]: https://github.com/syntax-tree/.github/blob/master/contributing.md

[support]: https://github.com/syntax-tree/.github/blob/master/support.md

[coc]: https://github.com/syntax-tree/.github/blob/master/code-of-conduct.md

[tree]: https://github.com/syntax-tree/unist#tree

[mdast]: https://github.com/syntax-tree/mdast

[remark]: https://github.com/remarkjs/remark

[squeeze-paragraphs]: https://github.com/remarkjs/remark-squeeze-paragraphs

[xss]: https://en.wikipedia.org/wiki/Cross-site_scripting

[hast]: https://github.com/syntax-tree/hast
