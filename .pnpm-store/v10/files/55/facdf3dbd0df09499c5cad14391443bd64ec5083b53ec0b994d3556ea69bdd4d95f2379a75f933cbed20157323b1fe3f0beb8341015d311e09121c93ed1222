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

# getPrototypeOf

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Return the prototype of a provided object.

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-get-prototype-of
```

</section>

<section class="usage">

## Usage

```javascript
var getPrototypeOf = require( '@stdlib/utils-get-prototype-of' );
```

#### getPrototypeOf( value )

Returns the `prototype` of an input `value`.

```javascript
var proto = getPrototypeOf( {} );
// returns {}
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   In contrast to the native [`Object.getPrototypeOf`][object-get-prototype-of], this function does **not** throw when provided `null` or `undefined`. Instead, similar to when provided any value with **no** inherited properties, the function returns `null`.

    ```javascript
    var proto = getPrototypeOf( Object.create( null ) );
    // returns null

    proto = getPrototypeOf( null );
    // returns null

    proto = getPrototypeOf( void 0 );
    // returns null
    ```

-   Value arguments other than `null` or `undefined` are coerced to `objects`.

    ```javascript
    var proto = getPrototypeOf( 'beep' );
    // returns String.prototype

    proto = getPrototypeOf( 5 );
    // returns Number.prototype
    ```

    This behavior matches ES6/ES2015 native [`Object.getPrototypeOf`][object-get-prototype-of] behavior. In ES5, the native [`Object.getPrototypeOf`][object-get-prototype-of] throws when provided non-object values.

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint-disable no-restricted-syntax, no-empty-function -->

<!-- eslint no-undef: "error" -->

```javascript
var getPrototypeOf = require( '@stdlib/utils-get-prototype-of' );

var proto = getPrototypeOf( 'beep' );
// returns String.prototype

proto = getPrototypeOf( 5 );
// returns Number.prototype

proto = getPrototypeOf( true );
// returns Boolean.prototype

proto = getPrototypeOf( null );
// returns null

proto = getPrototypeOf( void 0 );
// returns null

proto = getPrototypeOf( [] );
// returns Array.prototype

proto = getPrototypeOf( {} );
// returns {}

proto = getPrototypeOf( function foo() {} );
// returns Function.prototype
```

</section>

<!-- /.examples -->

<!-- Section for related `stdlib` packages. Do not manually edit this section, as it is automatically populated. -->

<section class="related">

* * *

## See Also

-   <span class="package-name">[`@stdlib/assert/is-prototype-of`][@stdlib/assert/is-prototype-of]</span><span class="delimiter">: </span><span class="description">test if an object's prototype chain contains a provided prototype.</span>

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-get-prototype-of.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-get-prototype-of

[test-image]: https://github.com/stdlib-js/utils-get-prototype-of/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/utils-get-prototype-of/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-get-prototype-of/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-get-prototype-of?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-get-prototype-of.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-get-prototype-of/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-get-prototype-of/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-get-prototype-of/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-get-prototype-of/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/utils-get-prototype-of/main/LICENSE

[object-get-prototype-of]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/getPrototypeOf

<!-- <related-links> -->

[@stdlib/assert/is-prototype-of]: https://www.npmjs.com/package/@stdlib/assert-is-prototype-of

<!-- </related-links> -->

</section>

<!-- /.links -->
