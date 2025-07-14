<!--

@license Apache-2.0

Copyright (c) 2022 The Stdlib Authors.

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

# FLOAT64_HIGH_WORD_SIGN_MASK

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> High word mask for the sign bit of a [double-precision floating-point number][ieee754].

<section class="installation">

## Installation

```bash
npm install @stdlib/constants-float64-high-word-sign-mask
```

</section>

<section class="usage">

## Usage

<!-- eslint-disable id-length -->

```javascript
var FLOAT64_HIGH_WORD_SIGN_MASK = require( '@stdlib/constants-float64-high-word-sign-mask' );
```

#### FLOAT64_HIGH_WORD_SIGN_MASK

High word mask for the sign bit of a [double-precision floating-point number][ieee754].

<!-- eslint-disable id-length -->

```javascript
// 0x80000000 = 2147483648 => 1 00000000000 00000000000000000000
var bool = ( FLOAT64_HIGH_WORD_SIGN_MASK === 0x80000000 );
// returns true
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   The higher order word of a [double-precision floating-point number][ieee754] is a 32-bit integer containing the more significant bits which include the exponent and sign.

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint-disable id-length -->

<!-- eslint no-undef: "error" -->

```javascript
var getHighWord = require( '@stdlib/number-float64-base-get-high-word' );
var getLowWord = require( '@stdlib/number-float64-base-get-low-word' );
var fromWords = require( '@stdlib/number-float64-base-from-words' );
var FLOAT64_HIGH_WORD_SIGN_MASK = require( '@stdlib/constants-float64-high-word-sign-mask' );

var x = -11.5;
var hi = getHighWord( x ); // 1 10000000010 01110000000000000000
// returns 3223781376

// Mask off all bits except for the sign bit:
var out = (hi & FLOAT64_HIGH_WORD_SIGN_MASK)>>>0; // 1 00000000000 00000000000000000000
// returns 2147483648

// Turn off the sign bit and leave other bits unchanged:
out = hi & (~FLOAT64_HIGH_WORD_SIGN_MASK); // 0 10000000010 01110000000000000000
// returns 1076297728

// Generate a new value:
out = fromWords( out, getLowWord( x ) );
// returns 11.5
```

</section>

<!-- /.examples -->

<!-- C interface documentation. -->

* * *

<section class="c">

## C APIs

<!-- Section to include introductory text. Make sure to keep an empty line after the intro `section` element and another before the `/section` close. -->

<section class="intro">

</section>

<!-- /.intro -->

<!-- C usage documentation. -->

<section class="usage">

### Usage

```c
#include "stdlib/constants/float64/high_word_sign_mask.h"
```

#### STDLIB_CONSTANT_FLOAT64_HIGH_WORD_SIGN_MASK

Macro for the high word mask for the sign bit of a [double-precision floating-point number][ieee754].

</section>

<!-- /.usage -->

<!-- C API usage notes. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="notes">

</section>

<!-- /.notes -->

<!-- C API usage examples. -->

<section class="examples">

</section>

<!-- /.examples -->

</section>

<!-- /.c -->

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/constants-float64-high-word-sign-mask.svg
[npm-url]: https://npmjs.org/package/@stdlib/constants-float64-high-word-sign-mask

[test-image]: https://github.com/stdlib-js/constants-float64-high-word-sign-mask/actions/workflows/test.yml/badge.svg?branch=v0.0.1
[test-url]: https://github.com/stdlib-js/constants-float64-high-word-sign-mask/actions/workflows/test.yml?query=branch:v0.0.1

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/constants-float64-high-word-sign-mask/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/constants-float64-high-word-sign-mask?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/constants-float64-high-word-sign-mask.svg
[dependencies-url]: https://david-dm.org/stdlib-js/constants-float64-high-word-sign-mask/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/constants-float64-high-word-sign-mask/tree/deno
[umd-url]: https://github.com/stdlib-js/constants-float64-high-word-sign-mask/tree/umd
[esm-url]: https://github.com/stdlib-js/constants-float64-high-word-sign-mask/tree/esm
[branches-url]: https://github.com/stdlib-js/constants-float64-high-word-sign-mask/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/constants-float64-high-word-sign-mask/main/LICENSE

[ieee754]: https://en.wikipedia.org/wiki/IEEE_754-1985

</section>

<!-- /.links -->
