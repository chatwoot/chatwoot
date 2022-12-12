# Isomorphic Unfetch

Switches between [unfetch](https://github.com/developit/unfetch) & [node-fetch](https://github.com/bitinn/node-fetch) for client & server.

## Install

This project uses [node](http://nodejs.org) and [npm](https://npmjs.com). Go check them out if you don't have them locally installed.

```sh
$ npm i isomorphic-unfetch
```

Then with a module bundler like [rollup](http://rollupjs.org/) or [webpack](https://webpack.js.org/), use as you would anything else:

```javascript
// using ES6 modules
import fetch from 'isomorphic-unfetch'

// using CommonJS modules
const fetch = require('isomorphic-unfetch')
```

## Usage

As a [**ponyfill**](https://ponyfill.com):

```js
import fetch from 'isomorphic-unfetch';

fetch('/foo.json')
  .then( r => r.json() )
  .then( data => {
    console.log(data);
  });
```

Globally, as a [**polyfill**](https://ponyfill.com/#polyfill):

```js
import 'isomorphic-unfetch';

// "fetch" is now installed globally if it wasn't already available

fetch('/foo.json')
  .then( r => r.json() )
  .then( data => {
    console.log(data);
  });
```

## License

[MIT License](LICENSE.md) © [Jason Miller](https://jasonformat.com/)
