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

# typeOf

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Determine a value's type.

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-type-of
```

</section>

<section class="usage">

## Usage

```javascript
var typeOf = require( '@stdlib/utils-type-of' );
```

#### typeOf( value )

Returns a value's type.

```javascript
var str = typeOf( 'a' );
// returns 'string'

str = typeOf( 5 );
// returns 'number'
```

| description           | value                               | type                  | notes        |
| --------------------- | ----------------------------------- | --------------------- | ------------ |
| string                | `'beep'`                            | `'string'`            |              |
| number                | `5`                                 | `'number'`            |              |
| NaN                   | `NaN`                               | `'number'`            |              |
| infinity              | `+infinity`/`-infinity`             | `'number'`            |              |
| boolean               | `true`/`false`                      | `'boolean'`           |              |
| null                  | `null`                              | `'null'`              |              |
| undefined             | `undefined`                         | `'undefined'`         |              |
| array                 | `['beep', 5]`                       | `'array'`             |              |
| object                | `{'foo': 'bar'}`                    | `'object'`            |              |
| function              | `function (){}`                     | `'function'`          |              |
| symbol                | `Symbol()`                          | `'symbol'`            | ES2015       |
| regexp                | `/./`                               | `'regexp'`            | Android 4.1+ |
| String                | `new String('beep')`                | `'string'`            |              |
| Number                | `new Number(5)`                     | `'number'`            |              |
| Boolean               | `new Boolean(false)`                | `'boolean'`           |              |
| Object                | `new Object()`                      | `'object'`            |              |
| Array                 | `new Array()`                       | `'array'`             |              |
| Int8Array             | `new Int8Array()`                   | `'int8array'`         |              |
| Uint8Array            | `new Uint8Array()`                  | `'uint8array'`        |              |
| Uint8ClampedArray     | `new Uint8ClampedArray()`           | `'uint8clampedarray'` |              |
| Int16Array            | `new Int16Array()`                  | `'int16array'`        |              |
| Uint16Array           | `new Uint16Array()`                 | `'uint16array'`       |              |
| Int32Array            | `new Int32Array()`                  | `'int32array'`        |              |
| Uint32Array           | `new Uint32Array()`                 | `'uint32array'`       |              |
| Float32Array          | `new Float32Array()`                | `'float32array'`      |              |
| Float64Array          | `new Float64Array()`                | `'float64array'`      |              |
| ArrayBuffer           | `new ArrayBuffer()`                 | `'arraybuffer'`       |              |
| Buffer                | `new Buffer()`                      | `'buffer'`            | Node.js      |
| Date                  | `new Date()`                        | `'date'`              |              |
| RegExp                | `new RegExp('.')`                   | `'regexp'`            | Android 4.1+ |
| Function              | `new Function('x', 'return x')`     | `'function'`          |              |
| Map                   | `new Map()`                         | `'map'`               | ES2015       |
| WeakMap               | `new WeakMap()`                     | `'weakmap'`           | ES2015       |
| Set                   | `new Set()`                         | `'set'`               | ES2015       |
| WeakSet               | `new WeakSet()`                     | `'weakset'`           | ES2015       |
| Error                 | `new Error()`                       | `'error'`             |              |
| TypeError             | `new TypeError()`                   | `'typeerror'`         |              |
| SyntaxError           | `new SyntaxError()`                 | `'syntaxerror'`       |              |
| ReferenceError        | `new ReferenceError()`              | `'referenceerror'`    |              |
| URIError              | `new URIError()`                    | `'urierror'`          |              |
| RangeError            | `new RangeError()`                  | `'rangeerror'`        |              |
| EvalError             | `new EvalError()`                   | `'evalerror'`         |              |
| Math                  | `Math`                              | `'math'`              |              |
| JSON                  | `JSON`                              | `'json'`              | IE8+         |
| arguments             | `(function(){return arguments;})()` | `'arguments'`         | IE9+         |
| custom constructor    | `new Beep()`                        | `'beep'`              |              |
| anonymous constructor | `new (function(){})()`              | `''`                  |              |

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- eslint-disable no-restricted-syntax, no-empty-function, func-names, func-style -->

<!-- eslint no-undef: "error" -->

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
var Symbol = require( '@stdlib/symbol-ctor' );
var typeOf = require( '@stdlib/utils-type-of' );

var str = typeOf( 'a' );
// returns 'string'

str = typeOf( 5 );
// returns 'number'

str = typeOf( NaN );
// returns 'number'

str = typeOf( Infinity );
// returns 'number'

str = typeOf( true );
// returns 'boolean'

str = typeOf( false );
// returns 'boolean'

str = typeOf( void 0 );
// returns 'undefined'

str = typeOf( null );
// returns 'null'

str = typeOf( [] );
// returns 'array'

str = typeOf( {} );
// returns 'object'

str = typeOf( function noop() {} );
// returns 'function'

str = typeOf( new Map() );
// returns 'map'

str = typeOf( new WeakMap() );
// returns 'weakmap'

str = typeOf( new Set() );
// returns 'set'

str = typeOf( new WeakSet() );
// returns 'weakset'

str = typeOf( Symbol( 'beep' ) );
// returns 'symbol'

str = typeOf( new Error( 'beep' ) );
// returns 'error'

str = typeOf( new TypeError( 'beep' ) );
// returns 'typeerror'

str = typeOf( new SyntaxError( 'beep' ) );
// returns 'syntaxerror'

str = typeOf( new ReferenceError( 'beep' ) );
// returns 'referenceerror'

str = typeOf( new URIError( 'beep' ) );
// returns 'urierror'

str = typeOf( new EvalError( 'beep' ) );
// returns 'evalerror'

str = typeOf( new RangeError( 'beep' ) );
// returns 'rangeerror'

str = typeOf( new Date() );
// returns 'date'

str = typeOf( /./ );
// returns 'regexp'

str = typeOf( Math );
// returns 'math'

str = typeOf( JSON );
// returns 'json'

str = typeOf( new Int8Array( 10 ) );
// returns 'int8array'

str = typeOf( new Uint8Array( 10 ) );
// returns 'uint8array'

str = typeOf( new Int16Array( 10 ) );
// returns 'int16array'

str = typeOf( new Uint16Array( 10 ) );
// returns 'uint16array'

str = typeOf( new Int32Array( 10 ) );
// returns 'int32array'

str = typeOf( new Uint32Array( 10 ) );
// returns 'uint32array'

str = typeOf( new Float32Array( 10 ) );
// returns 'float32array'

str = typeOf( new Float64Array( 10 ) );
// returns 'float64array'

str = typeOf( new ArrayBuffer( 10 ) );
// returns 'arraybuffer'

function Person1() {
    return this;
}
str = typeOf( new Person1() );
// returns 'person1'

var Person2 = function () {
    return this;
};
str = typeOf( new Person2() );
// returns ''
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/utils/constructor-name`][@stdlib/utils/constructor-name]</span><span class="delimiter">: </span><span class="description">determine the name of a value's constructor.</span>
-   <span class="package-name">[`@stdlib/utils/native-class`][@stdlib/utils/native-class]</span><span class="delimiter">: </span><span class="description">determine the specification defined classification of an object.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-type-of.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-type-of

[test-image]: https://github.com/stdlib-js/utils-type-of/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/utils-type-of/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-type-of/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-type-of?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-type-of.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-type-of/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-type-of/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-type-of/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-type-of/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/utils-type-of/main/LICENSE

<!-- <related-links> -->

[@stdlib/utils/constructor-name]: https://www.npmjs.com/package/@stdlib/utils-constructor-name

[@stdlib/utils/native-class]: https://www.npmjs.com/package/@stdlib/utils-native-class

<!-- </related-links> -->

</section>

<!-- /.links -->
