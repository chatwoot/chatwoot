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

# stdin

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Read data from [`stdin`][@stdlib/streams/node/stdin].

<section class="installation">

## Installation

```bash
npm install @stdlib/process-read-stdin
```

</section>

<section class="usage">

## Usage

```javascript
var stdin = require( '@stdlib/process-read-stdin' );
```

#### stdin( \[encoding,] clbk )

Reads data from [`stdin`][@stdlib/streams/node/stdin].

<!-- run-disable -->

```javascript
function onRead( error, data ) {
    if ( error ) {
        return console.error( 'Error: %s', error.message );
    }
    console.log( data.toString() );
    // => '...'
}

stdin( onRead );
```

By default, returned `data` is a [`Buffer`][buffer]. To return a `string` of a specified encoding, provide an `encoding` parameter.

<!-- run-disable -->

```javascript
function onRead( error, data ) {
    if ( error ) {
        return console.error( 'Error: %s', error.message );
    }
    console.log( data );
    // => '...'
}

stdin( 'utf8', onRead );
```

When a file's calling Node.js process is running in a [TTY][tty] context (i.e., no [`stdin`][@stdlib/streams/node/stdin]), `data` will either be an empty [`Buffer`][buffer] (no encoding provided) or an empty `string` (encoding provided).

<!-- run-disable -->

```javascript
var stream = require( '@stdlib/streams-node-stdin' );

function onRead( error, data ) {
    if ( error ) {
        return console.error( 'Error: %s', error.message );
    }
    console.log( data );
    // => ''
}

stream.isTTY = true;

stdin( 'utf8', onRead );
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- run-disable -->

<!-- eslint no-undef: "error" -->

```javascript
var string2buffer = require( '@stdlib/buffer-from-string' );
var stream = require( '@stdlib/streams-node-stdin' );
var stdin = require( '@stdlib/process-read-stdin' );

function onRead( error, data ) {
    if ( error ) {
        console.error( 'Error: %s', error.message );
    } else {
        console.log( data.toString() );
        // => 'beep boop'
    }
}

// Fake not being in a terminal context:
stream.isTTY = false;

// Provide a callback to consume all data from `stdin`:
stdin( onRead );

// Push some data to `stdin`:
stream.push( string2buffer( 'beep' ) );
stream.push( string2buffer( ' ' ) );
stream.push( string2buffer( 'boop' ) );

// End the stream:
stream.push( null );
```

</section>

<!-- /.examples -->

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/process-read-stdin.svg
[npm-url]: https://npmjs.org/package/@stdlib/process-read-stdin

[test-image]: https://github.com/stdlib-js/process-read-stdin/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/process-read-stdin/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/process-read-stdin/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/process-read-stdin?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/process-read-stdin.svg
[dependencies-url]: https://david-dm.org/stdlib-js/process-read-stdin/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/process-read-stdin/tree/deno
[umd-url]: https://github.com/stdlib-js/process-read-stdin/tree/umd
[esm-url]: https://github.com/stdlib-js/process-read-stdin/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/process-read-stdin/main/LICENSE

[buffer]: https://nodejs.org/api/buffer.html

[tty]: https://nodejs.org/api/tty.html#tty_tty

[@stdlib/streams/node/stdin]: https://www.npmjs.com/package/@stdlib/streams-node-stdin

</section>

<!-- /.links -->
