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

# string2buffer

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Allocate a [buffer][@stdlib/buffer/ctor] containing a provided string.

<!-- Section to include introductory text. Make sure to keep an empty line after the intro `section` element and another before the `/section` close. -->

<section class="intro">

</section>

<!-- /.intro -->

<!-- Package usage documentation. -->

<section class="installation">

## Installation

```bash
npm install @stdlib/buffer-from-string
```

</section>

<section class="usage">

## Usage

```javascript
var string2buffer = require( '@stdlib/buffer-from-string' );
```

#### string2buffer( str\[, encoding] )

Allocates a [buffer][@stdlib/buffer/ctor] containing a provided `string`.

```javascript
var buf = string2buffer( 'beep boop' );
// returns <Buffer>
```

The default character encoding is `utf8`. To specify an alternative encoding, provide an `encoding` argument.

```javascript
var buf = string2buffer( '7468697320697320612074c3a97374', 'hex' );
// returns <Buffer>
```

The following `encodings` are supported:

-   `utf8` (`utf-8`)
-   `hex`
-   `binary`
-   `ascii`
-   `ucs2`
-   `base64`

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
var randu = require( '@stdlib/random-base-randu' );
var randint = require( '@stdlib/random-base-discrete-uniform' );
var string2buffer = require( '@stdlib/buffer-from-string' );

// Create a buffer from a string:
var buf = string2buffer( 'beep boop bop' );
console.log( buf.toString() );

// Generate random strings...
var i;
var j;
for ( i = 0; i < 100; i++ ) {
    j = randint( 0, buf.length );
    if ( randu() < 2/buf.length ) {
        buf[ j ] = 32; // space
    } else {
        buf[ j ] = randint( 97, 122 );
    }
    console.log( buf.toString() );
}
```

</section>

<!-- /.examples -->

<!-- Section to include cited references. If references are included, add a horizontal rule *before* the section. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="references">

</section>

<!-- /.references -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/buffer/ctor`][@stdlib/buffer/ctor]</span><span class="delimiter">: </span><span class="description">Buffer.</span>
-   <span class="package-name">[`@stdlib/buffer/from-array`][@stdlib/buffer/from-array]</span><span class="delimiter">: </span><span class="description">allocate a buffer using an octet array.</span>
-   <span class="package-name">[`@stdlib/buffer/from-arraybuffer`][@stdlib/buffer/from-arraybuffer]</span><span class="delimiter">: </span><span class="description">allocate a buffer from an ArrayBuffer.</span>
-   <span class="package-name">[`@stdlib/buffer/from-buffer`][@stdlib/buffer/from-buffer]</span><span class="delimiter">: </span><span class="description">copy buffer data to a new Buffer instance.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/buffer-from-string.svg
[npm-url]: https://npmjs.org/package/@stdlib/buffer-from-string

[test-image]: https://github.com/stdlib-js/buffer-from-string/actions/workflows/test.yml/badge.svg?branch=v0.0.8
[test-url]: https://github.com/stdlib-js/buffer-from-string/actions/workflows/test.yml?query=branch:v0.0.8

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/buffer-from-string/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/buffer-from-string?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/buffer-from-string.svg
[dependencies-url]: https://david-dm.org/stdlib-js/buffer-from-string/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/buffer-from-string/tree/deno
[umd-url]: https://github.com/stdlib-js/buffer-from-string/tree/umd
[esm-url]: https://github.com/stdlib-js/buffer-from-string/tree/esm
[branches-url]: https://github.com/stdlib-js/buffer-from-string/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/buffer-from-string/main/LICENSE

<!-- <related-links> -->

[@stdlib/buffer/ctor]: https://www.npmjs.com/package/@stdlib/buffer-ctor

[@stdlib/buffer/from-array]: https://www.npmjs.com/package/@stdlib/buffer-from-array

[@stdlib/buffer/from-arraybuffer]: https://www.npmjs.com/package/@stdlib/buffer-from-arraybuffer

[@stdlib/buffer/from-buffer]: https://www.npmjs.com/package/@stdlib/buffer-from-buffer

<!-- </related-links> -->

</section>

<!-- /.links -->
