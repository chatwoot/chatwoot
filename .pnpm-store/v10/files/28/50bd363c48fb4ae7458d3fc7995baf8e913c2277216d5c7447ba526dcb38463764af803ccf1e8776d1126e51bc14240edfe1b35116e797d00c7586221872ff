<p align="center">
  <img src="https://i.imgur.com/0cSIPzP.png" width="300" height="300" alt="unfetch">
  <br>
  <a href="https://www.npmjs.org/package/unfetch"><img src="https://img.shields.io/npm/v/unfetch.svg?style=flat" alt="npm"></a>
  <a href="https://unpkg.com/unfetch/polyfill"><img src="https://img.badgesize.io/https://unpkg.com/unfetch/polyfill/index.js?compression=gzip" alt="gzip size"></a>
  <a href="https://www.npmjs.com/package/unfetch"><img src="https://img.shields.io/npm/dt/unfetch.svg" alt="downloads" ></a>
  <a href="https://travis-ci.org/developit/unfetch"><img src="https://travis-ci.org/developit/unfetch.svg?branch=master" alt="travis"></a>
</p>

# unfetch

> Tiny 500b fetch "barely-polyfill"

-   **Tiny:** under **500 bytes** of [ES3](https://unpkg.com/unfetch) gzipped
-   **Minimal:** just `fetch()` with headers and text/json responses
-   **Familiar:** a subset of the full API
-   **Supported:** supports IE8+ _(assuming `Promise` is polyfilled of course!)_
-   **Standalone:** one function, no dependencies
-   **Modern:** written in ES2015, transpiled to 500b of old-school JS

> 🤔 **What's Missing?**
>
> -   Uses simple Arrays instead of Iterables, since Arrays _are_ iterables
> -   No streaming, just Promisifies existing XMLHttpRequest response bodies
> -   Use in Node.JS is handled by [isomorphic-unfetch](https://github.com/developit/unfetch/tree/master/packages/isomorphic-unfetch)

* * *

## Table of Contents

-   [Install](#install)
-   [Usage](#usage)
-   [Examples & Demos](#examples--demos)
-   [API](#api)
-   [Caveats](#caveats)
-   [Contribute](#contribute)
-   [License](#license)

* * *

## Install

This project uses [node](http://nodejs.org) and [npm](https://npmjs.com). Go check them out if you don't have them locally installed.

```sh
$ npm install --save unfetch
```

Then with a module bundler like [rollup](http://rollupjs.org/) or [webpack](https://webpack.js.org/), use as you would anything else:

```javascript
// using ES6 modules
import fetch from 'unfetch'

// using CommonJS modules
var fetch = require('unfetch')
```

The [UMD](https://github.com/umdjs/umd) build is also available on [unpkg](https://unpkg.com):

```html
<script src="//unpkg.com/unfetch/dist/unfetch.umd.js"></script>
```

This exposes the `unfetch()` function as a global.

* * *

## Usage

As a [**ponyfill**](https://ponyfill.com):

```js
import fetch from 'unfetch';

fetch('/foo.json')
  .then( r => r.json() )
  .then( data => {
    console.log(data);
  });
```

Globally, as a [**polyfill**](https://ponyfill.com/#polyfill):

```js
import 'unfetch/polyfill';

// "fetch" is now installed globally if it wasn't already available

fetch('/foo.json')
  .then( r => r.json() )
  .then( data => {
    console.log(data);
  });
```

## Examples & Demos

[**Real Example on JSFiddle**](https://jsfiddle.net/developit/qrh7tLc0/) ➡️

```js
// simple GET request:
fetch('/foo')
  .then( r => r.text() )
  .then( txt => console.log(txt) )


// complex POST request with JSON, headers:
fetch('/bear', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ hungry: true })
}).then( r => {
  open(r.headers.get('location'));
  return r.json();
})
```

## API
While one of Unfetch's goals is to provide a familiar interface, its API may differ from other `fetch` polyfills/ponyfills. 
One of the key differences is that Unfetch focuses on implementing the [`fetch()` API](https://fetch.spec.whatwg.org/#fetch-api), while offering minimal (yet functional) support to the other sections of the [Fetch spec](https://fetch.spec.whatwg.org/), like the [Headers class](https://fetch.spec.whatwg.org/#headers-class) or the [Response class](https://fetch.spec.whatwg.org/#response-class).
Unfetch's API is organized as follows:

### `fetch(url: string, options: Object)`
This function is the heart of Unfetch. It will fetch resources from `url` according to the given `options`, returning a Promise that will eventually resolve to the response.

Unfetch will account for the following properties in `options`:
  
  * `method`: Indicates the request method to be performed on the
   target resource (The most common ones being `GET`, `POST`, `PUT`, `PATCH`, `HEAD`, `OPTIONS` or `DELETE`).
  * `headers`: An `Object` containing additional information to be sent with the request, e.g. `{ 'Content-Type': 'application/json' }` to indicate a JSON-typed request body.
  * `credentials`: ⚠ Accepts a `"include"` string, which will allow both CORS and same origin requests to work with cookies. As pointed in the ['Caveats' section](#caveats), Unfetch won't send or receive cookies otherwise. The `"same-origin"` value is not supported. ⚠
  * `body`: The content to be transmited in request's body. Common content types include `FormData`, `JSON`, `Blob`, `ArrayBuffer` or plain text.

### `response` Methods and Attributes
These methods are used to handle the response accordingly in your Promise chain. Instead of implementing full spec-compliant [Response Class](https://fetch.spec.whatwg.org/#response-class) functionality, Unfetch provides the following methods and attributes:

#### `response.ok`
Returns `true` if the request received a status in the `OK` range (200-299).

#### `response.status`
Contains the status code of the response, e.g. `404` for a not found resource, `200` for a success.

#### `response.statusText`
A message related to the `status` attribute, e.g. `OK` for a status `200`.

#### `response.clone()`
Will return another `Object` with the same shape and content as `response`.

#### `response.text()`, `response.json()`, `response.blob()`
Will return the response content as plain text, JSON and `Blob`, respectively.

#### `response.headers`
Again, Unfetch doesn't implement a full spec-compliant [`Headers Class`](https://fetch.spec.whatwg.org/#headers), emulating some of the Map-like functionality through its own functions:
  * `headers.keys`: Returns an `Array` containing the `key` for every header in the response.
  * `headers.entries`: Returns an `Array` containing the `[key, value]` pairs for every `Header` in the response.
  * `headers.get(key)`: Returns the `value` associated with the given `key`.
  * `headers.has(key)`: Returns a `boolean` asserting the existence of a `value` for the given `key` among the response headers.

## Caveats

_Adapted from the GitHub fetch polyfill [**readme**](https://github.com/github/fetch#caveats)._

The `fetch` specification differs from `jQuery.ajax()` in mainly two ways that
bear keeping in mind:

* By default, `fetch` **won't send or receive any cookies** from the server,
  resulting in unauthenticated requests if the site relies on maintaining a user
  session.

```javascript
fetch('/users', {
  credentials: 'include'
});
```

* The Promise returned from `fetch()` **won't reject on HTTP error status**
  even if the response is an HTTP 404 or 500. Instead, it will resolve normally,
  and it will only reject on network failure or if anything prevented the
  request from completing.

  To have `fetch` Promise reject on HTTP error statuses, i.e. on any non-2xx
  status, define a custom response handler:

```javascript
fetch('/users')
  .then( checkStatus )
  .then( r => r.json() )
  .then( data => {
    console.log(data);
  });

function checkStatus(response) {
  if (response.ok) {
    return response;
  } else {
    var error = new Error(response.statusText);
    error.response = response;
    return Promise.reject(error);
  }
}
```

* * *

## Contribute

First off, thanks for taking the time to contribute!
Now, take a moment to be sure your contributions make sense to everyone else.

### Reporting Issues

Found a problem? Want a new feature? First of all see if your issue or idea has [already been reported](../../issues).
If it hasn't, just open a [new clear and descriptive issue](../../issues/new).

### Submitting pull requests

Pull requests are the greatest contributions, so be sure they are focused in scope, and do avoid unrelated commits.

> 💁 **Remember: size is the #1 priority.**
>
> Every byte counts! PR's can't be merged if they increase the output size much.

-   Fork it!
-   Clone your fork: `git clone https://github.com/<your-username>/unfetch`
-   Navigate to the newly cloned directory: `cd unfetch`
-   Create a new branch for the new feature: `git checkout -b my-new-feature`
-   Install the tools necessary for development: `npm install`
-   Make your changes.
-   `npm run build` to verify your change doesn't increase output size.
-   `npm test` to make sure your change doesn't break anything.
-   Commit your changes: `git commit -am 'Add some feature'`
-   Push to the branch: `git push origin my-new-feature`
-   Submit a pull request with full remarks documenting your changes.

## License

[MIT License](LICENSE.md) © [Jason Miller](https://jasonformat.com/)
