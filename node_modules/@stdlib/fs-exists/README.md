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

# Exists

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Test whether a path exists on the filesystem.

<section class="installation">

## Installation

```bash
npm install @stdlib/fs-exists
```

</section>

<section class="usage">

## Usage

```javascript
var exists = require( '@stdlib/fs-exists' );
```

#### exists( path, clbk )

Asynchronously tests whether a path exists on the filesystem.

```javascript
exists( __dirname, done );

function done( bool ) {
    if ( bool ) {
        console.log( '...path exists.' );
    } else {
        console.log( '...path does not exist.' );
    }
}
```

The above callback signature matches the now **deprecated** [`fs.exists()`][node-fs-exists] API. The function also accepts the more conventional `error`-first style callback signature found in most asynchronous Node APIs.

```javascript
exists( __dirname, done );

function done( error, bool ) {
    if ( error ) {
        console.error( error.message );
    }
    if ( bool ) {
        console.log( '...path exists.' );
    } else {
        console.log( '...path does not exist.' );
    }
}
```

#### exists.sync( path )

Synchronously tests whether a path exists on the filesystem.

```javascript
var bool = exists.sync( __dirname );
// returns <boolean>
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   The following is considered an anti-pattern:

    ```javascript
    var path = require( 'path' );
    var readFileSync = require( '@stdlib/fs-read-file' ).sync;

    var file = path.join( __dirname, 'foo.js' );
    if ( exists.sync( __dirname ) ) {
        file = readFileSync( file );
    }
    ```

    Because time elapses between checking for existence and performing IO, at the time IO is performed, the path is no longer guaranteed to exist. In other words, a race condition exists between the process attempting to read and another process attempting to delete.

    Instead, the following pattern is preferred, where `errors` are handled explicitly:

    ```javascript
    var path = require( 'path' );
    var readFileSync = require( '@stdlib/fs-read-file' ).sync;

    var file = path.join( __dirname, 'foo.js' );
    try {
        file = readFileSync( file );
    } catch ( error ) {
        console.log( 'unable to read file.' );
        console.error( error );
    }
    ```

-   Nevertheless, use cases exist where one desires to check existence **without** performing IO. For example,

    <!-- run-disable -->

    ```javascript
    var path = require( 'path' );
    var writeFileSync = require( '@stdlib/fs-write-file' ).sync;

    var file = path.join( __dirname, 'foo.js' );
    if ( exists.sync( file ) ) {
        console.log( 'Don\'t overwrite the file!' );
    } else {
        writeFileSync( file, 'beep', {
            'encoding': 'utf8'
        });
    }
    ```

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var exists = require( '@stdlib/fs-exists' );

/* Sync */

console.log( exists.sync( __dirname ) );
// => true

console.log( exists.sync( 'beepboop' ) );
// => false

/* Async */

exists( __dirname, done );
exists( 'beepboop', done );

function done( error, bool ) {
    if ( error ) {
        console.error( error.message );
    } else {
        console.log( bool );
    }
}
```

</section>

<!-- /.examples -->

* * *

<section class="cli">

## CLI

<section class="installation">

## Installation

To use the module as a general utility, install the module globally

```bash
npm install -g @stdlib/fs-exists
```

</section>

<!-- CLI usage documentation. -->

<section class="usage">

### Usage

```text
Usage: exists [options] <path>

Options:

  -h,    --help                Print this message.
  -V,    --version             Print the package version.
```

</section>

<!-- /.usage -->

<section class="notes">

### Notes

-   Relative paths are resolved relative to the current working directory.
-   Errors are written to `stderr`.
-   Results are written to `stdout`.

</section>

<!-- /.notes -->

<section class="examples">

### Examples

```bash
$ exists ./../
true || <error_message>
```

</section>

<!-- /.examples -->

</section>

<!-- /.cli -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/fs/read-file`][@stdlib/fs/read-file]</span><span class="delimiter">: </span><span class="description">read the entire contents of a file.</span>
-   <span class="package-name">[`@stdlib/fs/read-dir`][@stdlib/fs/read-dir]</span><span class="delimiter">: </span><span class="description">read the entire contents of a directory.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/fs-exists.svg
[npm-url]: https://npmjs.org/package/@stdlib/fs-exists

[test-image]: https://github.com/stdlib-js/fs-exists/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/fs-exists/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/fs-exists/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/fs-exists?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/fs-exists.svg
[dependencies-url]: https://david-dm.org/stdlib-js/fs-exists/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/fs-exists/tree/deno
[umd-url]: https://github.com/stdlib-js/fs-exists/tree/umd
[esm-url]: https://github.com/stdlib-js/fs-exists/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/fs-exists/main/LICENSE

[node-fs-exists]: https://nodejs.org/api/fs.html#fs_fs_exists_path_callback

<!-- <related-links> -->

[@stdlib/fs/read-file]: https://www.npmjs.com/package/@stdlib/fs-read-file

[@stdlib/fs/read-dir]: https://www.npmjs.com/package/@stdlib/fs-read-dir

<!-- </related-links> -->

</section>

<!-- /.links -->
