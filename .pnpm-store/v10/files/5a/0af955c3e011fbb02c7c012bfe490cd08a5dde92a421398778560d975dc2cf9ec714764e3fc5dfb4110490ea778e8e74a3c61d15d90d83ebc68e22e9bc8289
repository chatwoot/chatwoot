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

# Array Function

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Return a function which tests if every element in an array passes a test condition.

<section class="installation">

## Installation

```bash
npm install @stdlib/assert-tools-array-function
```

</section>

<section class="usage">

## Usage

```javascript
var arrayfcn = require( '@stdlib/assert-tools-array-function' );
```

<a name="arrayfcn"></a>

#### arrayfcn( predicate )

Returns a function which tests if every element in an [`array`][mdn-array] passes a test condition. Given an input [`array`][mdn-array], the function returns `true` if all elements pass the test and `false` otherwise.

```javascript
var isOdd = require( '@stdlib/assert-is-odd' );

var arr1 = [ 1, 3, 5, 7 ];
var arr2 = [ 3, 5, 8 ];

var f = arrayfcn( isOdd );

var bool = f( arr1 );
// returns true

bool = f( arr2 );
// returns false
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   The returned function will return `false` if **not** provided an [`array`][mdn-array].
-   The returned function will return `false` if provided an empty [`array`][mdn-array].
-   A `predicate` function should accept a single argument: an [`array`][mdn-array] element. If the [`array`][mdn-array] element satisfies a test condition, the `predicate` function should return `true`; otherwise, the `predicate` function should return `false`.

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var isEven = require( '@stdlib/assert-is-even' );
var arrayfcn = require( '@stdlib/assert-tools-array-function' );

var arr1;
var arr2;
var bool;
var f;
var i;

arr1 = new Array( 25 );
for ( i = 0; i < arr1.length; i++ ) {
    arr1[ i ] = i;
}

arr2 = new Array( 25 );
for ( i = 0; i < arr2.length; i++ ) {
    arr2[ i ] = 2 * i;
}

f = arrayfcn( isEven );

bool = f( arr1 );
// returns false

bool = f( arr2 );
// returns true
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/assert-tools-array-function.svg
[npm-url]: https://npmjs.org/package/@stdlib/assert-tools-array-function

[test-image]: https://github.com/stdlib-js/assert-tools-array-function/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/assert-tools-array-function/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/assert-tools-array-function/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/assert-tools-array-function?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/assert-tools-array-function.svg
[dependencies-url]: https://david-dm.org/stdlib-js/assert-tools-array-function/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/assert-tools-array-function/tree/deno
[umd-url]: https://github.com/stdlib-js/assert-tools-array-function/tree/umd
[esm-url]: https://github.com/stdlib-js/assert-tools-array-function/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/assert-tools-array-function/main/LICENSE

[mdn-array]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array

</section>

<!-- /.links -->
