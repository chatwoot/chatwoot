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

# isObjectLike

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Test if a value is object-like.

<section class="installation">

## Installation

```bash
npm install @stdlib/assert-is-object-like
```

</section>

<section class="usage">

## Usage

```javascript
var isObjectLike = require( '@stdlib/assert-is-object-like' );
```

#### isObjectLike( value )

Tests if a `value` is object-like.

```javascript
var bool = isObjectLike( {} );
// returns true

bool = isObjectLike( [] );
// returns true

bool = isObjectLike( true );
// returns false
```

#### isObjectLike.isObjectLikeArray( value )

Tests if a `value` is an `array` of object-like values.

```javascript
var bool = isObjectLike.isObjectLikeArray( [ {}, [] ] );
// returns true

bool = isObjectLike.isObjectLikeArray( [ {}, '3.0' ] );
// returns false

bool = isObjectLike.isObjectLikeArray( [] );
// returns false
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   Return values are the same as would be obtained using the built-in [`typeof`][type-of] operator **except** that `null` is **not** considered an `object`.

    ```javascript
    var bool = ( typeof null === 'object' );
    // returns true

    bool = isObjectLike( null );
    // returns false
    ```

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint-disable no-empty-function, no-restricted-syntax -->

<!-- eslint no-undef: "error" -->

```javascript
var Int8Array = require( '@stdlib/array-int8' );
var ArrayBuffer = require( '@stdlib/array-buffer' );
var isObjectLike = require( '@stdlib/assert-is-object-like' );

var bool = isObjectLike( {} );
// returns true

bool = isObjectLike( [] );
// returns true

bool = isObjectLike( /./ );
// returns true

bool = isObjectLike( new Date() );
// returns true

bool = isObjectLike( Math );
// returns true

bool = isObjectLike( JSON );
// returns true

bool = isObjectLike( new Int8Array() );
// returns true

bool = isObjectLike( new ArrayBuffer() );
// returns true

bool = isObjectLike( 'a' );
// returns false

bool = isObjectLike( 5 );
// returns false

bool = isObjectLike( null );
// returns false

bool = isObjectLike( void 0 );
// returns false

bool = isObjectLike( function foo() {} );
// returns false
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/assert/is-object`][@stdlib/assert/is-object]</span><span class="delimiter">: </span><span class="description">test if a value is an object.</span>
-   <span class="package-name">[`@stdlib/assert/is-plain-object`][@stdlib/assert/is-plain-object]</span><span class="delimiter">: </span><span class="description">test if a value is a plain object.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/assert-is-object-like.svg
[npm-url]: https://npmjs.org/package/@stdlib/assert-is-object-like

[test-image]: https://github.com/stdlib-js/assert-is-object-like/actions/workflows/test.yml/badge.svg?branch=v0.0.8
[test-url]: https://github.com/stdlib-js/assert-is-object-like/actions/workflows/test.yml?query=branch:v0.0.8

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/assert-is-object-like/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/assert-is-object-like?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/assert-is-object-like.svg
[dependencies-url]: https://david-dm.org/stdlib-js/assert-is-object-like/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/assert-is-object-like/tree/deno
[umd-url]: https://github.com/stdlib-js/assert-is-object-like/tree/umd
[esm-url]: https://github.com/stdlib-js/assert-is-object-like/tree/esm
[branches-url]: https://github.com/stdlib-js/assert-is-object-like/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/assert-is-object-like/main/LICENSE

[type-of]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/typeof

<!-- <related-links> -->

[@stdlib/assert/is-object]: https://www.npmjs.com/package/@stdlib/assert-is-object

[@stdlib/assert/is-plain-object]: https://www.npmjs.com/package/@stdlib/assert-is-plain-object

<!-- </related-links> -->

</section>

<!-- /.links -->
