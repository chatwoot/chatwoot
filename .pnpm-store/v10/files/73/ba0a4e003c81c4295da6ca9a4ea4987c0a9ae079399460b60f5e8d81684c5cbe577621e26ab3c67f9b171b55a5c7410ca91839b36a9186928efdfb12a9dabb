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

# rescape

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> Escape a [regular expression][mdn-regexp] string or pattern.

<!-- Section to include introductory text. Make sure to keep an empty line after the intro `section` element and another before the `/section` close. -->

<section class="intro">

</section>

<!-- /.intro -->

<!-- Package usage documentation. -->

<section class="installation">

## Installation

```bash
npm install @stdlib/utils-escape-regexp-string
```

</section>

<section class="usage">

## Usage

```javascript
var rescape = require( '@stdlib/utils-escape-regexp-string' );
```

#### rescape( str )

Escapes a [regular expression][mdn-regexp] `string` or pattern.

```javascript
var str = rescape( '/[A-Z]*/' );
// returns '/\\[A\\-Z\\]\\*/'

str = rescape( '[A-Z]*' );
// returns '\\[A\\-Z\\]\\*'
```

If provided a value which is not a primitive `string`, the function **throws** a `TypeError`.

```javascript
try {
    rescape( null );
    // throws an error...
} catch ( err ) {
    console.error( err );
}
```

</section>

<!-- /.usage -->

<!-- Package usage notes. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="notes">

-   The following characters have special meaning inside of regular expressions and need to be escaped in case the characters should be treated literally:

    | description   | value    |
    | ------------- | -------- |
    | Backslash     | `&#92;`  |
    | Braces        | `{ }`    |
    | Brackets      | `[ ]`    |
    | Caret         | `^`      |
    | Dollar Sign   | `$`      |
    | Forward Slash | `/`      |
    | Asterisk      | `*`      |
    | Parentheses   | `( )`    |
    | Period        | `.`      |
    | Plus Sign     | `+`      |
    | Vertical Bar  | `&#124;` |
    | Question Mark | `?`      |

</section>

<!-- /.notes -->

<!-- Package usage examples. -->

<section class="examples">

## Examples

<!-- eslint-disable no-useless-escape -->

<!-- eslint no-undef: "error" -->

```javascript
var rescape = require( '@stdlib/utils-escape-regexp-string' );

var out = rescape( '/beep/' );
// returns '/beep/'

out = rescape( 'beep' );
// returns 'beep'

out = rescape( '/[A-Z]*/' );
// returns '/\\[A\\-Z\\]\\*/'

out = rescape( '[A-Z]*' );
// returns '\\[A\\-Z\\]\\*'

out = rescape( '/\\\//ig' );
// returns '/\\\\\\\//ig'

out = rescape( '\\\/' );
// returns '\\\\\\\/'

out = rescape( '/[A-Z]{0,}/' );
// returns '/\\[A\\-Z\\]\\{0,\\}/'

out = rescape( '[A-Z]{0,}' );
// returns '\\[A\\-Z\\]\\{0,\\}'

out = rescape( '/^boop$/' );
// returns '/\\^boop\\$/'

out = rescape( '^boop$' );
// returns '\\^boop\\$'

out = rescape( '/(?:.*)/' );
// returns '/\\(\\?:\\.\\*\\)/'

out = rescape( '(?:.*)' );
// returns '\\(\\?:\\.\\*\\)'

out = rescape( '/(?:beep|boop)/' );
// returns '/\\(\\?:beep\\|boop\\)/'

out = rescape( '(?:beep|boop)' );
// returns '\\(\\?:beep\\|boop\\)'
```

</section>

<!-- /.examples -->

<!-- Section to include cited references. If references are included, add a horizontal rule *before* the section. Make sure to keep an empty line after the `section` element and another before the `/section` close. -->

<section class="references">

</section>

<!-- /.references -->

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

[npm-image]: http://img.shields.io/npm/v/@stdlib/utils-escape-regexp-string.svg
[npm-url]: https://npmjs.org/package/@stdlib/utils-escape-regexp-string

[test-image]: https://github.com/stdlib-js/utils-escape-regexp-string/actions/workflows/test.yml/badge.svg?branch=v0.0.9
[test-url]: https://github.com/stdlib-js/utils-escape-regexp-string/actions/workflows/test.yml?query=branch:v0.0.9

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/utils-escape-regexp-string/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/utils-escape-regexp-string?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/utils-escape-regexp-string.svg
[dependencies-url]: https://david-dm.org/stdlib-js/utils-escape-regexp-string/main

-->

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/utils-escape-regexp-string/tree/deno
[umd-url]: https://github.com/stdlib-js/utils-escape-regexp-string/tree/umd
[esm-url]: https://github.com/stdlib-js/utils-escape-regexp-string/tree/esm
[branches-url]: https://github.com/stdlib-js/utils-escape-regexp-string/blob/main/branches.md

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/utils-escape-regexp-string/main/LICENSE

[mdn-regexp]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions

</section>

<!-- /.links -->
