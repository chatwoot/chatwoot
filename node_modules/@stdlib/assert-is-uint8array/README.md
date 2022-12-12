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

# isUint8Array

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Test if a value is a [Uint8Array][mdn-uint8array].

<section class="installation">

## Installation

```bash
npm install @stdlib/assert-is-uint8array
```

</section>

<section class="usage">

## Usage

```javascript
var isUint8Array = require( '@stdlib/assert-is-uint8array' );
```

#### isUint8Array( value )

Tests if a value is a [`Uint8Array`][mdn-uint8array].

```javascript
var Uint8Array = require( '@stdlib/array-uint8' );

var bool = isUint8Array( new Uint8Array( 10 ) );
// returns true

bool = isUint8Array( [] );
// returns false
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var Int8Array = require( '@stdlib/array-int8' );
var Uint8Array = require( '@stdlib/array-uint8' );
var Uint8ClampedArray = require( '@stdlib/array-uint8c' );
var Int16Array = require( '@stdlib/array-int16' );
var Uint16Array = require( '@stdlib/array-uint16' );
var Int32Array = require( '@stdlib/array-int32' );
var Uint32Array = require( '@stdlib/array-uint32' );
var Float32Array = require( '@stdlib/array-float32' );
var Float64Array = require( '@stdlib/array-float64' );
var isUint8Array = require( '@stdlib/assert-is-uint8array' );

var bool = isUint8Array( new Uint8Array( 10 ) );
// returns true

bool = isUint8Array( new Int8Array( 10 ) );
// returns false

bool = isUint8Array( new Uint8ClampedArray( 10 ) );
// returns false

bool = isUint8Array( new Int16Array( 10 ) );
// returns false

bool = isUint8Array( new Uint16Array( 10 ) );
// returns false

bool = isUint8Array( new Int32Array( 10 ) );
// returns false

bool = isUint8Array( new Uint32Array( 10 ) );
// returns false

bool = isUint8Array( new Float32Array( 10 ) );
// returns false

bool = isUint8Array( new Float64Array( 10 ) );
// returns false

bool = isUint8Array( new Array( 10 ) );
// returns false

bool = isUint8Array( {} );
// returns false

bool = isUint8Array( null );
// returns false
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/assert/is-typed-array`][@stdlib/assert/is-typed-array]</span><span class="delimiter">: </span><span class="description">test if a value is a typed array.</span>
-   <span class="package-name">[`@stdlib/assert/is-uint16array`][@stdlib/assert/is-uint16array]</span><span class="delimiter">: </span><span class="description">test if a value is a Uint16Array.</span>
-   <span class="package-name">[`@stdlib/assert/is-uint32array`][@stdlib/assert/is-uint32array]</span><span class="delimiter">: </span><span class="description">test if a value is a Uint32Array.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/assert-is-uint8array.svg
[npm-url]: https://npmjs.org/package/@stdlib/assert-is-uint8array

[test-image]: https://github.com/stdlib-js/assert-is-uint8array/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/assert-is-uint8array/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/assert-is-uint8array/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/assert-is-uint8array?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/assert-is-uint8array.svg
[dependencies-url]: https://david-dm.org/stdlib-js/assert-is-uint8array/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/assert-is-uint8array/tree/deno
[umd-url]: https://github.com/stdlib-js/assert-is-uint8array/tree/umd
[esm-url]: https://github.com/stdlib-js/assert-is-uint8array/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/assert-is-uint8array/main/LICENSE

[mdn-uint8array]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint8Array

<!-- <related-links> -->

[@stdlib/assert/is-typed-array]: https://www.npmjs.com/package/@stdlib/assert-is-typed-array

[@stdlib/assert/is-uint16array]: https://www.npmjs.com/package/@stdlib/assert-is-uint16array

[@stdlib/assert/is-uint32array]: https://www.npmjs.com/package/@stdlib/assert-is-uint32array

<!-- </related-links> -->

</section>

<!-- /.links -->
