# dset [![CI](https://github.com/lukeed/dset/workflows/CI/badge.svg?branch=master&event=push)](https://github.com/lukeed/dset/actions) [![codecov](https://badgen.net/codecov/c/github/lukeed/dset)](https://codecov.io/gh/lukeed/dset)

> A tiny (197B) utility for safely writing deep Object values~!

For _accessing_ deep object properties, please see [`dlv`](https://github.com/developit/dlv).

> **Using GraphQL?** You may want `dset/merge` – see [Merging](#merging) for more info.

## Install

```sh
$ npm install --save dset
```

## Modes

There are two "versions" of `dset` available:

#### `dset`
> **Size (gzip):** 197 bytes<br>
> **Availability:** [CommonJS](https://unpkg.com/dset/dist/index.js), [ES Module](https://unpkg.com/dset/dist/index.mjs), [UMD](https://unpkg.com/dset/dist/index.min.js)

```js
import { dset } from 'dset';
```

#### `dset/merge`
> **Size (gzip):** 307 bytes<br>
> **Availability:** [CommonJS](https://unpkg.com/dset/merge/index.js), [ES Module](https://unpkg.com/dset/merge/index.mjs), [UMD](https://unpkg.com/dset/merge/index.min.js)

```js
import { dset } from 'dset/merge';
```


## Usage

```js
import { dset } from 'dset';

let foo = { abc: 123 };
dset(foo, 'foo.bar', 'hello');
// or: dset(foo, ['foo', 'bar'], 'hello');
console.log(foo);
//=> {
//=>   abc: 123,
//=>   foo: { bar: 'hello' },
//=> }

dset(foo, 'abc.hello', 'world');
// or: dset(foo, ['abc', 'hello'], 'world');
console.log(foo);
//=> {
//=>   abc: { hello: 'world' },
//=>   foo: { bar: 'hello' },
//=> }

let bar = { a: { x: 7 }, b:[1, 2, 3] };
dset(bar, 'b.1', 999);
// or: dset(bar, ['b', 1], 999);
// or: dset(bar, ['b', '1'], 999);
console.log(bar);
//=> {
//=>   a: { x: 7 },
//=>   b: [1, 999, 3],
//=> }

dset(bar, 'a.y.0', 8);
// or: dset(bar, ['a', 'y', 0], 8);
// or: dset(bar, ['a', 'y', '0'], 8);
console.log(bar);
//=> {
//=>   a: {
//=>     x: 7,
//=>     y: [8],
//=>   },
//=>   b: [1, 999, 3],
//=> }

let baz = {};
dset(baz, 'a.0.b.0', 1);
dset(baz, 'a.0.b.1', 2);
console.log(baz);
//=> {
//=>   a: [{ b: [1, 2] }]
//=> }
```

## Merging

The main/default `dset` module forcibly writes values at the assigned key-path. However, in some cases, you may prefer to _merge_ values at the key-path. For example, when using [GraphQL's `@stream` and `@defer` directives](https://foundation.graphql.org/news/2020/12/08/improving-latency-with-defer-and-stream-directives/), you will need to merge the response chunks into a single object/list. This is why `dset/merge` exists~!

Below is a quick illustration of the difference between `dset` and `dset/merge`:

```js
let input = {
  hello: {
    abc: 123
  }
};

dset(input, 'hello', { world: 123 });
console.log(input);

// via `dset`
//=> {
//=>   hello: {
//=>     world: 123
//=>   }
//=> }

// via `dset/merge`
//=> {
//=>   hello: {
//=>     abc: 123,
//=>     world: 123
//=>   }
//=> }
```


## Immutability

As shown in the examples above, all `dset` interactions mutate the source object.

If you need immutable writes, please visit [`clean-set`](https://github.com/fwilkerson/clean-set) (182B).<br>
Alternatively, you may pair `dset` with [`klona`](https://github.com/lukeed/klona), a 366B utility to clone your source(s). Here's an example pairing:

```js
import { dset } from 'dset';
import { klona } from 'klona';

export function deepset(obj, path, val) {
  let copy = klona(obj);
  dset(copy, path, val);
  return copy;
}
```


## API

### dset(obj, path, val)

Returns: `void`

#### obj

Type: `Object`

The Object to traverse & mutate with a value.

#### path

Type: `String` or `Array`

The key path that should receive the value. May be in `x.y.z` or `['x', 'y', 'z']` formats.

> **Note:** Please be aware that only the _last_ key actually receives the value!

> **Important:** New Objects are created at each segment if there is not an existing structure.<br>However, when integers are encounted, Arrays are created instead!

#### value

Type: `Any`

The value that you want to set. Can be of any type!


## Benchmarks

For benchmarks and full results, check out the [`bench`](/bench) directory!

```
# Node 10.13.0

Validation:
  ✔ set-value
  ✔ lodash/set
  ✔ dset

Benchmark:
  set-value    x 1,701,821 ops/sec ±1.81% (93 runs sampled)
  lodash/set   x   975,530 ops/sec ±0.96% (91 runs sampled)
  dset         x 1,797,922 ops/sec ±0.32% (94 runs sampled)
```


## Related

- [dlv](https://github.com/developit/dlv) - safely read from deep properties in 120 bytes
- [dequal](https://github.com/lukeed/dequal) - safely check for deep equality in 247 bytes
- [klona](https://github.com/lukeed/klona) - quickly "deep clone" data in 200 to 330 bytes
- [clean-set](https://github.com/fwilkerson/clean-set) - fast, immutable version of `dset` in 182 bytes


## License

MIT © [Luke Edwards](https://lukeed.com)
