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

# Words

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Split a [double-precision floating-point number][ieee754] into a higher order word and a lower order word.

<section class="installation">

## Installation

```bash
npm install @stdlib/number-float64-base-to-words
```

</section>

<section class="usage">

## Usage

```javascript
var toWords = require( '@stdlib/number-float64-base-to-words' );
```

#### toWords( x )

Splits a [double-precision floating-point number][ieee754] into a higher order word (unsigned 32-bit `integer`) and a lower order word (unsigned 32-bit `integer`).

```javascript
var w = toWords( 3.14e201 );
// returns [ 1774486211, 2479577218 ]
```

By default, the function returns an `array` containing two elements: a higher order word and a lower order word. The lower order word contains the less significant bits, while the higher order word contains the more significant bits and includes the exponent and sign.

```javascript
var w = toWords( 3.14e201 );
// returns [ 1774486211, 2479577218 ]

var high = w[ 0 ];
// returns 1774486211

var low = w[ 1 ];
// returns 2479577218
```

#### toWords.assign( x, out, stride, offset )

Splits a [double-precision floating-point number][ieee754] into a higher order word (unsigned 32-bit `integer`) and a lower order word (unsigned 32-bit `integer`) and assigns results to a provided output array.

```javascript
var Uint32Array = require( '@stdlib/array-uint32' );

var out = new Uint32Array( 2 );

var w = toWords.assign( 3.14e201, out, 1, 0 );
// returns <Uint32Array>[ 1774486211, 2479577218 ]

var bool = ( w === out );
// returns true
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var floor = require( '@stdlib/math-base-special-floor' );
var randu = require( '@stdlib/random-base-randu' );
var pow = require( '@stdlib/math-base-special-pow' );
var toWords = require( '@stdlib/number-float64-base-to-words' );

var frac;
var exp;
var w;
var x;
var i;

// Generate random numbers and split into words...
for ( i = 0; i < 100; i++ ) {
    frac = randu() * 10.0;
    exp = -floor( randu()*324.0 );
    x = frac * pow( 10.0, exp );
    w = toWords( x );
    console.log( 'x: %d. higher: %d. lower: %d.', x, w[ 0 ], w[ 1 ] );
}
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
#include "stdlib/number/float64/base/to_words.h"
```

#### stdlib_base_float64_to_words( x, \*high, \*low )

Splits a double-precision floating-point number into a higher order word and a lower order word.

```c
#include <stdint.h>

uint32_t high;
uint32_t low;

stdlib_base_float64_to_words( 3.14, &high, &low );
```

The function accepts the following arguments:

-   **x**: `[in] double` input value.
-   **high**: `[out] uint32_t*` destination for higher order word.
-   **low**: `[out] uint32_t*` destination for lower order word.

```c
void stdlib_base_float64_to_words( const double x, uint32_t *high, uint32_t *low );
```

#### stdlib_base_float64_words_t

An opaque type definition for a union for converting between a double-precision floating-point number and two unsigned 32-bit integers.

```c
#include <stdint.h>

stdlib_base_float64_words_t w;

// Assign a double-precision floating-point number:
w.value = 3.14;

// Extract the high and low words:
uint32_t high = w.words.high;
uint32_t low = w.words.low;
```

The union has the following members:

-   **value**: `double` double-precision floating-point number.

-   **words**: `struct` struct having the following members:

    -   **high**: `uint32_t` higher order word.
    -   **low**: `uint32_t` lower order word.

</section>

<!-- /.usage -->

<!-- C API usage notes. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="notes">

</section>

<!-- /.notes -->

<!-- C API usage examples. -->

<section class="examples">

### Examples

```c
#include "stdlib/number/float64/base/to_words.h"
#include <stdint.h>
#include <stdio.h>

int main() {
    double x[] = { 3.14, -3.14, 0.0, 0.0/0.0 };

    uint32_t high;
    uint32_t low;
    int i;
    for ( i = 0; i < 4; i++ ) {
        stdlib_base_float64_to_words( x[ i ], &high, &low );
        printf( "%lf => high: %u, low: %u\n", x[ i ], high, low );
    }
}
```

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/number-float64-base-to-words.svg
[npm-url]: https://npmjs.org/package/@stdlib/number-float64-base-to-words

[test-image]: https://github.com/stdlib-js/number-float64-base-to-words/actions/workflows/test.yml/badge.svg?branch=v0.0.7
[test-url]: https://github.com/stdlib-js/number-float64-base-to-words/actions/workflows/test.yml?query=branch:v0.0.7

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/number-float64-base-to-words/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/number-float64-base-to-words?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/number-float64-base-to-words.svg
[dependencies-url]: https://david-dm.org/stdlib-js/number-float64-base-to-words/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/number-float64-base-to-words/tree/deno
[umd-url]: https://github.com/stdlib-js/number-float64-base-to-words/tree/umd
[esm-url]: https://github.com/stdlib-js/number-float64-base-to-words/tree/esm
[branches-url]: https://github.com/stdlib-js/number-float64-base-to-words/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/number-float64-base-to-words/main/LICENSE

[ieee754]: https://en.wikipedia.org/wiki/IEEE_754-1985

</section>

<!-- /.links -->
