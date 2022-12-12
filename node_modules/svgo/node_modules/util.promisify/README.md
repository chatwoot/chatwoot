# util.promisify
Polyfill for util.promisify in node versions &lt; v8

node v8.0.0 added support for a built-in `util.promisify`: https://github.com/nodejs/node/pull/12442/

This package provides the built-in `util.promisify` in node v8.0.0 and later, and a replacement in other environments.

## Usage

**Direct**
```js
const promisify = require('util.promisify');
// Use `promisify` just like the built-in method on `util`
```

**Shim**
```js
require('util.promisify/shim')();
// `util.promisify` is now defined
const util = require('util');
// Use `util.promisify`
```

Note: this package requires a native ES5 environment, and for `Promise` to be globally available. It will throw upon requiring it if these are not present.

## Promisifying modules

If you want to promisify a whole module, like the `fs` module, you can use [`util.promisify-all`](https://www.npmjs.com/package/util.promisify-all).
