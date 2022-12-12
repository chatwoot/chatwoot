# `@mdx-js/react`

[![Build Status][build-badge]][build]
[![lerna][lerna-badge]][lerna]
[![Chat][chat-badge]][chat]

Map components to HTML elements based on the Markdown syntax.
Serves as the React implementation for [MDX][].

## Installation

[npm][]:

```sh
npm install --save @mdx-js/react
```

## Usage

```md
<!-- helloworld.md -->

# Hello, World!
```

```jsx
import React from 'react'
import {MDXProvider} from '@mdx-js/react'
import {renderToString} from 'react-dom/server'

import HelloWorld from './helloworld.md'

const H1 = props => <h1 style={{color: 'tomato'}} {...props} />

console.log(
  renderToString(
    <MDXProvider components={{h1: H1}}>
      <HelloWorld />
    </MDXProvider>
  )
)
```

Yields:

```html
<h1 style="color:tomato">Hello, world!</h1>
```

## Contribute

See the [Support][] and [Contributing][] guidelines on the MDX website for ways
to (get) help.

This project has a [Code of Conduct][coc].
By interacting with this repository, organisation, or community you agree to
abide by its terms.

## License

[MIT][] © [Compositor][] and [Vercel][]

<!-- Definitions -->

[build]: https://travis-ci.com/mdx-js/mdx
[build-badge]: https://travis-ci.com/mdx-js/mdx.svg?branch=master
[lerna]: https://lerna.js.org/
[lerna-badge]: https://img.shields.io/badge/maintained%20with-lerna-cc00ff.svg
[chat-badge]: https://img.shields.io/badge/chat-discussions-success.svg
[chat]: https://github.com/mdx-js/mdx/discussions
[contributing]: https://mdxjs.com/contributing
[support]: https://mdxjs.com/support
[coc]: https://github.com/mdx-js/.github/blob/master/code-of-conduct.md
[mit]: license
[compositor]: https://compositor.io
[vercel]: https://vercel.com
[mdx]: https://github.com/mdx-js/mdx
[npm]: https://docs.npmjs.com/cli/install
