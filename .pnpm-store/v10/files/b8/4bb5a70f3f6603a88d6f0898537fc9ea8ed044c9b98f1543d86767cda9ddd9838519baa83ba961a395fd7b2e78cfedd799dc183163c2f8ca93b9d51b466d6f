<!--

@license Apache-2.0

Copyright (c) 2020 The Stdlib Authors.

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

# Byte Order

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Platform [byte order][endianness].

<section class="installation">

## Installation

```bash
npm install @stdlib/os-byte-order
```

</section>

<section class="usage">

## Usage

```javascript
var BYTE_ORDER = require( '@stdlib/os-byte-order' );
```

#### BYTE_ORDER

Platform byte order.

```javascript
console.log( BYTE_ORDER );
// => <string>
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   The following values are possible:

    -   `'little-endian'`
    -   `'big-endian'`
    -   `'mixed-endian'` (also known as "middle-endian")
    -   `'unknown'`

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var BYTE_ORDER = require( '@stdlib/os-byte-order' );

if ( BYTE_ORDER === 'little-endian' ) {
    console.log( 'Least significant byte comes first...' );
} else if ( BYTE_ORDER === 'big-endian' ) {
    console.log( 'Most significant byte comes first...' );
} else {
    console.log( 'This is uncommon...' );
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
#include "stdlib/os/byte_order.h"
```

#### STDLIB_OS_ORDER_LITTLE_ENDIAN

Macro for an arbitrary constant indicating little-endian order.

```c
#if defined(STDLIB_OS_BYTE_ORDER) && STDLIB_OS_BYTE_ORDER == STDLIB_OS_ORDER_LITTLE_ENDIAN

// Do something for little-endian...

#endif
```

If compiled on an unrecognized/unsupported platform, the macro is **not** defined.

#### STDLIB_OS_ORDER_BIG_ENDIAN

Macro for an arbitrary constant indicating big-endian order.

```c
#if defined(STDLIB_OS_BYTE_ORDER) && STDLIB_OS_BYTE_ORDER == STDLIB_OS_ORDER_BIG_ENDIAN

// Do something for big-endian...

#endif
```

If compiled on an unrecognized/unsupported platform, the macro is **not** defined.

#### STDLIB_OS_BYTE_ORDER

Macro which equals either `STDLIB_OS_ORDER_LITTLE_ENDIAN` or `STDLIB_OS_ORDER_BIG_ENDIAN` (or host defined) depending on the resolved platform byte order.

```c
#if defined(STDLIB_OS_BYTE_ORDER)

#if STDLIB_OS_BYTE_ORDER == STDLIB_OS_ORDER_LITTLE_ENDIAN

// Do something for little-endian...

#elif STDLIB_OS_BYTE_ORDER == STDLIB_OS_ORDER_BIG_ENDIAN

// Do something for big-endian...

#endif

#endif
```

If compiled on an unrecognized/unsupported platform, the macro is **not** defined.

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
#include "stdlib/os/byte_order.h"
#include <stdio.h>

int main() {
#if defined(STDLIB_OS_BYTE_ORDER)
#if STDLIB_OS_BYTE_ORDER == STDLIB_OS_ORDER_LITTLE_ENDIAN
    printf( "Platform is little-endian...\n" );
#elif STDLIB_OS_BYTE_ORDER == STDLIB_OS_ORDER_BIG_ENDIAN
    printf( "Platform is big-endian...\n" );
#else
    printf( "Platform endianness is either mixed-endian or unknown...\n" )
#endif
#endif
}
```

</section>

<!-- /.examples -->

</section>

<!-- /.c -->

* * *

<section class="cli">

## CLI

<section class="installation">

## Installation

To use the module as a general utility, install the module globally

```bash
npm install -g @stdlib/os-byte-order
```

</section>

<!-- CLI usage documentation. -->

<section class="usage">

### Usage

```text
Usage: byte-order [options]

Options:

  -h,    --help                Print this message.
  -V,    --version             Print the package version.
```

</section>

<!-- /.usage -->

<section class="examples">

### Examples

```bash
$ byte-order
```

</section>

<!-- /.examples -->

</section>

<!-- /.cli -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/assert/is-big-endian`][@stdlib/assert/is-big-endian]</span><span class="delimiter">: </span><span class="description">check if an environment is big endian.</span>
-   <span class="package-name">[`@stdlib/assert/is-little-endian`][@stdlib/assert/is-little-endian]</span><span class="delimiter">: </span><span class="description">check if an environment is little endian.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/os-byte-order.svg
[npm-url]: https://npmjs.org/package/@stdlib/os-byte-order

[test-image]: https://github.com/stdlib-js/os-byte-order/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/os-byte-order/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/os-byte-order/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/os-byte-order?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/os-byte-order.svg
[dependencies-url]: https://david-dm.org/stdlib-js/os-byte-order/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/os-byte-order/tree/deno
[umd-url]: https://github.com/stdlib-js/os-byte-order/tree/umd
[esm-url]: https://github.com/stdlib-js/os-byte-order/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/os-byte-order/main/LICENSE

[endianness]: https://en.wikipedia.org/wiki/Endianness

<!-- <related-links> -->

[@stdlib/assert/is-big-endian]: https://www.npmjs.com/package/@stdlib/assert-is-big-endian

[@stdlib/assert/is-little-endian]: https://www.npmjs.com/package/@stdlib/assert-is-little-endian

<!-- </related-links> -->

</section>

<!-- /.links -->
