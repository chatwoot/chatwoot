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

# reim

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Return the real and imaginary components of a double-precision complex floating-point number.

<!-- Section to include introductory text. Make sure to keep an empty line after the intro `section` element and another before the `/section` close. -->

<section class="intro">

</section>

<!-- /.intro -->

<!-- Package usage documentation. -->

<section class="installation">

## Installation

```bash
npm install @stdlib/complex-reim
```

</section>

<section class="usage">

## Usage

```javascript
var reim = require( '@stdlib/complex-reim' );
```

#### reim( z )

Returns the **real** and **imaginary** components of a double-precision complex floating-point number.

```javascript
var Complex128 = require( '@stdlib/complex-float64' );

var z = new Complex128( 5.0, 3.0 );
var out = reim( z );
// returns <Float64Array>[ 5.0, 3.0 ]
```

</section>

<!-- /.usage -->

<!-- Package usage notes. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="notes">

</section>

<!-- /.notes -->

<!-- Package usage examples. -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var Complex128 = require( '@stdlib/complex-float64' );
var randu = require( '@stdlib/random-base-randu' );
var round = require( '@stdlib/math-base-special-round' );
var reim = require( '@stdlib/complex-reim' );

var out;
var re;
var im;
var z;
var i;

for ( i = 0; i < 100; i++ ) {
    re = round( (randu()*100.0) - 50.0 );
    im = round( (randu()*50.0) - 25.0 );
    z = new Complex128( re, im );
    out = reim( z );
    console.log( '%s => %d, %d', z.toString(), out[ 0 ], out[ 1 ] );
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
#include "stdlib/complex/reim.h"
```

#### stdlib_reim( z, \*re, \*im )

Returns the real and imaginary components of a double-precision complex floating-point number.

```c
#include "stdlib/complex/float64.h"

stdlib_complex128_t z = stdlib_complex128( 5.0, 2.0 );

// ...

double re;
double im;

stdlib_reim( z, &re, &im );
```

The function accepts the following arguments:

-   **z**: `[in] stdlib_complex128_t` double-precision complex floating-point number.
-   **re**: `[out] double*` destination for real component.
-   **im**: `[out] double*` destination for imaginary component.

```c
void stdlib_reim( const stdlib_complex128_t z, double *re, double *im );
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
#include "stdlib/complex/reim.h"
#include "stdlib/complex/float64.h"
#include <stdio.h>

int main() {
    stdlib_complex128_t x[] = {
        stdlib_complex128( 5.0, 2.0 ),
        stdlib_complex128( -2.0, 1.0 ),
        stdlib_complex128( 0.0, -0.0 ),
        stdlib_complex128( 0.0/0.0, 0.0/0.0 )
    };

    double re;
    double im;
    int i;
    for ( i = 0; i < 4; i++ ) {
        stdlib_reim( x[ i ], &re, &im );
        printf( "reim(v) = %lf, %lf\n", re, im );
    }
}
```

</section>

<!-- /.examples -->

</section>

<!-- /.c -->

<!-- Section to include cited references. If references are included, add a horizontal rule *before* the section. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="references">

</section>

<!-- /.references -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/complex/imag`][@stdlib/complex/imag]</span><span class="delimiter">: </span><span class="description">return the imaginary component of a complex number.</span>
-   <span class="package-name">[`@stdlib/complex/real`][@stdlib/complex/real]</span><span class="delimiter">: </span><span class="description">return the real component of a complex number.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/complex-reim.svg
[npm-url]: https://npmjs.org/package/@stdlib/complex-reim

[test-image]: https://github.com/stdlib-js/complex-reim/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/complex-reim/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/complex-reim/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/complex-reim?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/complex-reim.svg
[dependencies-url]: https://david-dm.org/stdlib-js/complex-reim/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/complex-reim/tree/deno
[umd-url]: https://github.com/stdlib-js/complex-reim/tree/umd
[esm-url]: https://github.com/stdlib-js/complex-reim/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/complex-reim/main/LICENSE

<!-- <related-links> -->

[@stdlib/complex/imag]: https://www.npmjs.com/package/@stdlib/complex-imag

[@stdlib/complex/real]: https://www.npmjs.com/package/@stdlib/complex-real

<!-- </related-links> -->

</section>

<!-- /.links -->
