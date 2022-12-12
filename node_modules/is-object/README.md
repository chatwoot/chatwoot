# is-object <sup>[![Version Badge][npm-version-svg]][npm-url]</sup>

[![dependency status][deps-svg]][deps-url]
[![dev dependency status][dev-deps-svg]][dev-deps-url]
[![License][license-image]][license-url]
[![Downloads][downloads-image]][downloads-url]

[![npm badge][npm-badge-png]][npm-url]

Checks whether a value is an object

Because `typeof null` is a troll.

## Example

```js
var isObject = require('is-object');
var assert = require('assert');

assert.equal(isObject(null), false);
assert.equal(isObject({}), true);
```

## Installation

`npm install is-object`

## Contributors

 - [Raynos][raynos-github]
 - [Jordan Harband][ljharb-github]

## MIT Licensed

[deps-svg]: http://david-dm.org/inspect-js/is-object/status.svg
[deps-url]: http://david-dm.org/inspect-js/is-object
[raynos-github]: https://github.com/Raynos
[ljharb-github]: https://github.com/ljharb
[dev-deps-svg]: https://david-dm.org/inspect-js/is-object/dev-status.svg
[dev-deps-url]: https://david-dm.org/inspect-js/is-object#info=devDependencies
[npm-url]: https://npmjs.org/package/is-object
[npm-version-svg]: http://versionbadg.es/inspect-js/is-object.svg
[npm-badge-png]: https://nodei.co/npm/is-object.png?downloads=true&stars=true
[license-image]: http://img.shields.io/npm/l/is-object.svg
[license-url]: LICENSE
[downloads-image]: http://img.shields.io/npm/dm/is-object.svg
[downloads-url]: http://npm-stat.com/charts.html?package=is-object

