# function.prototype.name <sup>[![Version Badge][2]][1]</sup>

[![dependency status][5]][6]
[![dev dependency status][7]][8]
[![License][license-image]][license-url]
[![Downloads][downloads-image]][downloads-url]

[![npm badge][11]][1]

An ES2015 spec-compliant `Function.prototype.name` shim. Invoke its "shim" method to shim Function.prototype.name if it is unavailable.
*Note*: `Function#name` requires a true ES5 environment - specifically, one with ES5 getters.

This package implements the [es-shim API](https://github.com/es-shims/api) interface. It works in an ES5-supported environment and complies with the [spec](https://www.ecma-international.org/ecma-262/6.0/#sec-get-regexp.prototype.flags).

Most common usage:

## Example

```js
var functionName = require('function.prototype.name');
var assert = require('assert');

assert.equal(functionName(function foo() {}), 'foo');

functionName.shim();
assert.equal(function foo() {}.name, 'foo');
```

## Tests
Simply clone the repo, `npm install`, and run `npm test`

[1]: https://npmjs.org/package/function.prototype.name
[2]: https://versionbadg.es/es-shims/Function.prototype.name.svg
[5]: https://david-dm.org/es-shims/Function.prototype.name.svg
[6]: https://david-dm.org/es-shims/Function.prototype.name
[7]: https://david-dm.org/es-shims/Function.prototype.name/dev-status.svg
[8]: https://david-dm.org/es-shims/Function.prototype.name#info=devDependencies
[11]: https://nodei.co/npm/function.prototype.name.png?downloads=true&stars=true
[license-image]: https://img.shields.io/npm/l/function.prototype.name.svg
[license-url]: LICENSE
[downloads-image]: https://img.shields.io/npm/dm/function.prototype.name.svg
[downloads-url]: https://npm-stat.com/charts.html?package=function.prototype.name
