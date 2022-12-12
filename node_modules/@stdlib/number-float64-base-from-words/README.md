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

# From Words

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Create a [double-precision floating-point number][ieee754] from a higher order word and a lower order word.

<section class="installation">

## Installation

```bash
npm install @stdlib/number-float64-base-from-words
```

</section>

<section class="usage">

## Usage

```javascript
var fromWords = require( '@stdlib/number-float64-base-from-words' );
```

#### fromWords( high, low )

Creates a [double-precision floating-point number][ieee754] from a higher order word (unsigned 32-bit `integer`) and a lower order word (unsigned 32-bit `integer`).

```javascript
var v = fromWords( 1774486211, 2479577218 );
// returns 3.14e201

v = fromWords( 3221823995, 1413754136 );
// returns -3.141592653589793

v = fromWords( 0, 0 );
// returns 0.0

v = fromWords( 2147483648, 0 );
// returns -0.0

v = fromWords( 2146959360, 0 );
// returns NaN

v = fromWords( 2146435072, 0 );
// returns Infinity

v = fromWords( 4293918720, 0 );
// returns -Infinity
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   For more information regarding higher and lower order words, see [to-words][@stdlib/number/float64/base/to-words].

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var randu = require( '@stdlib/random-base-randu' );
var round = require( '@stdlib/math-base-special-round' );
var MAX_UINT32 = require( '@stdlib/constants-uint32-max' );
var fromWords = require( '@stdlib/number-float64-base-from-words' );

var high;
var low;
var x;
var i;

for ( i = 0; i < 100; i++ ) {
    high = round( randu()*MAX_UINT32 );
    low = round( randu()*MAX_UINT32 );
    x = fromWords( high, low );
    console.log( 'higher: %d. lower: %d. float: %d.', high, low, x );
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
#include "stdlib/number/float64/base/from_words.h"
```

#### stdlib_base_float64_from_words( high, low, \*x )

Creates a double-precision floating-point number from a higher order word and a lower order word.

```c
#include <stdint.h>

uint32_t high = 1074339512;
uint32_t low = 1374389535;

double x;
stdlib_base_float64_from_words( high, low, &x );
```

The function accepts the following arguments:

-   **high**: `[in] uint32_t` higher order word.
-   **low**: `[in] uint32_t` lower order word.
-   **x**: `[out] double*` destination for a double-precision floating-point number.

```c
void stdlib_base_float64_from_words( const uint32_t high, const uint32_t low, double *x );
```

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
#include "stdlib/number/float64/base/from_words.h"
#include <stdint.h>
#include <stdio.h>

int main() {
    uint32_t high = 1074339512;
    uint32_t low[] = { 0, 10000, 1000000, 1374389535 };

    double x;
    int i;
    for ( i = 0; i < 4; i++ ) {
        stdlib_base_float64_from_words( high, low[ i ], &x );
        printf( "high: %u, low: %u => %lf\n", high, low[ i ], x );
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

[npm-image]: http://img.shields.io/npm/v/@stdlib/number-float64-base-from-words.svg
[npm-url]: https://npmjs.org/package/@stdlib/number-float64-base-from-words

[test-image]: https://github.com/stdlib-js/number-float64-base-from-words/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/number-float64-base-from-words/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/number-float64-base-from-words/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/number-float64-base-from-words?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/number-float64-base-from-words.svg
[dependencies-url]: https://david-dm.org/stdlib-js/number-float64-base-from-words/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/number-float64-base-from-words/tree/deno
[umd-url]: https://github.com/stdlib-js/number-float64-base-from-words/tree/umd
[esm-url]: https://github.com/stdlib-js/number-float64-base-from-words/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/number-float64-base-from-words/main/LICENSE

[ieee754]: https://en.wikipedia.org/wiki/IEEE_754-1985

[@stdlib/number/float64/base/to-words]: https://www.npmjs.com/package/@stdlib/number-float64-base-to-words

</section>

<!-- /.links -->
