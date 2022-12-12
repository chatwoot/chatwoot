# iterate-iterator <sup>[![Version Badge][npm-version-svg]][package-url]</sup>

[![Build Status][travis-svg]][travis-url]
[![dependency status][deps-svg]][deps-url]
[![dev dependency status][dev-deps-svg]][dev-deps-url]
[![License][license-image]][license-url]
[![Downloads][downloads-image]][downloads-url]

[![npm badge][npm-badge-png]][package-url]

Iterate any iterable JS iterator. Works robustly in all environments, all versions.

In modern engines, `[...value]` or `Array.from(value)` or `for (const item of value) { }` are sufficient to iterate an iterable value (an object with a `Symbol.iterator` method), which includes all builtin iterators. However, older engines:
 - may lack `Symbol`, array spread, or `for..of` support altogether
 - may have `Symbol.iterator` but not implement it on everything it should, like arguments objects
 - may have `Map` and `Set`, but a non-standard name for the iterator-producing method (`.iterator` or `['@@iterator']`, eg) and no syntax to support it
 - may be old versions of Firefox that produce values until they throw a StopIteration exception, rather than having iteration result objects
 - may be polyfilled/shimmed/shammed, with `es6-shim` or `core-js` or similar

This library simplifies iterating an iterator object, so no loops are required.

If called with a single iterator, it will return an array of the yielded values. If also called with a callback function, it will instead call that callback once for each yielded value.

## Example

```js
var iterate = require('iterate-iterator');
var getIterator = require('es-get-iterator');
var assert = require('assert');

assert.deepEqual(iterate(getIterator('a 💩')), ['a', ' ', '💩']);
assert.deepEqual(iterate(getIterator([1, 2])), [1, 2]);
assert.deepEqual(iterate(getIterator(new Set([1, 2]))), [1, 2]);
assert.deepEqual(iterate(getIterator(new Map([[1, 2], [3, 4]]))), [[1, 2], [3, 4]]);

function assertWithCallback(iterable, expected) {
	var values = [];
	var callback = function (x) { values.push(x); };
	iterate(iterable, callback);
	assert.deepEqual(values, expected);
}
assertWithCallback(getIterator('a 💩'), ['a', ' ', '💩']);
assertWithCallback(getIterator([1, 2]), [1, 2]);
assertWithCallback(getIterator(new Set([1, 2])), [1, 2]);
assertWithCallback(getIterator(new Map([[1, 2], [3, 4]])), [[1, 2], [3, 4]]);
```

## Tests
Simply clone the repo, `npm install`, and run `npm test`

[package-url]: https://npmjs.org/package/iterate-iterator
[npm-version-svg]: http://versionbadg.es/ljharb/iterate-iterator.svg
[travis-svg]: https://travis-ci.org/ljharb/iterate-iterator.svg
[travis-url]: https://travis-ci.org/ljharb/iterate-iterator
[deps-svg]: https://david-dm.org/ljharb/iterate-iterator.svg
[deps-url]: https://david-dm.org/ljharb/iterate-iterator
[dev-deps-svg]: https://david-dm.org/ljharb/iterate-iterator/dev-status.svg
[dev-deps-url]: https://david-dm.org/ljharb/iterate-iterator#info=devDependencies
[npm-badge-png]: https://nodei.co/npm/iterate-iterator.png?downloads=true&stars=true
[license-image]: http://img.shields.io/npm/l/iterate-iterator.svg
[license-url]: LICENSE
[downloads-image]: http://img.shields.io/npm/dm/iterate-iterator.svg
[downloads-url]: http://npm-stat.com/charts.html?package=iterate-iterator
