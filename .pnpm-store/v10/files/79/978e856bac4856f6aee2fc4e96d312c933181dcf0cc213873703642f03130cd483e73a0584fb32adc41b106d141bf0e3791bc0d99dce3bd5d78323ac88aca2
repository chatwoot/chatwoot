# safe-regex-test <sup>[![Version Badge][npm-version-svg]][package-url]</sup>

[![dependency status][deps-svg]][deps-url]
[![dev dependency status][dev-deps-svg]][dev-deps-url]
[![License][license-image]][license-url]
[![Downloads][downloads-image]][downloads-url]

[![npm badge][npm-badge-png]][package-url]

Give a regex, get a robust predicate function that tests it against a string. This will work even if `RegExp.prototype` is altered later.

## Getting started

```sh
npm install --save safe-regex-test
```

## Usage/Examples

```js
var regexTester = require('safe-regex-test');
var assert = require('assert');

var tester = regexTester('a');
assert.ok(tester('a'));
assert.notOk(tester('b'));
```

## Tests
Simply clone the repo, `npm install`, and run `npm test`

[package-url]: https://npmjs.org/package/safe-regex-test
[npm-version-svg]: https://versionbadg.es/ljharb/safe-regex-test.svg
[deps-svg]: https://david-dm.org/ljharb/safe-regex-test.svg
[deps-url]: https://david-dm.org/ljharb/safe-regex-test
[dev-deps-svg]: https://david-dm.org/ljharb/safe-regex-test/dev-status.svg
[dev-deps-url]: https://david-dm.org/ljharb/safe-regex-test#info=devDependencies
[npm-badge-png]: https://nodei.co/npm/safe-regex-test.png?downloads=true&stars=true
[license-image]: https://img.shields.io/npm/l/safe-regex-test.svg
[license-url]: LICENSE
[downloads-image]: https://img.shields.io/npm/dm/safe-regex-test.svg
[downloads-url]: https://npm-stat.com/charts.html?package=safe-regex-test
