# functions-have-names <sup>[![Version Badge][2]][1]</sup>

[![dependency status][5]][6]
[![dev dependency status][7]][8]
[![License][license-image]][license-url]
[![Downloads][downloads-image]][downloads-url]

[![npm badge][11]][1]

Does this JS environment support the `name` property on functions?

## Example

```js
var functionsHaveNames = require('functions-have-names');
var assert = require('assert');

assert.equal(functionsHaveNames(), true); // will be `false` in IE 6-8
```

## Tests
Simply clone the repo, `npm install`, and run `npm test`

[1]: https://npmjs.org/package/functions-have-names
[2]: https://versionbadg.es/inspect-js/functions-have-names.svg
[5]: https://david-dm.org/inspect-js/functions-have-names.svg
[6]: https://david-dm.org/inspect-js/functions-have-names
[7]: https://david-dm.org/inspect-js/functions-have-names/dev-status.svg
[8]: https://david-dm.org/inspect-js/functions-have-names#info=devDependencies
[11]: https://nodei.co/npm/functions-have-names.png?downloads=true&stars=true
[license-image]: https://img.shields.io/npm/l/functions-have-names.svg
[license-url]: LICENSE
[downloads-image]: https://img.shields.io/npm/dm/functions-have-names.svg
[downloads-url]: https://npm-stat.com/charts.html?package=functions-have-names
