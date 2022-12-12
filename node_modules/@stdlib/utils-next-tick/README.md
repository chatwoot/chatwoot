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

# nextTick

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Add a callback to the "next tick queue".

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-next-tick
```

</section>

<section class="usage">

## Usage

```javascript
var nextTick = require( '@stdlib/utils-next-tick' );
```

#### nextTick( clbk\[, ...args] )

Adds a callback to the "next tick queue".

```javascript
function beep() {
    console.log( 'boop' );
}

nextTick( beep );
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   The queue is fully drained after the current operation on the JavaScript stack runs to completion and before the event loop is allowed to continue.
-   Creating an infinite loop is possible if `nextTick` is called recursively.

</section>

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var nextTick = require( '@stdlib/utils-next-tick' );

function beep( x, y, z ) {
    console.log( 'boop: %d %d %d', x, y, z );
}

nextTick( beep, 1, 2, 3 );
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

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-next-tick.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-next-tick

[test-image]: https://github.com/stdlib-js/utils-next-tick/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/utils-next-tick/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-next-tick/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-next-tick?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-next-tick.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-next-tick/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-next-tick/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-next-tick/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-next-tick/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/utils-next-tick/main/LICENSE

</section>

<!-- /.links -->
