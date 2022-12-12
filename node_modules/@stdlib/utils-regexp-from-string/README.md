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

# RegExp

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Create a [regular expression][regexp] from a [regular expression][regexp] string.

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-regexp-from-string
```

</section>

<section class="usage">

## Usage

```javascript
var reFromString = require( '@stdlib/utils-regexp-from-string' );
```

#### reFromString( str )

Parses a [regular expression][regexp] `string` and returns a new [regular expression][regexp].

```javascript
var re = reFromString( '/beep/' );
// returns /beep/
```

</section>

<!-- /.usage -->

<section class="notes">

## Notes

-   Provided `strings` **must** be properly **escaped**.

    <!-- eslint-disable no-useless-escape -->

    ```javascript
    // Unescaped:
    var re = reFromString( '/\w+/' );
    // returns /w+/

    // Escaped:
    re = reFromString( '/\\w+/' );
    // returns /\w+/
    ```

</section>

<!-- /.notes -->

<section class="examples">

## Examples

<!-- eslint-disable no-useless-escape -->

<!-- eslint no-undef: "error" -->

```javascript
var reFromString = require( '@stdlib/utils-regexp-from-string' );

var re = reFromString( '/beep/' );
// returns /beep/

re = reFromString( '/[A-Z]*/' );
// returns /[A-Z]*/

re = reFromString( '/\\\\\\\//ig' );
// returns /\\\//gi

re = reFromString( '/[A-Z]{0,}/' );
// returns /[A-Z]{0,}/

re = reFromString( '/^boop$/' );
// returns /^boop$/

re = reFromString( '/(?:.*)/' );
// returns /(?:.*)/

re = reFromString( '/(?:beep|boop)/' );
// returns /(?:beep|boop)/

re = reFromString( '/\\w+/' );
// returns /\w+/
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

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-regexp-from-string.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-regexp-from-string

[test-image]: https://github.com/stdlib-js/utils-regexp-from-string/actions/workflows/test.yml/badge.svg?branch=v0.0.9
[test-url]: https://github.com/stdlib-js/utils-regexp-from-string/actions/workflows/test.yml?query=branch:v0.0.9

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-regexp-from-string/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-regexp-from-string?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-regexp-from-string.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-regexp-from-string/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-regexp-from-string/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-regexp-from-string/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-regexp-from-string/tree/esm
[branches-url]: https://github.com/stdlib-js/utils-regexp-from-string/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/utils-regexp-from-string/main/LICENSE

[regexp]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions

</section>

<!-- /.links -->
