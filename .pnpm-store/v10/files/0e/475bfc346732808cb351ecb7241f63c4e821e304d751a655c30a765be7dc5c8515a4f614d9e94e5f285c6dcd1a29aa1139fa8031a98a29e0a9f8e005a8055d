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

# Native Class

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Determine the specification defined classification of an object.

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-native-class
```

</section>

<section class="usage">

## Usage

```javascript
var nativeClass = require( '@stdlib/utils-native-class' );
```

#### nativeClass( value )

Returns a `string` value indicating a [specification defined][object-to-string] classification of an `object`.

```javascript
var str = nativeClass( 'a' );
// returns '[object String]'

str = nativeClass( 5 );
// returns '[object Number]'

function Beep() {
    return this;
}
str = nativeClass( new Beep() );
// returns '[object Object]'
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   The function is **not** robust for ES2015+ environments. In ES2015+, [`Symbol.toStringTag`][mdn-symbol-tostringtag] allows overriding the default description of an object.

    ```javascript
    var toStr = Object.prototype.toString;

    var str = toStr.call( false );
    // returns '[object Boolean]'

    var o = {};
    str = toStr.call( o );
    // returns '[object Object]'

    // Mask the default description:
    o[ Symbol.toStringTag ] = 'Boolean';

    str = toStr.call( o );
    // returns '[object Boolean]'
    ```

    While measures are taken to uncover the default description, such measures can be thwarted. While this function remains useful for type-checking, be aware that value impersonation is possible. Prefer functions tailored to checking for particular value types, as specialized functions are better equipped to address [`Symbol.toStringTag`][mdn-symbol-tostringtag].

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint-disable no-restricted-syntax, no-empty-function -->

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
var nativeClass = require( '@stdlib/utils-native-class' );

var str = nativeClass( 'a' );
// returns '[object String]'

str = nativeClass( 5 );
// returns '[object Number]'

str = nativeClass( NaN );
// returns '[object Number]'

str = nativeClass( null );
// returns '[object Null]'

str = nativeClass( void 0 );
// returns '[object Undefined]'

str = nativeClass( true );
// returns '[object Boolean]'

str = nativeClass( false );
// returns '[object Boolean]'

str = nativeClass( {} );
// returns '[object Object]'

str = nativeClass( [] );
// returns '[object Array]'

str = nativeClass( function noop() {} );
// returns '[object Function]'

str = nativeClass( /./ );
// returns '[object RegExp]'

str = nativeClass( new Date() );
// returns '[object Date]'

str = nativeClass( new Map() );
// returns '[object Map]'

str = nativeClass( new WeakMap() );
// returns '[object WeakMap]'

str = nativeClass( new Set() );
// returns '[object Set]'

str = nativeClass( new WeakSet() );
// returns '[object WeakSet]'

str = nativeClass( Symbol( 'beep' ) );
// returns '[object Symbol]'

str = nativeClass( new Error() );
// returns '[object Error]'

str = nativeClass( new TypeError() );
// returns '[object Error]'

str = nativeClass( new SyntaxError() );
// returns '[object Error]'

str = nativeClass( new URIError() );
// returns '[object Error]'

str = nativeClass( new RangeError() );
// returns '[object Error]'

str = nativeClass( new ReferenceError() );
// returns '[object Error]'

str = nativeClass( new EvalError() );
// returns '[object Error]'

str = nativeClass( new Int8Array() );
// returns '[object Int8Array]'

str = nativeClass( new Uint8Array() );
// returns '[object Uint8Array]'

str = nativeClass( new Uint8ClampedArray() );
// returns '[object Uint8ClampedArray]'

str = nativeClass( new Int16Array() );
// returns '[object Int16Array]'

str = nativeClass( new Uint16Array() );
// returns '[object Uint16Array]'

str = nativeClass( new Int32Array() );
// returns '[object Int32Array]'

str = nativeClass( new Uint32Array() );
// returns '[object Uint32Array]'

str = nativeClass( new Float32Array() );
// returns '[object Float32Array]'

str = nativeClass( new Float64Array() );
// returns '[object Float64Array]'

str = nativeClass( new ArrayBuffer() );
// returns '[object ArrayBuffer]'

str = nativeClass( Math );
// returns '[object Math]'

str = nativeClass( JSON );
// returns '[object JSON]'

function Person() {
    return this;
}
str = nativeClass( new Person() );
// returns '[object Object]'
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/utils/constructor-name`][@stdlib/utils/constructor-name]</span><span class="delimiter">: </span><span class="description">determine the name of a value's constructor.</span>
-   <span class="package-name">[`@stdlib/utils/type-of`][@stdlib/utils/type-of]</span><span class="delimiter">: </span><span class="description">determine a value's type.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-native-class.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-native-class

[test-image]: https://github.com/stdlib-js/utils-native-class/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/utils-native-class/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-native-class/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-native-class?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-native-class.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-native-class/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-native-class/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-native-class/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-native-class/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/utils-native-class/main/LICENSE

[object-to-string]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/toString

[mdn-symbol-tostringtag]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol/toStringTag

<!-- <related-links> -->

[@stdlib/utils/constructor-name]: https://www.npmjs.com/package/@stdlib/utils-constructor-name

[@stdlib/utils/type-of]: https://www.npmjs.com/package/@stdlib/utils-type-of

<!-- </related-links> -->

</section>

<!-- /.links -->
