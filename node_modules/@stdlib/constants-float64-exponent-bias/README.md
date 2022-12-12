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

# FLOAT64_EXPONENT_BIAS

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> The bias of a [double-precision floating-point number's][ieee754] exponent.

<section class="installation">

## Installation

```bash
npm install @stdlib/constants-float64-exponent-bias
```

</section>

<section class="usage">

## Usage

```javascript
var FLOAT64_EXPONENT_BIAS = require( '@stdlib/constants-float64-exponent-bias' );
```

#### FLOAT64_EXPONENT_BIAS

The bias of a [double-precision floating-point number's][ieee754] exponent.

```javascript
var bool = ( FLOAT64_EXPONENT_BIAS === 1023 );
// returns true
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- TODO: better example -->

<!-- eslint no-undef: "error" -->

```javascript
var FLOAT64_EXPONENT_BIAS = require( '@stdlib/constants-float64-exponent-bias' );

console.log( FLOAT64_EXPONENT_BIAS );
// => 1023
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
#include "stdlib/constants/float64/exponent_bias.h"
```

#### STDLIB_CONSTANT_FLOAT64_EXPONENT_BIAS

Macro for the bias of a [double-precision floating-point number's][ieee754] exponent.

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

* * *

## See Also

-   <span class="package-name">[`@stdlib/constants/float16/exponent-bias`][@stdlib/constants/float16/exponent-bias]</span><span class="delimiter">: </span><span class="description">the bias of a half-precision floating-point number's exponent.</span>
-   <span class="package-name">[`@stdlib/constants/float32/exponent-bias`][@stdlib/constants/float32/exponent-bias]</span><span class="delimiter">: </span><span class="description">the bias of a single-precision floating-point number's exponent.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/constants-float64-exponent-bias.svg
[npm-url]: https://npmjs.org/package/@stdlib/constants-float64-exponent-bias

[test-image]: https://github.com/stdlib-js/constants-float64-exponent-bias/actions/workflows/test.yml/badge.svg?branch=v0.0.8
[test-url]: https://github.com/stdlib-js/constants-float64-exponent-bias/actions/workflows/test.yml?query=branch:v0.0.8

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/constants-float64-exponent-bias/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/constants-float64-exponent-bias?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/constants-float64-exponent-bias.svg
[dependencies-url]: https://david-dm.org/stdlib-js/constants-float64-exponent-bias/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/constants-float64-exponent-bias/tree/deno
[umd-url]: https://github.com/stdlib-js/constants-float64-exponent-bias/tree/umd
[esm-url]: https://github.com/stdlib-js/constants-float64-exponent-bias/tree/esm
[branches-url]: https://github.com/stdlib-js/constants-float64-exponent-bias/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/constants-float64-exponent-bias/main/LICENSE

[ieee754]: https://en.wikipedia.org/wiki/IEEE_754-1985

<!-- <related-links> -->

[@stdlib/constants/float16/exponent-bias]: https://www.npmjs.com/package/@stdlib/constants-float16-exponent-bias

[@stdlib/constants/float32/exponent-bias]: https://www.npmjs.com/package/@stdlib/constants-float32-exponent-bias

<!-- </related-links> -->

</section>

<!-- /.links -->
