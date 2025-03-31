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

# High Word

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Return an unsigned 32-bit integer corresponding to the more significant 32 bits of a [double-precision floating-point number][ieee754].

<section class="installation">

## Installation

```bash
npm install @stdlib/number-float64-base-get-high-word
```

</section>

<section class="usage">

## Usage

```javascript
var getHighWord = require( '@stdlib/number-float64-base-get-high-word' );
```

#### getHighWord( x )

Returns an unsigned 32-bit `integer` corresponding to the more significant 32 bits of a [double-precision floating-point number][ieee754].

```javascript
var w = getHighWord( 3.14e201 ); // => 01101001110001001000001011000011
// returns 1774486211
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
var getHighWord = require( '@stdlib/number-float64-base-get-high-word' );

var frac;
var exp;
var w;
var x;
var i;

for ( i = 0; i < 100; i++ ) {
    frac = randu() * 10.0;
    exp = -floor( randu()*324.0 );
    x = frac * pow( 10.0, exp );
    w = getHighWord( x );
    console.log( 'x: %d. high word: %d.', x, w );
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
#include "stdlib/number/float64/base/get_high_word.h"
```

#### stdlib_base_float64_get_high_word( x, \*high )

Extracts the unsigned 32-bit integer corresponding to the more significant 32 bits of a double-precision floating-point number.

```c
#include <stdint.h>

uint32_t high;
stdlib_base_float64_get_high_word( 3.14, &high );
```

The function accepts the following arguments:

-   **x**: `[in] double` input value.
-   **high**: `[out] uint32_t*` destination for higher order word.

```c
void stdlib_base_float64_get_high_word( const double x, uint32_t *high );
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
#include "stdlib/number/float64/base/get_high_word.h"
#include <stdint.h>
#include <stdio.h>

int main() {
    double x[] = { 3.14, -3.14, 0.0, 0.0/0.0 };

    uint32_t high;
    int i;
    for ( i = 0; i < 4; i++ ) {
        stdlib_base_float64_get_high_word( x[ i ], &high );
        printf( "%lf => high: %u\n", x[ i ], high );
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

[npm-image]: http://img.shields.io/npm/v/@stdlib/number-float64-base-get-high-word.svg
[npm-url]: https://npmjs.org/package/@stdlib/number-float64-base-get-high-word

[test-image]: https://github.com/stdlib-js/number-float64-base-get-high-word/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/number-float64-base-get-high-word/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/number-float64-base-get-high-word/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/number-float64-base-get-high-word?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/number-float64-base-get-high-word.svg
[dependencies-url]: https://david-dm.org/stdlib-js/number-float64-base-get-high-word/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/number-float64-base-get-high-word/tree/deno
[umd-url]: https://github.com/stdlib-js/number-float64-base-get-high-word/tree/umd
[esm-url]: https://github.com/stdlib-js/number-float64-base-get-high-word/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/number-float64-base-get-high-word/main/LICENSE

[ieee754]: https://en.wikipedia.org/wiki/IEEE_754-1985

</section>

<!-- /.links -->
