# @lukeed/uuid ![CI](https://github.com/lukeed/uuid/workflows/CI/badge.svg) [![codecov](https://badgen.now.sh/codecov/c/github/lukeed/uuid)](https://codecov.io/gh/lukeed/uuid)

> A tiny (~230B) and [fast](#benchmarks) UUID (v4) generator for Node and the browser.

This module offers two [modes](#modes) for your needs:

* [`@lukeed/uuid`](#lukeeduuid)<br>_The default is "non-secure", which uses `Math.random` to produce UUIDs._
* [`@lukeed/uuid/secure`](#lukeeduuidsecure)<br>_The "secure" mode produces cryptographically secure (CSPRNG) UUIDs using the current environment's `crypto` module._

> **Important:** <br>Version `1.0.0` only offered a "secure" implementation.<br>In `v2.0.0`, this is now exported as the `"@lukeed/uuid/secure"` entry.

Additionally, this module is preconfigured for native ESM support in Node.js with fallback to CommonJS. It will also work with any Rollup and webpack configuration.


## Install

```
$ npm install --save @lukeed/uuid
```

## Modes

There are two "versions" of `@lukeed/uuid` available:

#### `@lukeed/uuid`
> **Size (gzip):** 231 bytes<br>
> **Availability:** [CommonJS](https://unpkg.com/@lukeed/uuid/dist/index.js), [ES Module](https://unpkg.com/@lukeed/uuid/dist/index.mjs), [UMD](https://unpkg.com/@lukeed/uuid/dist/index.min.js)

Relies on `Math.random`, which means that, while faster, this mode **is not** cryptographically secure. <br>Works in Node.js and all browsers.

#### `@lukeed/uuid/secure`
> **Size (gzip):** 235 bytes<br>
> **Availability:** [CommonJS](https://unpkg.com/@lukeed/uuid/secure/index.js), [ES Module](https://unpkg.com/@lukeed/uuid/secure/index.mjs), [UMD](https://unpkg.com/@lukeed/uuid/secure/index.min.js)

Relies on the environment's `crypto` module in order to produce cryptographically secure (CSPRNG) values. <br>Works in all versions of Node.js. Works in all browsers with [`crypto.getRandomValues()` support](https://caniuse.com/#feat=getrandomvalues).


## Usage

```js
import { v4 as uuid } from '@lukeed/uuid';
import { v4 as secure } from '@lukeed/uuid/secure';

uuid(); //=> '400fa120-5e9f-411e-94bd-2a23f6695704'
uuid(); //=> 'cd6ffb4d-2eda-4c84-aef5-71eb360ac8c5'

secure(); //=> '8641f70e-8112-4168-9d81-d38170bfa612'
secure(); //=> 'd175fabc-2a4d-475f-be56-29ba8104c2f2'
```


## API

### uuid.v4()
Returns: `string`

Creates a new Version 4 (random) [RFC4122](http://www.ietf.org/rfc/rfc4122.txt) UUID.


## Benchmarks

> Running on Node.js v12.18.4

```
Validation:
  ✔ String.replace(Math.random)
  ✔ String.replace(crypto)
  ✔ uuid/v4
  ✔ @lukeed/uuid
  ✔ @lukeed/uuid/secure

Benchmark:
  String.replace(Math.random)  x    381,358 ops/sec ±0.31% (93 runs sampled)
  String.replace(crypto)       x     15,842 ops/sec ±1.16% (86 runs sampled)
  uuid/v4                      x  1,259,600 ops/sec ±0.45% (91 runs sampled)
  @lukeed/uuid                 x  6,384,840 ops/sec ±0.22% (95 runs sampled)
  @lukeed/uuid/secure          x  5,439,096 ops/sec ±0.23% (98 runs sampled)
```

## Performance

The reason why this UUID.V4 implementation is so much faster is two-fold:

1) It composes an output with hexadecimal pairs (from a cached dictionary) instead of single characters.
2) It allocates a larger Buffer/ArrayBuffer up front (expensive) and slices off chunks as needed (cheap).

In the `@lukeed/uuid/secure` module, The internal ArrayBuffer is 4096 bytes, which supplies **256** `uuid.v4()` invocations. However, the default module preallocates **256** invocations using less memory upfront.

A larger buffer would result in higher performance over time, but I found this to be a good balance of performance and memory space.

## License

MIT © [Luke Edwards](https://lukeed.com)
