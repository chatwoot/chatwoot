<!--

@license Apache-2.0

Copyright (c) 2018 The Stdlib Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-->

# Constructor Name

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Determine the name of a value's constructor.

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-constructor-name
```

</section>

<section class="usage">

## Usage

```javascript
var constructorName = require( '@stdlib/utils-constructor-name' );
```

#### constructorName( value )

Returns the name of a value's constructor.

```javascript
var v = constructorName( 'a' );
// returns 'String'

v = constructorName( 5 );
// returns 'Number'

function Beep() {
    return this;
}
v = constructorName( new Beep() );
// returns 'Beep'
```

| description           | value                               | constructor           | notes        |
| --------------------- | ----------------------------------- | --------------------- | ------------ |
| string                | `'beep'`                            | `'String'`            |              |
| number                | `5`                                 | `'Number'`            |              |
| NaN                   | `NaN`                               | `'Number'`            |              |
| infinity              | `+infinity`/`-infinity`             | `'Number'`            |              |
| boolean               | `true`/`false`                      | `'Boolean'`           |              |
| null                  | `null`                              | `'Null'`              |              |
| undefined             | `undefined`                         | `'Undefined'`         |              |
| array                 | `['beep', 5]`                       | `'Array'`             |              |
| object                | `{'foo': 'bar'}`                    | `'Object'`            |              |
| function              | `function (){}`                     | `'Function'`          |              |
| symbol                | `Symbol()`                          | `'Symbol'`            | ES2015       |
| regexp                | `/./`                               | `'RegExp'`            | Android 4.1+ |
| String                | `new String('beep')`                | `'String'`            |              |
| Number                | `new Number(5)`                     | `'Number'`            |              |
| Boolean               | `new Boolean(false)`                | `'Boolean'`           |              |
| Object                | `new Object()`                      | `'Object'`            |              |
| Array                 | `new Array()`                       | `'Array'`             |              |
| Int8Array             | `new Int8Array()`                   | `'Int8Array'`         |              |
| Uint8Array            | `new Uint8Array()`                  | `'Uint8Array'`        |              |
| Uint8ClampedArray     | `new Uint8ClampedArray()`           | `'Uint8ClampedArray'` |              |
| Int16Array            | `new Int16Array()`                  | `'Int16Array'`        |              |
| Uint16Array           | `new Uint16Array()`                 | `'Uint16Array'`       |              |
| Int32Array            | `new Int32Array()`                  | `'Int32Array'`        |              |
| Uint32Array           | `new Uint32Array()`                 | `'Uint32Array'`       |              |
| Float32Array          | `new Float32Array()`                | `'Float32Array'`      |              |
| Float64Array          | `new Float64Array()`                | `'Float64Array'`      |              |
| ArrayBuffer           | `new ArrayBuffer()`                 | `'ArrayBuffer'`       |              |
| Buffer                | `new Buffer()`                      | `'Buffer'`            | Node.js      |
| Date                  | `new Date()`                        | `'Date'`              |              |
| RegExp                | `new RegExp('.')`                   | `'RegExp'`            | Android 4.1+ |
| Function              | `new Function('x', 'return x')`     | `'Function'`          |              |
| Map                   | `new Map()`                         | `'Map'`               | ES2015       |
| WeakMap               | `new WeakMap()`                     | `'WeakMap'`           | ES2015       |
| Set                   | `new Set()`                         | `'Set'`               | ES2015       |
| WeakSet               | `new WeakSet()`                     | `'WeakSet'`           | ES2015       |
| Error                 | `new Error()`                       | `'Error'`             |              |
| TypeError             | `new TypeError()`                   | `'TypeError'`         |              |
| SyntaxError           | `new SyntaxError()`                 | `'SyntaxError'`       |              |
| ReferenceError        | `new ReferenceError()`              | `'ReferenceError'`    |              |
| URIError              | `new URIError()`                    | `'URIError'`          |              |
| RangeError            | `new RangeError()`                  | `'RangeError'`        |              |
| EvalError             | `new EvalError()`                   | `'EvalError'`         |              |
| Math                  | `Math`                              | `'Math'`              |              |
| JSON                  | `JSON`                              | `'JSON'`              | IE8+         |
| arguments             | `(function(){return arguments;})()` | `'Arguments'`         | IE9+         |
| custom constructor    | `new Beep()`                        | `'Beep'`              |              |
| anonymous constructor | `new (function(){})()`              | `''`                  |              |

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   If a value's constructor is an anonymous `function`, the implementation returns an empty `string`.

    <!-- eslint-disable no-restricted-syntax, func-style, func-names -->

    ```javascript
    var Beep = function () {
        return this;
    };

    var v = constructorName( new Beep() );
    // returns ''
    ```

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- TODO: update once have Buffer wrapper -->

<!-- eslint no-undef: "error" -->

<!-- eslint-disable no-restricted-syntax, no-buffer-constructor, func-style, func-names -->

```javascript
var Float32Array = require( '@stdlib/array-float32' );
var Float64Array = require( '@stdlib/array-float64' );
var Int8Array = require( '@stdlib/array-int8' );
var Int16Array = require( '@stdlib/array-int16' );
var Int32Array = require( '@stdlib/array-int32' );
var Uint8Array = require( '@stdlib/array-uint8' );
var Uint8ClampedArray = require( '@stdlib/array-uint8c' );
var Uint16Array = require( '@stdlib/array-uint16' );
var Uint32Array = require( '@stdlib/array-uint32' );
var ArrayBuffer = require( '@stdlib/array-buffer' );
var Buffer = require( '@stdlib/buffer-ctor' );
var Symbol = require( '@stdlib/symbol-ctor' );
var constructorName = require( '@stdlib/utils-constructor-name' );

