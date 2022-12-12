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

# Standard Input

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> [Standard input][standard-streams].

<section class="installation">

## Installation

```bash
npm install @stdlib/streams-node-stdin
```

</section>

<section class="usage">

## Usage

```javascript
var stdin = require( '@stdlib/streams-node-stdin' );
```

#### stdin

[Standard input][standard-streams] as a [Readable stream][readable-stream].

<!-- run-disable -->

```javascript
var string2buffer = require( '@stdlib/buffer-from-string' );
var Buffer = require( '@stdlib/buffer-ctor' );

var data = [];
var len = 0;

stdin.on( 'readable', onReadable );
stdin.on( 'error', onError );
stdin.on( 'end', onEnd );

function onReadable() {
    var chunk;
    while ( true ) {
        chunk = stdin.read();
        if ( chunk === null ) {
            break;
        }
        if ( typeof chunk === 'string' ) {
            chunk = string2buffer( chunk );
        }
        data.push( chunk );
        len += chunk.length;
    }
}

function onError( error ) {
    if ( error ) {
        console.error( error.message );
    }
}

function onEnd() {
    data = Buffer.concat( data, len );
    console.log( data.toString() );
    // => '...'
}
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- run-disable -->

<!-- eslint no-undef: "error" -->

```javascript
var proc = require( 'process' );
var stdin = require( '@stdlib/streams-node-stdin' );
var stdout = require( '@stdlib/streams-node-stdout' );

// Set the encoding:
stdin.setEncoding( 'utf8' );

// Create an echo stream:
stdin.pipe( stdout );

// Push data to `stdin`:
stdin.push( 'beep' );
stdin.push( ' ' );
stdin.push( 'boop' );
stdin.push( '\n' );

// End the stream:
stdin.push( null );

// Ensure the process closes:
setTimeout( proc.exit, 1000 );
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

[npm-image]: http://img.shields.io/npm/v/@stdlib/streams-node-stdin.svg
[npm-url]: https://npmjs.org/package/@stdlib/streams-node-stdin

[test-image]: https://github.com/stdlib-js/streams-node-stdin/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/streams-node-stdin/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/streams-node-stdin/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/streams-node-stdin?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/streams-node-stdin.svg
[dependencies-url]: https://david-dm.org/stdlib-js/streams-node-stdin/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/streams-node-stdin/tree/deno
[umd-url]: https://github.com/stdlib-js/streams-node-stdin/tree/umd
[esm-url]: https://github.com/stdlib-js/streams-node-stdin/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/streams-node-stdin/main/LICENSE

[standard-streams]: https://en.wikipedia.org/wiki/Standard_streams

[readable-stream]: https://nodejs.org/api/stream.html#stream_class_stream_readable

</section>

<!-- /.links -->
