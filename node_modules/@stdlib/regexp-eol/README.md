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

# EOL

[![NPM version][npm-image]][npm-url] [![Build Status][test-image]][test-url] [![Coverage Status][coverage-image]][coverage-url] <!-- [![dependencies][dependencies-image]][dependencies-url] -->

> [Regular expression][mdn-regexp] to match a [newline][newline] character sequence.

<section class="installation">

## Installation

```bash
npm install @stdlib/regexp-eol
```

</section>

<section class="usage">

## Usage

```javascript
var reEOL = require( '@stdlib/regexp-eol' );
```

#### reEOL( \[options] )

Returns a [Regular expression][mdn-regexp] to match a [newline][newline] character sequence. 

```javascript
var RE_EOL = reEOL();

var bool = RE_EOL.test( '\n' );
// returns true

bool = RE_EOL.test( '\r\n' );
// returns true

bool = RE_EOL.test( '\\r\\n' );
// returns false
```

The function accepts an `options` object with optional properties:

-   **flags**: `string` specifying regular expression [flags][mdn-regexp-flags]. Default: `''`.
-   **capture**: `boolean` indicating whether to create a capture group for the match. Default: `false`.

By default, the function returns a regular expression which does not have any flags specified. To specify [flags][mdn-regexp-flags], set the `flags` option with a list of flags (which may be in any order).

```javascript
var replace = require( '@stdlib/string-replace' );

var RE_EOL = reEOL({
    'flags': 'g'
});

var str = '1\n2\n3';
var out = replace( str, RE_EOL, '' );
// returns '123'
```

By default, the function returns a regular expression which does not capture the part of a string matching the regular expression. To capture matches, set the `capture` option.

```javascript
var RE_EOL = reEOL({
    'capture': true
});

var str = 'beep\nboop';
var arr = str.split( RE_EOL );
// returns [ 'beep', '\n', 'boop' ]
```

#### reEOL.REGEXP

[Regular expression][mdn-regexp] to match a [newline][newline] character sequence. 

```javascript
var bool = reEOL.REGEXP.test( 'abc' );
// returns false
```

#### reEOL.REGEXP_CAPTURE

[Regular expression][mdn-regexp] to capture a [newline][newline] character sequence. 

```javascript
var parts = reEOL.REGEXP_CAPTURE.exec( '\n' );
// returns [ '\n', '\n' ]
```

</section>

<!-- /.usage -->

<section class="examples">

## Examples

<!-- eslint no-undef: "error" -->

```javascript
var reEOL = require( '@stdlib/regexp-eol' );

var RE_EOL = reEOL();
var bool;
var str;

bool = RE_EOL.test( '\r\n' );
// returns true

bool = RE_EOL.test( '\n' );
// returns true

bool = RE_EOL.test( '\r' );
// returns false

bool = RE_EOL.test( '\\r\\n' );
// returns false

bool = RE_EOL.test( 'beep' );
// returns false

str = 'This is\na newline\r\ndelimited string.';

var arr = str.split( RE_EOL );
// returns [ 'This is', 'a newline', 'delimited string.' ]
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

[npm-image]: http://img.shields.io/npm/v/@stdlib/regexp-eol.svg
[npm-url]: https://npmjs.org/package/@stdlib/regexp-eol

[test-image]: https://github.com/stdlib-js/regexp-eol/actions/workflows/test.yml/badge.svg
[test-url]: https://github.com/stdlib-js/regexp-eol/actions/workflows/test.yml

[coverage-image]: https://img.shields.io/codecov/c/github/stdlib-js/regexp-eol/main.svg
[coverage-url]: https://codecov.io/github/stdlib-js/regexp-eol?branch=main

<!--

[dependencies-image]: https://img.shields.io/david/stdlib-js/regexp-eol.svg
[dependencies-url]: https://david-dm.org/stdlib-js/regexp-eol/main

-->

[umd]: https://github.com/umdjs/umd
[es-module]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules

[deno-url]: https://github.com/stdlib-js/regexp-eol/tree/deno
[umd-url]: https://github.com/stdlib-js/regexp-eol/tree/umd
[esm-url]: https://github.com/stdlib-js/regexp-eol/tree/esm

[chat-image]: https://img.shields.io/gitter/room/stdlib-js/stdlib.svg
[chat-url]: https://gitter.im/stdlib-js/stdlib/

[stdlib]: https://github.com/stdlib-js/stdlib

[stdlib-authors]: https://github.com/stdlib-js/stdlib/graphs/contributors

[stdlib-license]: https://raw.githubusercontent.com/stdlib-js/regexp-eol/main/LICENSE

[mdn-regexp]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions

[mdn-regexp-flags]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions#advanced_searching_with_flags_2

[newline]: https://en.wikipedia.org/wiki/Newline

</section>

<!-- /.links -->
