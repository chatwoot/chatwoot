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

# Resolve Parent Path

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Resolve a path by walking parent directories.

<section class="installation">

## Installation

```bash
npm install @stdlib/fs-resolve-parent-path
```

</section>

<section class="usage">

## Usage

```javascript
var resolveParentPath = require( '@stdlib/fs-resolve-parent-path' );
```

<a name="resolve-parent-path"></a>

#### resolveParentPath( path\[, options], clbk )

Asynchronously resolves a path by walking parent directories.

```javascript
resolveParentPath( 'package.json', onPath );

function onPath( error, path ) {
    if ( error ) {
        throw error;
    }
    console.log( path );
    // => '...'
}
```

The function accepts the following `options`:

-   **dir**: base directory from which to begin walking. May be either an absolute path or a path relative to the current working directory.

By default, the function begins walking from the current working directory. To specify an alternative directory, set the `dir` option.

```javascript
var opts = {
    'dir': __dirname
};
resolveParentPath( 'package.json', opts, onPath );

function onPath( error, path ) {
    if ( error ) {
        throw error;
    }
    console.log( path );
    // => '...'
}
```

#### resolveParentPath.sync( path\[, options] )

Synchronously resolves a path by walking parent directories.

```javascript
var path = resolveParentPath.sync( 'package.json' );
// returns '...'
```

The function accepts the same `options` as [`resolveParentPath()`](#resolve-parent-path).

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   If unable to resolve a path, both functions return `null`.
-   This implementation is **not** similar in functionality to core [`path.resolve`][node-core-path-resolve]. The latter performs string manipulation to generate a full path. This implementation walks parent directories to perform a **search**, thereby touching the file system. Accordingly, this implementation resolves a _real_ absolute file path and is intended for use when a target's location in a parent directory is unknown relative to a child directory; e.g., when wanting to find a package root from deep within a package directory. 

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var resolveParentPath = require( '@stdlib/fs-resolve-parent-path' );

var opts = {
    'dir': __dirname
};

/* Sync */

var out = resolveParentPath.sync( 'package.json', opts );
// returns '...'

out = resolveParentPath.sync( 'non_existent_basename' );
// returns null

/* Async */

resolveParentPath( 'package.json', opts, onPath );
resolveParentPath( './../non_existent_path', onPath );

function onPath( error, path ) {
    if ( error ) {
        throw error;
    }
    console.log( path );
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
npm install -g @stdlib/fs-resolve-parent-path
```

</section>

<!-- CLI usage documentation. -->

<section class="usage">

### Usage

```text
Usage: resolve-parent-path [options] <path>

Options:

  -h,    --help                Print this message.
  -V,    --version             Print the package version.
         --dir dir             Base search directory.
```

</section>

<!-- /.usage -->

<section class="examples">

### Examples

```bash
$ resolve-parent-path package.json
```

</section>

<!-- /.examples -->

</section>

<!-- /.cli -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/fs/resolve-parent-path-by`][@stdlib/fs/resolve-parent-path-by]</span><span class="delimiter">: </span><span class="description">resolve a path according to a predicate function by walking parent directories.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/fs-resolve-parent-path.svg
[npm-url]: https://npmjs.org/package/@stdlib/fs-resolve-parent-path

[test-image]: https://github.com/stdlib-js/fs-resolve-parent-path/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/fs-resolve-parent-path/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/fs-resolve-parent-path/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/fs-resolve-parent-path?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/fs-resolve-parent-path.svg
[dependencies-url]: https://david-dm.org/stdlib-js/fs-resolve-parent-path/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/fs-resolve-parent-path/tree/deno
[umd-url]: https://github.com/stdlib-js/fs-resolve-parent-path/tree/umd
[esm-url]: https://github.com/stdlib-js/fs-resolve-parent-path/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/fs-resolve-parent-path/main/LICENSE

[node-core-path-resolve]: https://nodejs.org/api/path.html#path_path_resolve_paths

<!-- <related-links> -->

[@stdlib/fs/resolve-parent-path-by]: https://www.npmjs.com/package/@stdlib/fs-resolve-parent-path-by

<!-- </related-links> -->

</section>

<!-- /.links -->
