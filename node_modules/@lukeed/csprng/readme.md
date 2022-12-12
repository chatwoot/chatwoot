# @lukeed/csprng ![CI](https://github.com/lukeed/csprng/workflows/CI/badge.svg) [![codecov](https://badgen.now.sh/codecov/c/github/lukeed/csprng)](https://codecov.io/gh/lukeed/csprng)

> A tiny (~90B) isomorphic wrapper for `crypto.randomBytes` in Node.js and browsers.

***Why?***

This package allows you/dependents to import a cryptographically secure generator (CSPRNG) _without_ worrying about (aka, checking the runtime environment for) the different `crypto` implementations. Instead, by extracting a `random` function into a third-party/external package, one can rely on bundlers and/or module resolution to load the correct implementation for the desired environment.

In other words, one can include the browser-specific implementation when bundling for the browser, completely ignoring the Node.js code – or vice versa.

By default, this module is set up to work with Rollup, webpack, and Node's native ESM _and_ CommonJS path resolutions.

## Install

```
$ npm install --save @lukeed/csprng
```


## Usage

***General Usage***

```js
// Rely on bundlers/environment detection
import { random } from '@lukeed/csprng';

const array = random(12);
// browser => Uint8Array(12) [...]
// Node.js => <Buffer ...>
```

***Specific Environment***

```js
// Choose the "browser" implementation explicitly.
//=> ! NOTE ! Will break in Node.js environments!
import { random } from '@lukeed/csprng/browser';

const array = random(1024);
//=> Uint8Array(1024) [...]

// ---

// Choose the "node" implementation explicitly.
//=> ! NOTE ! Will break in browser environments!
import { random } from '@lukeed/csprng/node';

const array = random(1024);
//=> <Buffer ...>
```


## API

### random(length)
Returns: `Buffer` or `Uint8Array`

Returns a typed array of given `length`.


#### length
Type: `Number`

The desired length of your output TypedArray.


## Related

- [uid](https://github.com/lukeed/uid) - A tiny (134B) and fast utility to randomize unique IDs of fixed length
- [@lukeed/uuid](https://github.com/lukeed/uuid) - A tiny (230B), fast, and cryptographically secure UUID (V4) generator for Node and the browser


## License

MIT © [Luke Edwards](https://lukeed.com)
