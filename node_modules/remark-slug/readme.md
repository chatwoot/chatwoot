# remark-slug

[![Build][build-badge]][build]
[![Coverage][coverage-badge]][coverage]
[![Downloads][downloads-badge]][downloads]
[![Size][size-badge]][size]
[![Sponsors][sponsors-badge]][collective]
[![Backers][backers-badge]][collective]
[![Chat][chat-badge]][chat]

[**remark**][remark] plugin to add anchors headings using GitHub’s algorithm.

> ⚠️ Note: This is often useful when compiling to HTML.
> If you’re doing that, it’s probably smarter to use
> [`remark-rehype`][remark-rehype] and [`rehype-slug`][rehype-slug] and benefit
> from the [**rehype**][rehype] ecosystem.

## Install

[npm][]:

```sh
npm install remark-slug
```

## Use

Say we have the following file, `example.md`:

```markdown
# Lorem ipsum 😪

## dolor—sit—amet

### consectetur &amp; adipisicing

#### elit

##### elit
```

And our script, `example.js`, looks as follows:

```js
var fs = require('fs')
var unified = require('unified')
var markdown = require('remark-parse')
var slug = require('remark-slug')
var remark2rehype = require('remark-rehype')
var html = require('rehype-stringify')

unified()
  .use(markdown)
  .use(slug)
  .use(remark2rehype)
  .use(html)
  .process(fs.readFileSync('example.md'), function(err, file) {
    if (err) throw err
    console.log(String(file))
  })
```

Now, running `node example` yields:

```html
<h1 id="lorem-ipsum-">Lorem ipsum 😪</h1>
<h2 id="dolorsitamet">dolor—sit—amet</h2>
<h3 id="consectetur--adipisicing">consectetur &#x26; adipisicing</h3>
<h4 id="elit">elit</h4>
<h5 id="elit-1">elit</h5>
```

## API

### `remark().use(slug)`

Add anchors headings using GitHub’s algorithm.

Uses [`github-slugger`][ghslug] to creates GitHub-style slugs.

Sets `data.id` and `data.hProperties.id` on headings.
The first can be used by any plugin as a unique identifier, the second tells
[`mdast-util-to-hast`][to-hast] (used in [`remark-html`][remark-html] and
[`remark-rehype`][remark-rehype]) to use its value as an `id` attribute.

## Security

Use of `remark-slug` can open you up to a [cross-site scripting (XSS)][xss]
attack as it sets `id` attributes on headings.
In a browser, elements are retrievable by `id` with JavaScript and CSS.
If a user injects a heading that slugs to an id you are already using,
the user content may impersonate the website.

Always be wary with user input and use [`rehype-sanitize`][sanitize].

## Related

*   [`rehype-slug`][rehype-slug] — Add slugs to headings in HTML

## Contribute

See [`contributing.md`][contributing] in [`remarkjs/.github`][health] for ways
to get started.
See [`support.md`][support] for ways to get help.

This project has a [code of conduct][coc].
By interacting with this repository, organization, or community you agree to
abide by its terms.

## License

[MIT][license] © [Titus Wormer][author]

<!-- Definitions -->

[build-badge]: https://img.shields.io/travis/remarkjs/remark-slug/master.svg

[build]: https://travis-ci.org/remarkjs/remark-slug

[coverage-badge]: https://img.shields.io/codecov/c/github/remarkjs/remark-slug.svg

[coverage]: https://codecov.io/github/remarkjs/remark-slug

[downloads-badge]: https://img.shields.io/npm/dm/remark-slug.svg

[downloads]: https://www.npmjs.com/package/remark-slug

[size-badge]: https://img.shields.io/bundlephobia/minzip/remark-slug.svg

[size]: https://bundlephobia.com/result?p=remark-slug

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

[author]: https://wooorm.com

[remark]: https://github.com/remarkjs/remark

[ghslug]: https://github.com/Flet/github-slugger

[to-hast]: https://github.com/syntax-tree/mdast-util-to-hast

[rehype-slug]: https://github.com/rehypejs/rehype-slug

[remark-html]: https://github.com/remarkjs/remark-html

[remark-rehype]: https://github.com/remarkjs/remark-rehype

[rehype]: https://github.com/rehypejs/rehype

[xss]: https://en.wikipedia.org/wiki/Cross-site_scripting

[sanitize]: https://github.com/rehypejs/rehype-sanitize
