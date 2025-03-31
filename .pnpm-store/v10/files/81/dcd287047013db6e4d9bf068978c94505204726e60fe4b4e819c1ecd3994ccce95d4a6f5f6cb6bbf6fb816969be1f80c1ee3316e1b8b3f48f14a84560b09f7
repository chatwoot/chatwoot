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

# Buffer

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> [Buffer][node-buffer] constructor.

<!-- Section to include introductory text. Make sure to keep an empty line after the intro `section` element and another before the `/section` close. -->

<section class="intro">

</section>

<!-- /.intro -->

<!-- Package usage documentation. -->

<section class="installation">

## Installation

```bash
npm install @stdlib/buffer-ctor
```

</section>

<section class="usage">

## Usage

```javascript
var Buffer = require( '@stdlib/buffer-ctor' );
```

#### Buffer( size )

Allocates a [`Buffer`][node-buffer] having a specified number of bytes.

<!-- eslint-disable stdlib/require-globals, no-buffer-constructor -->

```javascript
var b = new Buffer( 10 );
// returns <Buffer>
```

#### Buffer( array )

Allocates a [`Buffer`][node-buffer] from an array of octets.

<!-- eslint-disable stdlib/require-globals, no-buffer-constructor -->

```javascript
var b = new Buffer( [ 1, 2, 3, 4 ] );
// returns <Buffer>[ 1, 2, 3, 4 ]
```

#### Buffer( buffer )

Copies [buffer][node-buffer] data to a new [`Buffer`][node-buffer] instance.

<!-- eslint-disable stdlib/require-globals, no-buffer-constructor -->

```javascript
var b1 = new Buffer( [ 1, 2, 3, 4 ] );
var b2 = new Buffer( b1 );
// returns <Buffer>[ 1, 2, 3, 4 ]
```

#### Buffer( str\[, encoding] )

Returns a [`Buffer`][node-buffer] containing a provided `string`.

<!-- eslint-disable stdlib/require-globals, no-buffer-constructor -->

```javascript
var b = new Buffer( 'beep boop' );
// returns <Buffer>
```

* * *

### Properties

TODO: add properties

* * *

### Methods

TODO: add methods

</section>

<!-- /.usage -->

* * *

<!-- Package usage notes. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="notes">

</section>

<!-- /.notes -->

<!-- Package usage examples. -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var ctor = require( '@stdlib/buffer-ctor' );

var b;
var i;

// Allocate uninitialized memory:
if ( typeof ctor.alloc === 'function' ) {
    b = ctor.alloc( 10 );
} else {
    b = new ctor( 10 );
}

// Zero fill the buffer...
for ( i = 0; i < b.length; i++ ) {
    b[ i ] = 0;
}
console.log( b );
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

-   <span class="package-name">[`@stdlib/array/buffer`][@stdlib/array/buffer]</span><span class="delimiter">: </span><span class="description">ArrayBuffer.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/buffer-ctor.svg
[npm-url]: https://npmjs.org/package/@stdlib/buffer-ctor

[test-image]: https://github.com/stdlib-js/buffer-ctor/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/buffer-ctor/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/buffer-ctor/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/buffer-ctor?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/buffer-ctor.svg
[dependencies-url]: https://david-dm.org/stdlib-js/buffer-ctor/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/buffer-ctor/tree/deno
[umd-url]: https://github.com/stdlib-js/buffer-ctor/tree/umd
[esm-url]: https://github.com/stdlib-js/buffer-ctor/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/buffer-ctor/main/LICENSE

[node-buffer]: https://nodejs.org/api/buffer.html

<!-- <related-links> -->

[@stdlib/array/buffer]: https://www.npmjs.com/package/@stdlib/array-buffer

<!-- </related-links> -->

</section>

<!-- /.links -->