function noop() {
    // Do nothing...
}

var v = constructorName( 'a' );
// returns 'String'

v = constructorName( 5 );
// returns 'Number'

v = constructorName( NaN );
// returns 'Number'

v = constructorName( null );
// returns 'Null'

v = constructorName( void 0 );
// returns 'Undefined'

v = constructorName( true );
// returns 'Boolean'

v = constructorName( false );
// returns 'Boolean'

v = constructorName( {} );
// returns 'Object'

v = constructorName( [] );
// returns 'Array'

v = constructorName( noop );
// returns 'Function'

v = constructorName( /./ );
// returns 'RegExp'

v = constructorName( new Date() );
// returns 'Date'

v = constructorName( new Map() );
// returns 'Map'

v = constructorName( new WeakMap() );
// returns 'WeakMap'

v = constructorName( new Set() );
// returns 'Set'

v = constructorName( new WeakSet() );
// returns 'WeakSet'

v = constructorName( Symbol( 'beep' ) );
// returns 'Symbol'

v = constructorName( new Error() );
// returns 'Error'

v = constructorName( new TypeError() );
// returns 'TypeError'

v = constructorName( new SyntaxError() );
// returns 'SyntaxError'

v = constructorName( new URIError() );
// returns 'URIError'

v = constructorName( new RangeError() );
// returns 'RangeError'

v = constructorName( new ReferenceError() );
// returns 'ReferenceError'

v = constructorName( new EvalError() );
// returns 'EvalError'

v = constructorName( new Int8Array() );
// returns 'Int8Array'

v = constructorName( new Uint8Array() );
// returns 'Uint8Array'

v = constructorName( new Uint8ClampedArray() );
// returns 'Uint8ClampedArray'

v = constructorName( new Int16Array() );
// returns 'Int16Array'

v = constructorName( new Uint16Array() );
// returns 'Uint16Array'

v = constructorName( new Int32Array() );
// returns 'Int32Array'

v = constructorName( new Uint32Array() );
// returns 'Uint32Array'

v = constructorName( new Float32Array() );
// returns 'Float32Array'

v = constructorName( new Float64Array() );
// returns 'Float64Array'

v = constructorName( new ArrayBuffer() );
// returns 'ArrayBuffer'

v = constructorName( new Buffer( 'beep' ) );
// returns 'Buffer'

v = constructorName( Math );
// returns 'Math'

v = constructorName( JSON );
// returns 'JSON'

function Person1() {
    return this;
}
v = constructorName( new Person1() );
// returns 'Person1'

var Person2 = function () {
    return this;
};
v = constructorName( new Person2() );
// returns ''
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/utils/function-name`][@stdlib/utils/function-name]</span><span class="delimiter">: </span><span class="description">determine a function's name.</span>

</section>

<!-- /.related -->

<!-- Section for all links. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->


<section class="main-repo" >

* * *

## Notice

This package is part of [stdlib][stdlib], a standard library for JavaScript and Node.js, with an emphasis on numerical and scientific computing. The library provides a collection of robust, high performance libraries for mathematics, statistics, streams, utilities, and more.

For more information on the project, filing bug reports and feature requests, and guidance on how to develop [stdlib][stdlib], see the main project [repository][stdlib].

#### Community

[![Chat][chat-image]][chat-url]

---

## License

See [LICENSE][stdlib-license].


## Copyright

Copyright &copy; 2016-2022. The Stdlib [Authors][stdlib-authors].

</section>

<!-- /.stdlib -->

<!-- Section for all links. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="links">

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-constructor-name.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-constructor-name

[test-image]: https://github.com/stdlib-js/utils-constructor-name/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/utils-constructor-name/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-constructor-name/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-constructor-name?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-constructor-name.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-constructor-name/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-constructor-name/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-constructor-name/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-constructor-name/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/utils-constructor-name/main/LICENSE

<!-- <related-links> -->

[@stdlib/utils/function-name]: https://www.npmjs.com/package/@stdlib/utils-function-name

<!-- </related-links> -->

</section>

<!-- /.links -->
