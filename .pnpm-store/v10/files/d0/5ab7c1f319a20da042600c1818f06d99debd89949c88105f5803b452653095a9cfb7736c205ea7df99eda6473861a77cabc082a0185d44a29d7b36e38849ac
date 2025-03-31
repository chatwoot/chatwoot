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

# Absolute Value

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Compute the [absolute value][absolute-value] of a double-precision floating-point number.

<section class="intro">

The [absolute value][absolute-value] is defined as

<!-- <equation class="equation" label="eq:absolute_value" align="center" raw="|x| = \begin{cases} x & \textrm{if}\ x \geq 0 \\ -x & \textrm{if}\ x < 0\end{cases}" alt="Absolute value"> -->

<div class="equation" align="center" data-raw-text="|x| = \begin{cases} x &amp; \textrm{if}\ x \geq 0 \\ -x &amp; \textrm{if}\ x &lt; 0\end{cases}" data-equation="eq:absolute_value">
    <img src="https://cdn.jsdelivr.net/gh/stdlib-js/stdlib@bb29798906e119fcb2af99e94b60407a270c9b32/lib/node_modules/@stdlib/math/base/special/abs/docs/img/equation_absolute_value.svg" alt="Absolute value">
    <br>
</div>

<!-- </equation> -->

</section>

<!-- /.intro -->

<section class="installation">

## Installation

```bash
npm install @stdlib/math-base-special-abs
```

</section>

<section class="usage">

## Usage

```javascript
var abs = require( '@stdlib/math-base-special-abs' );
```

#### abs( x )

Computes the [absolute value][absolute-value] of a double-precision floating-point number.

```javascript
var v = abs( -1.0 );
// returns 1.0

v = abs( 2.0 );
// returns 2.0

v = abs( 0.0 );
// returns 0.0

v = abs( -0.0 );
// returns 0.0

v = abs( NaN );
// returns NaN
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var randu = require( '@stdlib/random-base-randu' );
var round = require( '@stdlib/math-base-special-round' );
var abs = require( '@stdlib/math-base-special-abs' );

var rand;
var i;

for ( i = 0; i < 100; i++ ) {
    rand = round( randu() * 100.0 ) - 50.0;
    console.log( 'abs(%d) = %d', rand, abs( rand ) );
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
#include "stdlib/math/base/special/abs.h"
```

#### stdlib_base_abs( x )

Computes the absolute value of a double-precision floating-point number.

```c
double y = stdlib_base_abs( -5.0 );
// returns 5.0
```

The function accepts the following arguments:

-   **x**: `[in] double` input value.

```c
double stdlib_base_abs( const double x );
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
#include "stdlib/math/base/special/abs.h"
#include <stdio.h>

int main() {
    double x[] = { 3.14, -3.14, 0.0, 0.0/0.0 };

    double y;
    int i;
    for ( i = 0; i < 4; i++ ) {
        y = stdlib_base_abs( x[ i ] );
        printf( "|%lf| = %lf\n", x[ i ], y );
    }
}
```

</section>

<!-- /.examples -->

</section>

<!-- /.c -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/math/base/special/abs2`][@stdlib/math/base/special/abs2]</span><span class="delimiter">: </span><span class="description">compute the squared absolute value of a double-precision floating-point number.</span>
-   <span class="package-name">[`@stdlib/math/base/special/absf`][@stdlib/math/base/special/absf]</span><span class="delimiter">: </span><span class="description">compute the absolute value of a single-precision floating-point number.</span>
-   <span class="package-name">[`@stdlib/math/base/special/labs`][@stdlib/math/base/special/labs]</span><span class="delimiter">: </span><span class="description">compute an absolute value of a signed 32-bit integer.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/math-base-special-abs.svg
[npm-url]: https://npmjs.org/package/@stdlib/math-base-special-abs

[test-image]: https://github.com/stdlib-js/math-base-special-abs/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/math-base-special-abs/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/math-base-special-abs/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/math-base-special-abs?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/math-base-special-abs.svg
[dependencies-url]: https://david-dm.org/stdlib-js/math-base-special-abs/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/math-base-special-abs/tree/deno
[umd-url]: https://github.com/stdlib-js/math-base-special-abs/tree/umd
[esm-url]: https://github.com/stdlib-js/math-base-special-abs/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/math-base-special-abs/main/LICENSE

[absolute-value]: https://en.wikipedia.org/wiki/Absolute_value

<!-- <related-links> -->

[@stdlib/math/base/special/abs2]: https://www.npmjs.com/package/@stdlib/math-base-special-abs2

[@stdlib/math/base/special/absf]: https://www.npmjs.com/package/@stdlib/math-base-special-absf

[@stdlib/math/base/special/labs]: https://www.npmjs.com/package/@stdlib/math-base-special-labs

<!-- </related-links> -->

</section>

<!-- /.links -->
