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

# toFloat32

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Convert a [double-precision floating-point number][ieee754] to the nearest [single-precision floating-point number][ieee754].

<section class="installation">

## Installation

```bash
npm install @stdlib/number-float64-base-to-float32
```

</section>

<section class="usage">

## Usage

```javascript
var float64ToFloat32 = require( '@stdlib/number-float64-base-to-float32' );
```

#### float64ToFloat32( x )

Converts a [double-precision floating-point number][ieee754] to the nearest [single-precision floating-point number][ieee754].

```javascript
var y = float64ToFloat32( 1.337 );
// returns 1.3370000123977661
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   This function may be used as a polyfill for the ES2015 built-in [`Math.fround`][math-fround].

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var randu = require( '@stdlib/random-base-randu' );
var float64ToFloat32 = require( '@stdlib/number-float64-base-to-float32' );

var f64;
var f32;
var i;

// Convert random double-precision floating-point numbers to the nearest single-precision floating-point number...
for ( i = 0; i < 1000; i++ ) {
    f64 = randu() * 100.0;
    f32 = float64ToFloat32( f64 );
    console.log( 'float64: %d => float32: %d', f64, f32 );
}
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

[npm-image]: http://img.shields.io/npm/v/@stdlib/number-float64-base-to-float32.svg
[npm-url]: https://npmjs.org/package/@stdlib/number-float64-base-to-float32

[test-image]: https://github.com/stdlib-js/number-float64-base-to-float32/actions/workflows/test.yml/badge.svg?branch=v0.0.7
[test-url]: https://github.com/stdlib-js/number-float64-base-to-float32/actions/workflows/test.yml?query=branch:v0.0.7

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/number-float64-base-to-float32/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/number-float64-base-to-float32?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/number-float64-base-to-float32.svg
[dependencies-url]: https://david-dm.org/stdlib-js/number-float64-base-to-float32/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/number-float64-base-to-float32/tree/deno
[umd-url]: https://github.com/stdlib-js/number-float64-base-to-float32/tree/umd
[esm-url]: https://github.com/stdlib-js/number-float64-base-to-float32/tree/esm
[branches-url]: https://github.com/stdlib-js/number-float64-base-to-float32/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/number-float64-base-to-float32/main/LICENSE

[ieee754]: https://en.wikipedia.org/wiki/IEEE_754-1985

[math-fround]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/fround

</section>

<!-- /.links -->
