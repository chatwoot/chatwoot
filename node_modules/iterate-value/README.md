# iterate-value <sup>[![Version Badge][npm-version-svg]][package-url]</sup>

[![Build Status][travis-svg]][travis-url]
[![dependency status][deps-svg]][deps-url]
[![dev dependency status][dev-deps-svg]][dev-deps-url]
[![License][license-image]][license-url]
[![Downloads][downloads-image]][downloads-url]

[![npm badge][npm-badge-png]][package-url]

Iterate any iterable JS value. Works robustly in all environments, all versions.

In modern engines, `[...value]` or `Array.from(value)` or `for (const item of value) { }` are sufficient to iterate an iterable value (an object with a `Symbol.iterator` method). However, older engines:
 - may lack `Symbol`, array spread, or `for..of` support altogether
 - may have `Symbol.iterator` but not implement it on everything it should, like arguments objects
 - may have `Map` and `Set`, but a non-standard name for the iterator-producing method (`.iterator` or `['@@iterator']`, eg) and no syntax to support it
 - may be old versions of Firefox that produce values until they throw a StopIteration exception, rather than having iteration result objects
 - may be polyfilled/shimmed/shammed, with `es6-shim` or `core-js` or similar

This library attempts to provide an abstraction over all that complexity!

If called with a single value, it will return an array of the yielded values. If also called with a callback function, it will instead call that callback once for each yielded value.

In node v13+, `exports` is used by the `es-get-iterator` dependency to provide a lean implementation that lacks all the complexity described above, in combination with the `browser` field so that bundlers will pick up the proper implementation.

If you are targeting browsers that definitely all have Symbol support, then you can configure your bundler to replace `require('has-symbols')()` with a literal `true`, which should allow dead code elimination to reduce the size of the bundled code.

## Example

```js
var iterate = require('iterate-value');
var assert = require('assert');

assert.deepEqual(iterate('a 💩'), ['a', ' ', '💩']);
assert.deepEqual(iterate([1, 2]), [1, 2]);
assert.deepEqual(iterate(new Set([1, 2])), [1, 2]);
assert.deepEqual(iterate(new Map([[1, 2], [3, 4]])), [[1, 2], [3, 4]]);

function assertWithCallback(iterable, expected) {
	var values = [];
	var callback = function (x) { values.push(x); };
	iterate(iterable, callback);
	assert.deepEqual(values, expected);
}
assertWithCallback('a 💩', ['a', ' ', '💩']);
assertWithCallback([1, 2], [1, 2]);
assertWithCallback(new Set([1, 2]), [1, 2]);
assertWithCallback(new Map([[1, 2], [3, 4]]), [[1, 2], [3, 4]]);
```

## Tests
Simply clone the repo, `npm install`, and run `npm test`

[package-url]: https://npmjs.org/package/iterate-value
[npm-version-svg]: http://versionbadg.es/ljharb/iterate-value.svg
[travis-svg]: https://travis-ci.org/ljharb/iterate-value.svg
[travis-url]: https://travis-ci.org/ljharb/iterate-value
[deps-svg]: https://david-dm.org/ljharb/iterate-value.svg
[deps-url]: https://david-dm.org/ljharb/iterate-value
[dev-deps-svg]: https://david-dm.org/ljharb/iterate-value/dev-status.svg
[dev-deps-url]: https://david-dm.org/ljharb/iterate-value#info=devDependencies
[npm-badge-png]: https://nodei.co/npm/iterate-value.png?downloads=true&stars=true
[license-image]: http://img.shields.io/npm/l/iterate-value.svg
[license-url]: LICENSE
[downloads-image]: http://img.shields.io/npm/dm/iterate-value.svg
[downloads-url]: http://npm-stat.com/charts.html?package=iterate-value
